
-- Set up the mindtest namespace
mindtest = {}

local modpath = minetest.get_modpath("mindtest")

-- Utility functions
dofile(modpath .. "/helpers.lua")


-- Energy system
dofile(modpath .. "/energy/init.lua")
