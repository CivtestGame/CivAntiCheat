
civanticheat = {}

local path = minetest.get_modpath(minetest.get_current_modname())

dofile(path .. "/api.lua")
dofile(path .. "/commands.lua")

dofile(path .. "/fly.lua")
dofile(path .. "/noclip.lua")

minetest.log("[CivAntiCheat] Initialised.")
