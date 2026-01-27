--[[
    OX INVENTORY ITEM DEFINITIONS
    
    Add these items to your ox_inventory/data/items.lua file
    
    These are the tool items and lootable items for the copper theft script.
]]

-- ========== TOOL ITEMS ==========

-- Wire Cutters - Required for electrical theft
['wire_cutters'] = {
    label = 'Wire Cutters',
    weight = 350,
    stack = false,
    close = true,
    description = 'Heavy duty wire cutters for cutting copper wiring',
    durability = 100,
},

-- Pipe Cutters - Required for plumbing theft
['pipe_cutters'] = {
    label = 'Pipe Cutters',
    weight = 500,
    stack = false,
    close = true,
    description = 'Professional pipe cutters for cutting copper pipes',
    durability = 100,
},

-- Crowbar - Required for HVAC, infrastructure, building theft
['crowbar'] = {
    label = 'Crowbar',
    weight = 800,
    stack = false,
    close = true,
    description = 'A sturdy crowbar for prying open panels and units',
    durability = 100,
},

-- ========== LOOTABLE ITEMS ==========

-- Copper Wire - Most common loot
['copper_wire'] = {
    label = 'Copper Wire',
    weight = 150,
    stack = true,
    close = true,
    description = 'Stripped copper wiring, valuable at scrap yards',
},

-- Copper Pipe - From plumbing locations
['copper_pipe'] = {
    label = 'Copper Pipe',
    weight = 400,
    stack = true,
    close = true,
    description = 'Cut copper plumbing pipes, good scrap value',
},

-- HVAC Coil - High value from HVAC units
['hvac_coil'] = {
    label = 'HVAC Coil',
    weight = 1200,
    stack = true,
    close = true,
    description = 'Copper heating coil from an HVAC unit',
},

-- AC Coil - High value from AC units
['ac_coil'] = {
    label = 'AC Coil',
    weight = 1500,
    stack = true,
    close = true,
    description = 'Copper cooling coil from an air conditioning unit',
},
