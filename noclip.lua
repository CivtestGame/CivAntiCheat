
local ac = civanticheat

local player_pos_history = {}

ac.register_module({
      name = "noclip",
      severity = 1.2,
      threshold = 3,
      decay = 0.95,

      check_frequency = 0.5,
      check = function(self, player)
         -- local has_noclip = minetest.check_player_privs(
         --    player, {noclip = true}
         -- )
         -- if has_noclip then
         --    -- Disable noclip check for flying + noclipping players
         --    return false
         -- end

         local pname = player:get_player_name()
         local ppos = player:get_pos()

         local upper_node = minetest.get_node(
            vector.new(ppos.x, ppos.y + 1, ppos.z)
         )
         local lower_node = minetest.get_node(
            vector.new(ppos.x, ppos.y + 0.1, ppos.z)
         )

         local upper_node_def = minetest.registered_nodes[upper_node.name]
         local lower_node_def = minetest.registered_nodes[lower_node.name]

         if not upper_node_def or not lower_node_def then
            ac.log("NoClip can't check defs of an undefined node...")
            return false
         end

         -- minetest.log("ppos.y: " .. tostring(ppos.y) ..
         --    ", upper: " .. upper_node.name .. ", lower: " .. lower_node.name
         -- )

         if not upper_node_def.walkable and not lower_node_def.walkable then
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
