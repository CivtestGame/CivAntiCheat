
local ac = civanticheat

ac.register_module({
      name = "Fly",
      severity = 1,

      frequency = 1,
      check = function(self, player)
         -- self:log("It's a party with " .. player:get_player_name())
      end,
})
