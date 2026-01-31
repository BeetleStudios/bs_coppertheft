local QBX = exports.qbx_core
local ox_inventory = exports.ox_inventory
local ox_target = exports.ox_target

-- Local variables
local isThieving = false
local propCooldowns = {} -- Track cooldowns by prop entity
local lastTheftTime = 0
local isHazardActive = false
local locationConfigs = {} -- Store location configs by model hash
local brokenProps = {} -- Track props with smoke effects (broken props)
local hazardRecoveryTime = 0 -- Timestamp when hazard recovery will complete
local lootCount = 0 -- Track number of successful loots before cooldown
local lootCountResetTime = 0 -- When to reset the loot counter
local scrapyardPeds = {} -- Track scrapyard PED entities

-- Debug function
local function DebugPrint(...)
    if Config.Debug then
        print('[bs__coppertheft:client]', ...)
    end
end

-- Notification wrapper
local function Notify(message, type)
    if Config.Notifications.type == 'ox_lib' then
        lib.notify({
            title = 'Copper Theft',
            description = message,
            type = type or 'inform',
            duration = 5000,
        })
    elseif Config.Notifications.type == 'qb' then
        TriggerEvent('QBCore:Notify', message, type or 'primary')
    else
        -- Custom notification - modify as needed
        lib.notify({
            title = 'Copper Theft',
            description = message,
            type = type or 'inform',
        })
    end
end

-- Play screen effect
local function PlayScreenEffect(effectName, duration)
    StartScreenEffect(effectName, 0, true)
    SetTimeout(duration, function()
        StopScreenEffect(effectName)
    end)
end

-- Load animation dictionary
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

-- Apply electrocution effect (Taser-like)
local function ApplyElectrocutionEffect(damage, duration, recoveryTime)
    local ped = cache.ped
    local effectSettings = Config.HazardEffects.electrocution
    
    -- Use recovery time from config, or fall back to duration if not specified
    recoveryTime = recoveryTime or duration
    
    isHazardActive = true
    hazardRecoveryTime = GetGameTimer() + recoveryTime -- Calculate when recovery will complete
    DebugPrint('isHazardActive set to true, recovery time:', recoveryTime, 'ms. Will recover at:', hazardRecoveryTime)
    
    -- Play taser stun animation (not handcuff animation)
    -- For electrocution, we'll just use ragdoll - no pre-animation needed
    -- The ragdoll effect itself shows the stun
    if effectSettings.taserAnim then
        -- Just clear any current tasks, ragdoll will handle the visual effect
        ClearPedTasksImmediately(ped)
        DebugPrint('Cleared tasks for electrocution - ragdoll will show the effect')
    end
    
    -- Screen effects removed - only particle effects on player
    
    -- Electrocution sound effects using InteractSound
    -- Using PlayOnSource - plays directly on the source player (best for personal effects)
    if effectSettings.sound then
        DebugPrint('Sound enabled in config, attempting to play electrocute sound')
        
        -- Check if InteractSound resource exists
        local interactSoundResource = GetResourceState('interact-sound')
        DebugPrint('InteractSound resource state:', interactSoundResource)
        
        if interactSoundResource == 'started' or interactSoundResource == 'starting' then
            DebugPrint('Triggering InteractSound_SV:PlayOnSource event:')
            DebugPrint('  - Event: InteractSound_SV:PlayOnSource')
            DebugPrint('  - Sound: electrocute')
            DebugPrint('  - Volume: 0.3')
            
            -- Play electrocute sound using InteractSound (PlayOnSource is best for personal effects)
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'electrocute', 0.3)
            
            DebugPrint('InteractSound_SV:PlayOnSource event triggered successfully')
        else
            DebugPrint('WARNING: InteractSound resource is not running! State:', interactSoundResource)
            DebugPrint('Using native GTA V sound as fallback')
            
            -- Fallback to native GTA V sound (electric spark sound)
            PlaySoundFrontend(-1, 'Spark', 'dlc_xm_fy_scripted_sounds', true)
            Wait(100)
            PlaySoundFrontend(-1, 'Taser_Shot', 'TAXI_SOUNDS', true)
            DebugPrint('Played native GTA V electric sound as fallback')
            
            DebugPrint('')
            DebugPrint('=== TO FIX: Install InteractSound resource ===')
            DebugPrint('1. Download interact-sound from: https://github.com/plunkettscott/interact-sound')
            DebugPrint('2. Place it in your resources folder')
            DebugPrint('3. Add "ensure interact-sound" to your server.cfg')
            DebugPrint('4. Place electrocute.ogg in interact-sound/client/html/sounds/')
            DebugPrint('5. Add the file to interact-sound/fxmanifest.lua files section')
            DebugPrint('6. Restart the server')
            DebugPrint('')
        end
    else
        DebugPrint('WARNING: Sound is disabled in config (effectSettings.sound = false)')
    end
    
    -- Ragdoll effect (taser stun)
    if effectSettings.ragdoll then
        CreateThread(function()
            -- Wait a moment to let animation play first
            Wait(500) -- Give animation time to be visible
            
            -- Apply ragdoll
            SetPedToRagdoll(ped, effectSettings.ragdollTime, effectSettings.ragdollTime, 0, false, false, false)
            DebugPrint('Applied ragdoll effect for', effectSettings.ragdollTime, 'ms')
            
            -- Wait for ragdoll to complete
            Wait(effectSettings.ragdollTime)
            
            -- After ragdoll, just clear tasks - no handcuff animation
            -- The ragdoll effect is enough, player will naturally get up
            if isHazardActive then
                -- Just clear any stuck tasks, let player recover naturally
                ClearPedTasksImmediately(ped)
                DebugPrint('Ragdoll complete, cleared tasks (no handcuff animation)')
            end
        end)
        
        -- Camera shake removed - no screen effects
        
        -- Apply electric particle effect (taser-like)
        CreateThread(function()
            local particleDict = 'core'
            local particleName = 'ent_dst_elec_fire_sp'
            
            RequestNamedPtfxAsset(particleDict)
            while not HasNamedPtfxAssetLoaded(particleDict) do
                Wait(10)
            end
            
            UseParticleFxAsset(particleDict)
            local particle = StartNetworkedParticleFxLoopedOnEntity(
                particleName,
                ped,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.6,
                false, false, false
            )
            
            Wait(duration)
            StopParticleFxLooped(particle, false)
            RemoveNamedPtfxAsset(particleDict)
        end)
        
        -- Screen flash removed - only particle effects
    end
    
    -- Apply damage
    local currentHealth = GetEntityHealth(ped)
    SetEntityHealth(ped, math.max(currentHealth - damage, 100)) -- Don't let it kill them (100 is min health)
    
    -- Recovery time is handled by the recovery check thread (timestamp-based)
    -- No SetTimeout needed - we check timestamps in a loop
    
    Notify('You got electrocuted! Be more careful!', 'error')
end

-- Apply burn effect
local function ApplyBurnEffect(damage, duration, recoveryTime)
    local ped = cache.ped
    local effectSettings = Config.HazardEffects.burn
    
    -- Use recovery time from config, or fall back to duration if not specified
    recoveryTime = recoveryTime or duration
    
    isHazardActive = true
    hazardRecoveryTime = GetGameTimer() + recoveryTime -- Calculate when recovery will complete
    DebugPrint('isHazardActive set to true (burn), recovery time:', recoveryTime, 'ms. Will recover at:', hazardRecoveryTime)
    
    -- Screen effect
    if effectSettings.screenEffect then
        PlayScreenEffect(effectSettings.screenEffect, duration)
    end
    
    -- Sound effect
    if effectSettings.sound then
        PlaySoundFrontend(-1, 'YOURSHIP_YOURSHIP_GUN_YOURSHIP_YOURSHIP_YOURSHIP', 'dlc_xm_fy_scripted_sounds', false)
    end
    
    -- Fire particle on player
    if effectSettings.fireParticle then
        CreateThread(function()
            local particleDict = 'core'
            local particleName = 'ent_ray_heli_crash_fire'
            
            RequestNamedPtfxAsset(particleDict)
            while not HasNamedPtfxAssetLoaded(particleDict) do
                Wait(10)
            end
            
            UseParticleFxAsset(particleDict)
            local particle = StartNetworkedParticleFxLoopedOnEntity(
                particleName,
                ped,
                0.0, 0.0, -0.5,
                0.0, 0.0, 0.0,
                0.3,
                false, false, false
            )
            
            -- Make player react to fire
            local fireCoords = GetEntityCoords(ped)
            StartScriptFire(fireCoords.x, fireCoords.y, fireCoords.z - 1.0, 1, false)
            
            Wait(effectSettings.fireDuration or duration)
            
            StopParticleFxLooped(particle, false)
            RemoveNamedPtfxAsset(particleDict)
            
            -- Remove any script fires near player
            local fires = GetNumberOfFiresInRange(fireCoords.x, fireCoords.y, fireCoords.z, 2.0)
            if fires > 0 then
                StopFireInRange(fireCoords.x, fireCoords.y, fireCoords.z, 3.0)
            end
        end)
    end
    
    -- Apply damage over time (burn damage)
    CreateThread(function()
        local damagePerTick = math.floor(damage / 4)
        for i = 1, 4 do
            if not isHazardActive then break end
            local currentHealth = GetEntityHealth(ped)
            SetEntityHealth(ped, math.max(currentHealth - damagePerTick, 100))
            Wait(duration / 4)
        end
    end)
    
    -- Clear ped tasks and make them react
    ClearPedTasks(ped)
    
    -- Recovery time is handled by the recovery check thread (timestamp-based)
    -- No SetTimeout needed - we check timestamps in a loop
    
    Notify('You got burned! Watch out for hot components!', 'error')
end

-- Process hazard on failed skill check
local function ProcessHazard(theftType)
    if not Config.Hazards.enabled then return false end
    
    local hazardConfig = Config.Hazards[theftType]
    if not hazardConfig or hazardConfig.type == 'none' then return false end
    
    -- Check if hazard triggers
    if math.random(100) > hazardConfig.chance then
        DebugPrint('Hazard check failed - no hazard triggered')
        return false
    end
    
    -- Calculate damage
    local damage = math.random(hazardConfig.damage.min, hazardConfig.damage.max)
    local duration = hazardConfig.duration
    
    -- Get recovery time from global config
    local recoveryTime = Config.Hazards.recoveryTime
    if not recoveryTime or recoveryTime <= 0 then
        recoveryTime = duration or 5000 -- Fall back to duration, then default 5 seconds
        DebugPrint('Warning: Invalid recoveryTime in config, using fallback:', recoveryTime)
    end
    
    DebugPrint('Recovery time from config:', Config.Hazards.recoveryTime, 'Using:', recoveryTime)
    
    -- Determine hazard type
    local hazardType = hazardConfig.type
    if hazardType == 'both' then
        -- Randomly choose between electrocution and burn
        hazardType = math.random(2) == 1 and 'electrocution' or 'burn'
    end
    
    DebugPrint('Applying hazard:', hazardType, 'Damage:', damage, 'Duration:', duration, 'RecoveryTime:', recoveryTime)
    
    -- Apply the appropriate effect
    if hazardType == 'electrocution' then
        ApplyElectrocutionEffect(damage, duration, recoveryTime)
    elseif hazardType == 'burn' then
        ApplyBurnEffect(damage, duration, recoveryTime)
    end
    
    return true
end

-- Check if player has required tools
local function HasRequiredTools(theftType)
    local requiredTools = Config.RequiredTools[theftType]
    if not requiredTools then return true end

    for _, tool in ipairs(requiredTools) do
        local count = ox_inventory:Search('count', tool)
        if not count or count < 1 then
            return false, tool
        end
    end
    return true
end

-- Get tool names for display
local function GetToolNames(theftType)
    local requiredTools = Config.RequiredTools[theftType]
    if not requiredTools then return 'None' end
    
    local names = {}
    for _, tool in ipairs(requiredTools) do
        local itemData = ox_inventory:Items(tool)
        local name = itemData and itemData.label or tool
        table.insert(names, name)
    end
    return table.concat(names, ', ')
end

-- Check cooldowns (prop-based)
local function IsOnCooldown(propEntity)
    -- Check if cooldowns are enabled
    if not Config.Cooldowns.enabled then
        return false
    end
    
    local currentTime = GetGameTimer()
    
    -- Check if we've reached the loot limit before cooldown
    local lootsBeforeCooldown = Config.Cooldowns.lootsBeforeCooldown or 0
    if lootsBeforeCooldown > 0 and lootCount < lootsBeforeCooldown then
        -- Reset loot counter if enough time has passed (reset after global cooldown period)
        if lootCountResetTime > 0 and currentTime >= lootCountResetTime then
            lootCount = 0
            lootCountResetTime = 0
            DebugPrint('Loot counter reset after cooldown period')
        end
        -- Still under the limit, no cooldown needed
        DebugPrint('Loot count:', lootCount, '/', lootsBeforeCooldown, '- No cooldown yet')
        return false
    end
    
    -- Check global cooldown (only if we've reached loot limit)
    if Config.Cooldowns.global and Config.Cooldowns.global > 0 then
        if lastTheftTime > 0 and currentTime - lastTheftTime < (Config.Cooldowns.global * 1000) then
            local remaining = math.ceil((Config.Cooldowns.global * 1000 - (currentTime - lastTheftTime)) / 1000)
            return true, 'Wait ' .. remaining .. ' seconds before attempting another theft'
        end
    end
    
    -- Check prop-specific cooldown
    if Config.Cooldowns.perLocation and Config.Cooldowns.perLocation > 0 then
        if propEntity and propCooldowns[propEntity] then
            if currentTime - propCooldowns[propEntity] < (Config.Cooldowns.perLocation * 1000) then
                local remaining = math.ceil((Config.Cooldowns.perLocation * 1000 - (currentTime - propCooldowns[propEntity])) / 1000)
                return true, 'This location needs time to recover (' .. remaining .. 's remaining)'
            end
        end
    end
    
    return false
end

-- Create smoke effect on broken prop
local function CreateSmokeEffect(propEntity)
    if not propEntity or not DoesEntityExist(propEntity) then 
        DebugPrint('CreateSmokeEffect: Invalid prop entity')
        return 
    end
    
    -- Check if prop already has smoke effect
    if brokenProps[propEntity] then 
        DebugPrint('CreateSmokeEffect: Prop already has smoke effect')
        return 
    end
    
    DebugPrint('CreateSmokeEffect: Starting smoke effect for prop', propEntity)
    
    CreateThread(function()
        -- Wait a moment to ensure entity is fully loaded
        Wait(200)
        
        if not DoesEntityExist(propEntity) then 
            DebugPrint('CreateSmokeEffect: Prop no longer exists')
            return 
        end
        
        -- Initialize as table to store particle data
        brokenProps[propEntity] = {
            active = true,
            particles = {},
        }
        
        -- Get prop position and bounding box
        local min, max = GetModelDimensions(GetEntityModel(propEntity))
        local height = max.z - min.z
        
        -- Create smoke effect at top of prop (or center if height is 0)
        local smokeOffset = vector3(0.0, 0.0, math.max(height * 0.8, 0.2))
        
        -- First, create spark animations (larger size)
        CreateThread(function()
            local sparkDict = 'core'
            local sparkName = 'ent_dst_elec_fire_sp'
            
            RequestNamedPtfxAsset(sparkDict)
            local timeout = 0
            while not HasNamedPtfxAssetLoaded(sparkDict) and timeout < 200 do
                Wait(10)
                timeout = timeout + 1
            end
            
            if HasNamedPtfxAssetLoaded(sparkDict) and DoesEntityExist(propEntity) and brokenProps[propEntity] and type(brokenProps[propEntity]) == 'table' then
                UseParticleFxAsset(sparkDict)
                
                -- Increased spark size (from 0.8 to 1.5)
                local particle = StartNetworkedParticleFxLoopedOnEntity(
                    sparkName,
                    propEntity,
                    smokeOffset.x, smokeOffset.y, smokeOffset.z,
                    0.0, 0.0, 0.0,
                    1.5, -- Increased scale for larger sparks
                    false, false, false
                )
                
                if particle then
                    if not brokenProps[propEntity].particles then
                        brokenProps[propEntity].particles = {}
                    end
                    table.insert(brokenProps[propEntity].particles, {
                        particle = particle,
                        dict = sparkDict,
                    })
                    DebugPrint('Created spark effect on prop', propEntity)
                end
            end
        end)
        
        -- After a delay, add black smoke effect
        CreateThread(function()
            Wait(1000) -- Wait 1 second after sparks to show black smoke
            
            if not DoesEntityExist(propEntity) or not brokenProps[propEntity] then return end
            
            -- Try multiple black smoke effects
            local smokeEffects = {
                { dict = 'scr_trevor_tree', name = 'ent_sht_steam', scale = 1.2 }, -- Dark steam/smoke
                { dict = 'scr_family5', name = 'scr_trev1_trailer_boosh', scale = 1.0 }, -- Dark smoke
                { dict = 'core', name = 'ent_dst_elec_fire_sp', scale = 0.3 }, -- Smaller sparks mixed with smoke
            }
            
            for i, effect in ipairs(smokeEffects) do
                CreateThread(function()
                    RequestNamedPtfxAsset(effect.dict)
                    local timeout = 0
                    while not HasNamedPtfxAssetLoaded(effect.dict) and timeout < 200 do
                        Wait(10)
                        timeout = timeout + 1
                    end
                    
                    if HasNamedPtfxAssetLoaded(effect.dict) and DoesEntityExist(propEntity) and brokenProps[propEntity] and type(brokenProps[propEntity]) == 'table' then
                        UseParticleFxAsset(effect.dict)
                        
                        local particle = StartNetworkedParticleFxLoopedOnEntity(
                            effect.name,
                            propEntity,
                            smokeOffset.x, smokeOffset.y, smokeOffset.z,
                            0.0, 0.0, 0.0,
                            effect.scale,
                            false, false, false
                        )
                        
                        if particle then
                            if not brokenProps[propEntity].particles then
                                brokenProps[propEntity].particles = {}
                            end
                            table.insert(brokenProps[propEntity].particles, {
                                particle = particle,
                                dict = effect.dict,
                            })
                            DebugPrint('Created black smoke effect', effect.name, 'on prop', propEntity)
                        end
                    end
                end)
                
                -- Stagger the effects slightly
                Wait(150)
            end
        end)
    end)
end

-- Perform the theft action (prop-based)
local function PerformTheft(propEntity, location)
    if isThieving then
        Notify('You are already busy!', 'error')
        return
    end
    
    -- Check hazard state and provide more info
    if isHazardActive then
        DebugPrint('Player tried to interact but isHazardActive is true. Current state - isThieving:', isThieving, 'isHazardActive:', isHazardActive)
        Notify('You need to recover first!', 'error')
        return
    end
    
    -- Ensure clean state before starting
    isHazardActive = false
    hazardRecoveryTime = 0
    DebugPrint('Starting theft attempt - isHazardActive reset to false')
    
    -- Check if prop is already broken
    if brokenProps[propEntity] and (type(brokenProps[propEntity]) == 'table' or brokenProps[propEntity] == true) then
        Notify('This item is already broken and has been stripped!', 'error')
        return
    end

    -- Check cooldown
    local onCooldown, cooldownMsg = IsOnCooldown(propEntity)
    if onCooldown then
        Notify(cooldownMsg, 'error')
        return
    end

    -- Check for required tools
    local hasTools, missingTool = HasRequiredTools(location.type)
    if not hasTools then
        local itemData = ox_inventory:Items(missingTool)
        local itemName = itemData and itemData.label or missingTool
        Notify('You need a ' .. itemName .. ' for this!', 'error')
        return
    end

    isThieving = true
    local success = false

    -- Get animation settings
    local animSettings = Config.Animations[location.type]
    local progressTime = Config.ProgressTime[location.type] or 10000

    -- Load animation
    LoadAnimDict(animSettings.dict)

    -- Get prop coordinates for police alert
    local propCoords = GetEntityCoords(propEntity)

    -- Skill check if enabled
    if Config.SkillCheck.enabled then
        local skillSuccess = lib.skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.inputs)
        if not skillSuccess then
            isThieving = false
            
            -- Process hazard (electrocution/burn) on failed skill check
            local hazardTriggered = ProcessHazard(location.type)
            
            if hazardTriggered then
                -- Hazard notification is handled in the hazard functions
                DebugPrint('Hazard triggered for player at prop', propEntity)
                -- isHazardActive is set inside ApplyElectrocutionEffect or ApplyBurnEffect
            else
                -- No hazard triggered, ensure isHazardActive is false
                isHazardActive = false
                hazardRecoveryTime = 0
                DebugPrint('No hazard triggered, isHazardActive set to false. Current state:', isHazardActive)
                Notify('You fumbled and made too much noise!', 'error')
            end
            
            -- Alert police on failed skill check with higher chance
            if Config.PoliceAlert.enabled and math.random(100) <= (Config.PoliceAlert.chance + 20) then
                TriggerServerEvent('bs__coppertheft:server:alertPolice', propCoords, location.type)
            end
            
            -- Clear any stuck animations
            ClearPedTasks(cache.ped)
            return
        end
    end

    -- Play wire_cut.ogg sound when starting the progress bar
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'wire_cut', 0.5)
    DebugPrint('Playing wire_cut.ogg sound during progress bar')
    
    -- Progress bar with animation (circular, bottom center)
    local progressSuccess = lib.progressCircle({
        duration = progressTime,
        label = location.description or ('Stripping ' .. location.type),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = animSettings.dict,
            clip = animSettings.anim,
            flag = 49,
        },
        position = 'bottom',
    })

    if progressSuccess then
        success = true
        
        -- Send prop coords + model + type for server validation (distance, config, cooldowns)
        local coords = GetEntityCoords(propEntity)
        TriggerServerEvent('bs__coppertheft:server:processTheft', { x = coords.x, y = coords.y, z = coords.z }, location.model, location.type)
        
        -- Increment loot counter
        local lootsBeforeCooldown = Config.Cooldowns.lootsBeforeCooldown or 0
        if lootsBeforeCooldown > 0 then
            lootCount = lootCount + 1
            DebugPrint('Successful loot! Count:', lootCount, '/', lootsBeforeCooldown)
            
            -- If we've reached the limit, set cooldown and reset counter after cooldown
            if lootCount >= lootsBeforeCooldown then
                local currentTime = GetGameTimer()
                lastTheftTime = currentTime
                lootCountResetTime = currentTime + (Config.Cooldowns.global * 1000)
                lootCount = 0 -- Reset counter, cooldown will apply next time
                DebugPrint('Reached loot limit, cooldown will apply. Counter reset in', Config.Cooldowns.global, 'seconds')
            end
        else
            -- No loot limit, apply cooldown immediately
            lastTheftTime = GetGameTimer()
        end
        
        -- Update prop-specific cooldown
        propCooldowns[propEntity] = GetGameTimer()
        
        -- Create smoke effect on broken prop
        CreateSmokeEffect(propEntity)
        
        -- Random chance to alert police
        if Config.PoliceAlert.enabled and math.random(100) <= Config.PoliceAlert.chance then
            TriggerServerEvent('bs__coppertheft:server:alertPolice', propCoords, location.type)
        end
        
        Notify('You successfully stripped the copper!', 'success')
    else
        Notify('Cancelled!', 'error')
    end

    -- Clear animation
    ClearPedTasks(cache.ped)
    isThieving = false
end

-- Create target zones for all prop models
local function CreateTargetZones()
    -- Group locations by model to avoid duplicate model registrations
    local modelGroups = {}
    
    for index, location in ipairs(Config.Locations) do
        if location.model then
            local modelHash = location.model
            
            -- Initialize model group if not exists
            if not modelGroups[modelHash] then
                modelGroups[modelHash] = {}
            end
            
            -- Store location config for this model
            table.insert(modelGroups[modelHash], location)
        end
    end
    
    -- Register each model with ox_target
    for modelHash, locations in pairs(modelGroups) do
        local targetOptions = {}
        
        -- Create options for each location type that uses this model
        for _, location in ipairs(locations) do
            table.insert(targetOptions, {
                name = 'copper_theft_' .. location.type .. '_' .. modelHash,
                icon = 'fas fa-bolt',
                label = location.label,
                onSelect = function(data)
                    -- data.entity is the prop entity
                    PerformTheft(data.entity, location)
                end,
                distance = Config.TargetDistance,
                canInteract = function(entity)
                    if isThieving then return false end
                    
                    -- In ox_target model targeting, canInteract receives the entity handle directly
                    -- entity can be a number (entity handle) or a table with entity property
                    local propEntity = nil
                    if type(entity) == 'number' then
                        propEntity = entity
                    elseif type(entity) == 'table' and entity.entity then
                        propEntity = entity.entity
                    end
                    
                    -- Check if prop is broken (has smoke effect)
                    if propEntity and brokenProps[propEntity] and (type(brokenProps[propEntity]) == 'table' or brokenProps[propEntity] == true) then
                        return false -- Can't interact with broken props
                    end
                    return true
                end,
            })
        end
        
        -- Register model with ox_target
        ox_target:addModel(modelHash, targetOptions)
        
        -- Store location configs for this model
        locationConfigs[modelHash] = locations
        
        DebugPrint('Registered prop model:', modelHash, 'with', #locations, 'location types')
    end
end

-- Create scrap yard sell points (PED-based)
local function CreateScrapYards()
    local pedModel = `a_m_m_hillbilly_01`
    
    -- Request the ped model
    RequestModel(pedModel)
    local timeout = 0
    while not HasModelLoaded(pedModel) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(pedModel) then
        DebugPrint('ERROR: Failed to load scrapyard ped model a_m_m_hillbilly_01')
        return
    end
    
    for index, scrapyard in ipairs(Config.ScrapYards.locations) do
        -- Spawn the PED
        local ped = CreatePed(4, pedModel, scrapyard.coords.x, scrapyard.coords.y, scrapyard.coords.z - 1.0, scrapyard.heading or 0.0, false, true)
        
        if ped and ped ~= 0 then
            -- Configure PED
            SetEntityAsMissionEntity(ped, true, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 17, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetPedCanRagdollFromPlayerImpact(ped, false)
            SetPedCanRagdoll(ped, false)
            
            -- Set PED to idle animation
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
            
            -- Store PED entity
            scrapyardPeds[index] = ped
            
            -- Create target options for the PED
            local targetOptions = {
                {
                    name = 'scrapyard_sell_' .. index,
                    icon = 'fas fa-dollar-sign',
                    label = 'Sell Copper Materials',
                    onSelect = function()
                        OpenSellMenu()
                    end,
                    distance = 2.5,
                },
            }
            
            -- Register PED with ox_target
            ox_target:addLocalEntity(ped, targetOptions)
            
            -- Create blip if enabled (check both global and individual settings)
            if Config.ScrapYards.blipsEnabled and scrapyard.blip and scrapyard.blip.enabled then
                local blip = AddBlipForCoord(scrapyard.coords.x, scrapyard.coords.y, scrapyard.coords.z)
                SetBlipSprite(blip, scrapyard.blip.sprite)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, scrapyard.blip.scale)
                SetBlipColour(blip, scrapyard.blip.color)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(scrapyard.blip.name)
                EndTextCommandSetBlipName(blip)
                DebugPrint('Created scrapyard blip for:', scrapyard.label)
            else
                DebugPrint('Scrapyard blip disabled for:', scrapyard.label)
            end
            
            DebugPrint('Created scrapyard PED at:', scrapyard.coords, 'PED entity:', ped)
        else
            DebugPrint('ERROR: Failed to create scrapyard PED at:', scrapyard.coords)
        end
    end
    
    -- Release the model
    SetModelAsNoLongerNeeded(pedModel)
end

-- Create location blips if enabled (disabled for prop-based approach)
local function CreateLocationBlips()
    if not Config.Blips.enabled then return end
    
    -- Note: With prop-based approach, blips are not practical since props
    -- can be anywhere on the map. If you want blips, you'll need to manually
    -- specify coordinates for known prop locations.
    DebugPrint('Blips disabled for prop-based approach. Props can be found throughout the map.')
end

-- Open sell menu
function OpenSellMenu()
    local sellItems = {}
    
    for item, prices in pairs(Config.SellPrices) do
        local count = ox_inventory:Search('count', item)
        if count and count > 0 then
            local itemData = ox_inventory:Items(item)
            local itemLabel = itemData and itemData.label or item
            table.insert(sellItems, {
                title = itemLabel .. ' (x' .. count .. ')',
                description = 'Sell for $' .. prices.min .. ' - $' .. prices.max .. ' each',
                icon = 'dollar-sign',
                metadata = {
                    { label = 'Quantity', value = count },
                    { label = 'Price Range', value = '$' .. prices.min .. ' - $' .. prices.max },
                },
                onSelect = function()
                    OpenSellAmountMenu(item, count, itemLabel)
                end,
            })
        end
    end

    if #sellItems == 0 then
        Notify('You have no copper materials to sell!', 'error')
        return
    end

    table.insert(sellItems, 1, {
        title = 'Sell All Copper',
        description = 'Sell all your copper materials at once',
        icon = 'boxes',
        onSelect = function()
            TriggerServerEvent('bs__coppertheft:server:sellAll')
        end,
    })

    lib.registerContext({
        id = 'copper_sell_menu',
        title = 'Scrap Yard',
        options = sellItems,
    })

    lib.showContext('copper_sell_menu')
end

-- Open amount selection menu
function OpenSellAmountMenu(item, maxAmount, itemLabel)
    local input = lib.inputDialog('Sell ' .. itemLabel, {
        { type = 'number', label = 'Amount to sell', default = maxAmount, min = 1, max = maxAmount },
    })

    if input and input[1] then
        local amount = math.floor(input[1])
        if amount > 0 and amount <= maxAmount then
            TriggerServerEvent('bs__coppertheft:server:sellCopper', item, amount)
        end
    end
end

-- Event handlers
RegisterNetEvent('bs__coppertheft:client:notify', function(message, type)
    Notify(message, type)
end)

-- Debug command to reset hazard state (admin only)
RegisterCommand('resetcopperhazard', function()
    if isHazardActive then
        isHazardActive = false
        hazardRecoveryTime = 0
        Notify('Hazard state reset!', 'success')
        DebugPrint('Hazard state manually reset by player')
    else
        Notify('No active hazard to reset.', 'inform')
    end
end, false)

-- Recovery check thread: Check if hazard recovery time has elapsed
CreateThread(function()
    while true do
        Wait(500) -- Check every 500ms for responsive recovery
        
        if isHazardActive then
            local currentTime = GetGameTimer()
            
            -- Check if recovery time has elapsed
            if hazardRecoveryTime > 0 and currentTime >= hazardRecoveryTime then
                DebugPrint('Recovery complete - resetting isHazardActive. Current time:', currentTime, 'Recovery time:', hazardRecoveryTime)
                isHazardActive = false
                hazardRecoveryTime = 0
                StopGameplayCamShaking(true)
                ClearPedTasks(cache.ped)
            elseif hazardRecoveryTime > 0 then
                local remaining = math.ceil((hazardRecoveryTime - currentTime) / 1000)
                -- Only log occasionally to avoid spam
                if remaining > 0 and remaining % 2 == 0 then
                    DebugPrint('Recovery in progress,', remaining, 'seconds remaining')
                end
            end
            
            -- Safety check: If recovery time is set but way in the past, something's wrong
            if hazardRecoveryTime > 0 and currentTime - hazardRecoveryTime > 5000 then
                DebugPrint('WARNING: Recovery time passed but isHazardActive still true, forcing reset!')
                isHazardActive = false
                hazardRecoveryTime = 0
                StopGameplayCamShaking(true)
                ClearPedTasks(cache.ped)
            end
        else
            -- Reset recovery time if not active
            if hazardRecoveryTime > 0 then
                hazardRecoveryTime = 0
            end
        end
    end
end)

-- Initialize
CreateThread(function()
    while not QBX:GetPlayerData() do
        Wait(100)
    end
    
    Wait(1000) -- Small delay to ensure everything is loaded
    
    CreateTargetZones()
    CreateScrapYards()
    CreateLocationBlips()
    
    DebugPrint('Copper Theft script initialized')
end)

-- Clean up smoke effects when entity is removed
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        for propEntity, data in pairs(brokenProps) do
            if not DoesEntityExist(propEntity) then
                -- Clean up particles if entity no longer exists
                if data.particles then
                    for _, particleData in ipairs(data.particles) do
                        if particleData.particle then
                            StopParticleFxLooped(particleData.particle, false)
                        end
                    end
                elseif data.particle then
                    StopParticleFxLooped(data.particle, false)
                end
                if data.altParticle then
                    StopParticleFxLooped(data.altParticle, false)
                end
                brokenProps[propEntity] = nil
                DebugPrint('Cleaned up smoke effect for removed prop')
            end
        end
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Stop all smoke effects
    for propEntity, data in pairs(brokenProps) do
        if data.particles then
            for _, particleData in ipairs(data.particles) do
                if particleData.particle then
                    StopParticleFxLooped(particleData.particle, false)
                end
            end
        elseif data.particle then
            StopParticleFxLooped(data.particle, false)
        end
        if data.altParticle then
            StopParticleFxLooped(data.altParticle, false)
        end
    end
    brokenProps = {}
    
    -- Remove all model targets
    for modelHash in pairs(locationConfigs) do
        ox_target:removeModel(modelHash)
    end
    
    -- Remove scrapyard PEDs
    for index, ped in pairs(scrapyardPeds) do
        if ped and DoesEntityExist(ped) then
            ox_target:removeLocalEntity(ped)
            DeleteEntity(ped)
        end
    end
    scrapyardPeds = {}
end)
