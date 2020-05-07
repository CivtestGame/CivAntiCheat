
local ac = civanticheat

ac.modules = {}

function ac.log(acmodule, msg, ...)
   minetest.log(
      "[CivAntiCheat]["..acmodule.name:upper().."] " .. msg:format(...)
   )
end

-- ac._lowest_timer = nil

function ac.register_module(def)
   def.name = def.name or error("Anticheat module registered without a name.")
   def.severity = def.severity or 1
   def.violations = {}
   def.enabled = def.enabled or true

   def.log = ac.log

   -- Execute the check every half-second
   def.check = def.check or nil
   def.frequency = def.frequency or 0.5
   -- Module-local timer is used by the globalstep
   def._timer = 0

   -- ac._lowest_timer = (ac._lowest_timer
   --                        and math.min(ac._lowest_timer, def._timer))
   --    or def._timer

   if def.frequency and not def.check then
      error("Anticheat module '" .. def.name
               .. "' registered with a frequency but no check.")
      return
   end

   ac.modules[def.name] = def
end

function ac.record_violation(acmodule_name, player_name)
   local acmodule = ac.modules[acmodule_name]

   if not acmodule then
      minetest.log(
         "warning", "[CivAntiCheat] Violation recorded for unknown module '"
            .. acmodule_name .. "'."
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
end


minetest.register_on_mods_loaded(function()

      minetest.register_globalstep(function(dtime)
            local modules_to_check = {}
            for _,acmodule in pairs(ac.modules) do
               if acmodule.enabled and acmodule.check then
                  acmodule._timer = acmodule._timer + dtime
                  if acmodule._timer >= acmodule.frequency then
                     modules_to_check[#modules_to_check + 1] = acmodule
                     acmodule._timer = 0
                  end
               end
            end

            if not next(modules_to_check) then
               return
            end

            for _,player in ipairs(minetest.get_connected_players()) do
               for _,acmodule in ipairs(modules_to_check) do
                  acmodule:check(player)
               end
            end
      end)

  for _,acmodule in pairs(ac.modules) do
     if acmodule.enabled then
        acmodule:log("Initialised.")
     end
  end

end)
