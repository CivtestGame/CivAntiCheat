
local ac = civanticheat

local player_pos_history = {}

ac.register_module({
      name = "fly",
      severity = 1.2,
      threshold = 3,
      decay = 0.95,

      check_frequency = 0.25,
      check = function(self, player)
         if minetest.check_player_privs(player, {fly = true}) then
            -- Disable flyhack check for those with the 'fly' privilege
            return false
         end

         local pname = player:get_player_name()
         local ppos = player:get_pos()

         local ground_node = minetest.get_node(
            vector.new(ppos.x, ppos.y - 1.5, ppos.z)
         )

         if ground_node.name ~= "air" then
            player_pos_history[pname] = {}
            return false
         end

         player_pos_history[pname] = player_pos_history[pname] or {}
         table.insert(player_pos_history[pname], ppos)

         local last_y

         for i,hpos in ipairs(player_pos_history[pname]) do
            if last_y and hpos.y >= last_y then
               player_pos_history[pname] = {}
               return true
            end
            last_y = hpos.y
         end

         return false
      end,
})
