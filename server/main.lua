local QBX = exports.qbx_core
local ox_inventory = exports.ox_inventory

-- Debug function
local function DebugPrint(...)
    if Config.Debug then
        print('[bs__coppertheft:server]', ...)
    end
end

-- Build allowed model+type set from config (server-side source of truth)
local AllowedTheftLocations = {}
local function BuildAllowedLocations()
    AllowedTheftLocations = {}
    for _, loc in ipairs(Config.Locations or {}) do
        if loc.model and loc.type then
            local key = tostring(loc.model) .. '_' .. tostring(loc.type)
            AllowedTheftLocations[key] = true
            if not AllowedTheftLocations[loc.model] then
                AllowedTheftLocations[loc.model] = {}
            end
            AllowedTheftLocations[loc.model][loc.type] = true
        end
    end
end
BuildAllowedLocations()

-- Server-side cooldowns (location key = rounded coords + model, so same physical spot syncs for all players)
local PlayerGlobalLastTheft = {}
local PlayerLootCount = {} -- loots since last global cooldown (global cooldown only after lootsBeforeCooldown)
local LocationLastTheft = {}
local function GetLocationKey(propCoords, modelHash)
    if type(propCoords) ~= 'table' or not propCoords.x or not propCoords.y or not propCoords.z then
        return nil
    end
    local x = math.floor(tonumber(propCoords.x) or 0)
    local y = math.floor(tonumber(propCoords.y) or 0)
    local z = math.floor(tonumber(propCoords.z) or 0)
    return string.format('%d_%d_%d_%s', x, y, z, tostring(modelHash))
end

local function IsLocationAllowed(modelHash, theftType)
    if type(modelHash) ~= 'number' or type(theftType) ~= 'string' then return false end
    local types = AllowedTheftLocations[modelHash]
    return types and types[theftType] == true
end

-- Calculate loot based on type
local function CalculateLoot(theftType)
    local lootTable = Config.Loot[theftType]
    if not lootTable then return {} end

    local rewards = {}
    
    for _, lootEntry in ipairs(lootTable) do
        if math.random(100) <= lootEntry.chance then
            local amount = math.random(lootEntry.min, lootEntry.max)
            if rewards[lootEntry.item] then
                rewards[lootEntry.item] = rewards[lootEntry.item] + amount
            else
                rewards[lootEntry.item] = amount
            end
        end
    end

    return rewards
end

-- Remove tool durability
local function RemoveToolDurability(source, theftType)
    local requiredTools = Config.RequiredTools[theftType]
    if not requiredTools then return end

    for _, toolName in ipairs(requiredTools) do
        local durabilityLoss = Config.ToolDurability[toolName]
        if durabilityLoss then
            -- Get the tool from player inventory
            local items = ox_inventory:Search(source, 'slots', toolName)
            if items and #items > 0 then
                local slot = items[1].slot
                local metadata = items[1].metadata or {}
                
                -- Calculate new durability
                local currentDurability = metadata.durability or 100
                local newDurability = currentDurability - durabilityLoss
                
                if newDurability <= 0 then
                    -- Tool broke
                    ox_inventory:RemoveItem(source, toolName, 1, nil, slot)
                    TriggerClientEvent('bs__coppertheft:client:notify', source, 'Your ' .. toolName .. ' broke!', 'error')
                else
                    -- Update durability
                    ox_inventory:SetMetadata(source, slot, { durability = newDurability })
                end
            end
        end
    end
end

-- Process theft event (prop-based) — server validates coords, model/type, distance, and cooldowns
RegisterNetEvent('bs__coppertheft:server:processTheft', function(propCoords, modelHash, theftType)
    local source = source
    local Player = QBX:GetPlayer(source)
    if not Player then return end

    -- 1) Validate payload types
    if type(propCoords) ~= 'table' or type(modelHash) ~= 'number' or type(theftType) ~= 'string' then
        DebugPrint('processTheft rejected: invalid payload from', source)
        return
    end
    local px = tonumber(propCoords.x)
    local py = tonumber(propCoords.y)
    local pz = tonumber(propCoords.z)
    if not px or not py or not pz then
        DebugPrint('processTheft rejected: invalid prop coords from', source)
        return
    end

    -- 2) Entity must be a valid theft target from config (no arbitrary type/model)
    if not IsLocationAllowed(modelHash, theftType) then
        DebugPrint('processTheft rejected: model/type not in config', modelHash, theftType, 'from', source)
        return
    end

    -- 3) Distance check: player must be near the claimed prop (no triggering from a field)
    local ped = GetPlayerPed(source)
    if not ped or not DoesEntityExist(ped) then return end
    local playerCoords = GetEntityCoords(ped)
    local dx = playerCoords.x - px
    local dy = playerCoords.y - py
    local dz = playerCoords.z - pz
    local distSq = dx * dx + dy * dy + dz * dz
    local maxDist = tonumber(Config.MaxTheftDistance) or 5.0
    if distSq > (maxDist * maxDist) then
        DebugPrint('processTheft rejected: player too far from prop', math.sqrt(distSq), 'from', source)
        return
    end

    -- 4) Server-side cooldowns (location key = rounded coords + model, same for all players)
    local now = os.time()
    local cooldownCfg = Config.Cooldowns or {}
    local locationKey = GetLocationKey(propCoords, modelHash)
    if not locationKey then return end

    if cooldownCfg.enabled then
        if cooldownCfg.global and cooldownCfg.global > 0 then
            local last = PlayerGlobalLastTheft[source]
            if last and (now - last) < cooldownCfg.global then
                TriggerClientEvent('bs__coppertheft:client:notify', source, 'You need to wait before stealing again.', 'error')
                return
            end
        end
        if cooldownCfg.perLocation and cooldownCfg.perLocation > 0 then
            local last = LocationLastTheft[locationKey]
            if last and (now - last) < cooldownCfg.perLocation then
                TriggerClientEvent('bs__coppertheft:client:notify', source, 'This spot has already been stripped recently.', 'error')
                return
            end
        end
    end

    -- Verify player has required tools
    local requiredTools = Config.RequiredTools[theftType]
    if requiredTools then
        for _, tool in ipairs(requiredTools) do
            local hasItem = ox_inventory:Search(source, 'count', tool)
            if not hasItem or hasItem < 1 then
                TriggerClientEvent('bs__coppertheft:client:notify', source, 'You don\'t have the required tools!', 'error')
                return
            end
        end
    end

    -- Calculate and give loot
    local loot = CalculateLoot(theftType)
    local receivedItems = {}

    for item, amount in pairs(loot) do
        local success = ox_inventory:AddItem(source, item, amount)
        if success then
            local itemData = ox_inventory:Items(item)
            local itemLabel = itemData and itemData.label or item
            table.insert(receivedItems, amount .. 'x ' .. itemLabel)
        else
            TriggerClientEvent('bs__coppertheft:client:notify', source, 'Your inventory is full!', 'error')
        end
    end

    -- Notify player of received items
    if #receivedItems > 0 then
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'Received: ' .. table.concat(receivedItems, ', '), 'success')
    else
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'You didn\'t find anything valuable this time.', 'inform')
    end

    -- Remove tool durability
    RemoveToolDurability(source, theftType)

    -- Update server cooldowns (global only after lootsBeforeCooldown, so client and server agree)
    if cooldownCfg.enabled then
        local lootsBefore = tonumber(cooldownCfg.lootsBeforeCooldown) or 0
        if cooldownCfg.global and cooldownCfg.global > 0 then
            PlayerLootCount[source] = (PlayerLootCount[source] or 0) + 1
            if lootsBefore == 0 or PlayerLootCount[source] >= lootsBefore then
                PlayerGlobalLastTheft[source] = now
                PlayerLootCount[source] = 0
            end
        end
        if cooldownCfg.perLocation and cooldownCfg.perLocation > 0 then
            LocationLastTheft[locationKey] = now
        end
    end

    DebugPrint('Player', GetPlayerName(source), 'completed theft at', locationKey, 'type:', theftType)
end)

-- Alert police event
RegisterNetEvent('bs__coppertheft:server:alertPolice', function(coords, theftType)
    local source = source
    
    if not Config.PoliceAlert.enabled then return end

    -- Check minimum cops requirement
    local cops = QBX:GetDutyCountType('leo')
    if cops < Config.PoliceAlert.requiredCops then
        DebugPrint('Not enough cops online for alert. Required:', Config.PoliceAlert.requiredCops, 'Online:', cops)
        return
    end

    -- Get player info for alert
    local Player = QBX:GetPlayer(source)
    if not Player then return end

    -- Alert message with street name
    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    local alertMessage = Config.PoliceAlert.alertMessage .. ' near ' .. streetName

    -- Trigger alert to police
    -- Using qbx_dispatch or ps-dispatch if available
    local dispatchData = {
        message = alertMessage,
        coords = coords,
        dispatchCode = '10-31',
        description = 'Copper Theft in Progress',
        radius = 0,
        sprite = 618,
        color = 1,
        scale = 1.0,
        length = 3,
    }

    -- Try different dispatch systems
    TriggerClientEvent('police:client:policeAlert', -1, coords, alertMessage)
    
    -- Also try ps-dispatch if it exists
    TriggerEvent('ps-dispatch:server:notify', {
        dispatchcodename = 'coppertheft',
        dispatchCode = '10-31',
        firstStreet = streetName,
        gender = false,
        model = false,
        plate = false,
        priority = 2,
        firstColor = false,
        automaticGunfire = false,
        origin = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        dispatchMessage = alertMessage,
        job = { 'leo' }
    })

    TriggerClientEvent('bs__coppertheft:client:notify', source, 'Someone may have spotted you!', 'error')
    
    DebugPrint('Police alerted about copper theft at', coords)
end)

-- Sell copper event
RegisterNetEvent('bs__coppertheft:server:sellCopper', function(item, amount)
    local source = source
    local Player = QBX:GetPlayer(source)
    
    if not Player then return end

    -- Verify player has the item
    local hasItem = ox_inventory:Search(source, 'count', item)
    if not hasItem or hasItem < amount then
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'You don\'t have enough items!', 'error')
        return
    end

    -- Get price range
    local prices = Config.SellPrices[item]
    if not prices then
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'This item cannot be sold here!', 'error')
        return
    end

    -- Calculate total price
    local pricePerItem = math.random(prices.min, prices.max)
    local totalPrice = pricePerItem * amount

    -- Remove items
    local success = ox_inventory:RemoveItem(source, item, amount)
    if not success then
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'Failed to remove items!', 'error')
        return
    end

    -- Give money
    if Config.UseDirtyMoney then
        -- Give dirty money as marked bills
        ox_inventory:AddItem(source, Config.DirtyMoneyItem, totalPrice)
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'Sold ' .. amount .. 'x items for $' .. totalPrice .. ' in marked bills', 'success')
    else
        -- Give clean cash
        Player.Functions.AddMoney('cash', totalPrice)
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'Sold ' .. amount .. 'x items for $' .. totalPrice, 'success')
    end

    DebugPrint('Player', GetPlayerName(source), 'sold', amount, item, 'for', totalPrice)
end)

-- Sell all copper event
RegisterNetEvent('bs__coppertheft:server:sellAll', function()
    local source = source
    local Player = QBX:GetPlayer(source)
    
    if not Player then return end

    local totalEarnings = 0
    local soldItems = {}

    for item, prices in pairs(Config.SellPrices) do
        local hasItem = ox_inventory:Search(source, 'count', item)
        if hasItem and hasItem > 0 then
            local pricePerItem = math.random(prices.min, prices.max)
            local itemTotal = pricePerItem * hasItem
            
            local success = ox_inventory:RemoveItem(source, item, hasItem)
            if success then
                totalEarnings = totalEarnings + itemTotal
                local itemData = ox_inventory:Items(item)
                local itemLabel = itemData and itemData.label or item
                table.insert(soldItems, hasItem .. 'x ' .. itemLabel)
            end
        end
    end

    if totalEarnings > 0 then
        if Config.UseDirtyMoney then
            ox_inventory:AddItem(source, Config.DirtyMoneyItem, totalEarnings)
            TriggerClientEvent('bs__coppertheft:client:notify', source, 'Sold ' .. table.concat(soldItems, ', ') .. ' for $' .. totalEarnings .. ' in marked bills', 'success')
        else
            Player.Functions.AddMoney('cash', totalEarnings)
            TriggerClientEvent('bs__coppertheft:client:notify', source, 'Sold ' .. table.concat(soldItems, ', ') .. ' for $' .. totalEarnings, 'success')
        end
    else
        TriggerClientEvent('bs__coppertheft:client:notify', source, 'You have nothing to sell!', 'error')
    end

    DebugPrint('Player', GetPlayerName(source), 'sold all copper for', totalEarnings)
end)

-- Commands for admin/testing
lib.addCommand('givecoppertools', {
    help = 'Give copper theft tools (Admin Only)',
    restricted = 'group.admin',
}, function(source)
    ox_inventory:AddItem(source, 'wire_cutters', 1)
    ox_inventory:AddItem(source, 'pipe_cutters', 1)
    ox_inventory:AddItem(source, 'crowbar', 1)
    TriggerClientEvent('bs__coppertheft:client:notify', source, 'Received copper theft tools!', 'success')
end)

lib.addCommand('givecopper', {
    help = 'Give copper items for testing (Admin Only)',
    restricted = 'group.admin',
}, function(source)
    ox_inventory:AddItem(source, 'copper_wire', 10)
    ox_inventory:AddItem(source, 'copper_pipe', 10)
    ox_inventory:AddItem(source, 'hvac_coil', 5)
    ox_inventory:AddItem(source, 'ac_coil', 5)
    TriggerClientEvent('bs__coppertheft:client:notify', source, 'Received copper items!', 'success')
end)

-- Resource started: rebuild allowed locations from config
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    BuildAllowedLocations()
    print('^2[bs__coppertheft]^7 Copper Theft script loaded successfully!')
end)
