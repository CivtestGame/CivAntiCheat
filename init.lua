
civanticheat = {}

local path = minetest.get_modpath(minetest.get_current_modname())

local ac = civanticheat

function ac._round(x)
   return x >= 0
      and math.floor(x + 0.5)
      or math.ceil(x - 0.5)
end

function ac._decimal(x)
   return x - math.floor(x)
end


dofile(path .. "/api.lua")
dofile(path .. "/commands.lua")

dofile(path .. "/fly.lua")
dofile(path .. "/noclip.lua")

minetest.log("[CivAntiCheat] Initialised.")
