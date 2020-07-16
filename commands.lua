
local ac = civanticheat

minetest.register_privilege("civanticheat", "Privilege for CivAntiCheat")

minetest.register_privilege("civanticheat_test",
                            "Privilege for CivAntiCheat testing purposes.")

minetest.register_chatcommand(
   "ac",
   {
      params = "<name>",
      privs = { civanticheat = true },
      description = "Shows CivAntiCheat info for a player.",
      func = function(sender, param)
         local player = minetest.get_player_by_name(sender)
         if not player then
            return
         end

         if not param or param == "" then
            return false, "Please specify a player."
         end

         local pname = param
         local pinfo = minetest.get_player_information(pname)

         local msg = [[
CivAntiCheat: %s
  RTT: %.2f-%.2f (avg: %.2f)
  Jitter: %.2f-%.2f (avg: %.2f)
]]
         msg = msg:format(
            pname,
            pinfo.min_rtt, pinfo.max_rtt, pinfo.avg_rtt,
            pinfo.min_jitter, pinfo.max_jitter, pinfo.avg_jitter
         )

         for _,acmodule in pairs(ac.modules) do
            local name = acmodule.name
            local vl = acmodule.violation_level[pname] or 1.0
            local max_vl = acmodule.max_violation_level[pname] or 1.0
            msg = msg
               .. (" - [%s] VL: %.2f (max: %.2f)\n")
               :format(acmodule.name:upper(), vl, max_vl)
         end

         minetest.chat_send_player(sender, msg)
      end
   }
)
