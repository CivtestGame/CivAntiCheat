
local ac = civanticheat

ac.modules = {}

function ac.log(acmodule, msg, ...)
   minetest.log(
      "[CivAntiCheat]["..acmodule.name:upper().."] " .. msg:format(...)
   )
end

function ac.broadcast(acmodule, msg, ...)
   for _,player in ipairs(minetest.get_connected_players()) do
      local is_moderator = minetest.check_player_privs(
         player, { civanticheat = true }
      )
      local is_tester = minetest.check_player_privs(
         player, { civanticheat_test = true }
      )

      if is_moderator or is_tester then
         local pname = player:get_player_name()
         local c = minetest.colorize
         local full_msg = c("#f00", "[AC][")
            .. acmodule.name:upper()
            .. c("#f00","] ")
            .. msg:format(...)

         minetest.chat_send_player(pname, full_msg)
      end
   end
end

function ac.try_broadcast_violation(acmodule, player_name, msg, ...)
   local bcf = acmodule.broadcast_filter
   bcf[player_name] = bcf[player_name] or acmodule.broadcast_filter_limit

   if bcf[player_name] < acmodule.broadcast_filter_limit then
      bcf[player_name] = bcf[player_name] + 1
      return
   end

   acmodule:broadcast(msg, ...)
   bcf[player_name] = 0
end

function ac.register_module(def)
   def.name = def.name or error("Anticheat module registered without a name.")

   def.severity = def.severity or 1.1
   def.threshold = def.threshold or 2
   def.decay = def.decay or 1.01

   def.violations = {}
   def.violation_level = {}
   def.max_violation_level = {}

   def.enabled = def.enabled or true

   def.log = ac.log
   def.broadcast = ac.broadcast

   -- Used for filtering out excessive broadcasting
   def.broadcast_filter = {}
   def.broadcast_filter_limit = def.broadcast_filter_limit or 10

   -- Execute the check every half-second
   def.check = def.check or nil
   def.check_frequency = def.check_frequency or 0.5
   -- Module-local timer is used by the globalstep
   def._timer = 0

   -- ac._lowest_timer = (ac._lowest_timer
   --                        and math.min(ac._lowest_timer, def._timer))
   --    or def._timer

   if def.check_frequency and not def.check then
      error("Anticheat module '" .. def.name
               .. "' registered with a check_frequency but no check.")
      return
   end

   ac.modules[def.name] = def
end

function ac.record_violation(acmodule, player_name)

   if not acmodule then
      minetest.log(
         "warning", "[CivAntiCheat] Violation recorded for unknown module '"
            .. ((acmodule and acmodule.name) or "UNKNOWN") .. "'."
      )
      return
   end

   if not acmodule.enabled then
      return
   end

   acmodule.violations[player_name]
      = acmodule.violations[player_name] or {}

   acmodule.violation_level[player_name]
      = acmodule.violation_level[player_name] or 1

   acmodule.max_violation_level[player_name]
      = acmodule.max_violation_level[player_name] or 1

   local vl_tab = acmodule.violation_level
   local max_vl_tab = acmodule.max_violation_level

   local threshold = acmodule.threshold
   local severity = acmodule.severity

   local vl = vl_tab[player_name]

   local new_vl = vl * severity

   if new_vl > threshold then
      local pinfo = minetest.get_player_information(player_name)
      acmodule:log(
         "%s VL=%.2f exceeded threshold of %.2f (RTT %.2f Jitter %.2f)",
         player_name, new_vl, threshold, pinfo.avg_rtt, pinfo.avg_jitter
      )

      ac.try_broadcast_violation(
         acmodule, player_name,
         "%s VL=%.2f exceeded threshold of %.2f (RTT %.2f Jitter %.2f)",
         player_name, new_vl, threshold, pinfo.avg_rtt, pinfo.avg_jitter
      )
   end

   vl_tab[player_name] = new_vl
   max_vl_tab[player_name] = math.max(max_vl_tab[player_name], new_vl)

end

function ac.apply_decay(acmodule, pname)
   local vl_tab = acmodule.violation_level
   vl_tab[pname] = vl_tab[pname] or 1
   vl_tab[pname] = math.max(
      vl_tab[pname] * acmodule.decay, 1.0
   )
end

minetest.register_on_mods_loaded(function()

      minetest.register_globalstep(function(dtime)
            local modules_to_check = {}
            for _,acmodule in pairs(ac.modules) do
               if acmodule.enabled and acmodule.check then
                  acmodule._timer = acmodule._timer + dtime
                  if acmodule._timer >= acmodule.check_frequency then
                     modules_to_check[#modules_to_check + 1] = acmodule
                     acmodule._timer = 0
                  end
               end
            end

            if not next(modules_to_check) then
               return
            end

            for _,player in ipairs(minetest.get_connected_players()) do
               local pname = player:get_player_name()
               local is_tester = minetest.check_player_privs(
                  player, { civanticheat_test = true }
               )
               for _,acmodule in ipairs(modules_to_check) do
                  local result = acmodule:check(player, is_tester)
                  if result then
                     ac.record_violation(acmodule, pname)
                  else
                     ac.apply_decay(acmodule, pname)
                  end
               end
            end
      end)

  for _,acmodule in pairs(ac.modules) do
     if acmodule.enabled then
        acmodule:log("Initialised.")
     end
  end

end)
