
local ac = civanticheat

local player_pos_history = {}

ac.register_module({
      name = "fly",
      severity = 1.2,
      threshold = 3,
      decay = 0.95,

      check_frequency = 0.25,
      check = function(self, player, is_tester)

         if not is_tester then
            if minetest.check_player_privs(player, {fly = true}) then
               -- Disable flyhack check for those with the 'fly' privilege
               return false
            end
         end

         local pname = player:get_player_name()
         local ppos = player:get_pos()

         local gpos = vector.new(ppos.x, ppos.y - 1, ppos.z)
         local ground_node = minetest.get_node(gpos)

         -- When the AC doesn't think we're standing on air, great, we're very
         -- obviously grounded on a solid. No cheats here.
         --
         -- However, players can "perch" on the edges of nodes (e.g. sneaking),
         -- and this, naively implemented, is interpreted as standing on air.
         --
         -- To account for this, we do a threshold-check of our X and Z, and
         -- figure out a candidate for the perch node. If no perch is found, the
         -- player is in violation.

         if ground_node.name == "air" then
            local z_dec = ac._decimal(ppos.z)
            local ngz = ppos.z
            if z_dec > 0.5 and z_dec < 0.8 then
               ngz = math.floor(ppos.z)
            elseif z_dec > 0.2 and z_dec <= 0.5 then
               ngz = math.ceil(ppos.z)
            end

            local x_dec = ac._decimal(ppos.x)
            local ngx = ppos.x
            if x_dec > 0.5 and x_dec < 0.8 then
               ngx = math.floor(ppos.x)
            elseif x_dec > 0.2 and x_dec <= 0.5 then
               ngx = math.ceil(ppos.x)
            end

            local ngpos = vector.new(ngx, ppos.y - 1, ngz)

            ground_node = minetest.get_node(ngpos)
         end

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
