Config = {}

-- General Settings
Config.Debug = true -- Enable debug prints

-- Skill Check Settings
Config.SkillCheck = {
    enabled = true,
    difficulty = { 'easy', 'easy', 'medium' }, -- Skill check difficulties
    inputs = { 'w', 'a', 's', 'd' }, -- Keys for skill check
}

-- Hazard Settings (when skill check fails)
Config.Hazards = {
    enabled = true,
    recoveryTime = 5000, -- Global recovery time in ms (how long player must wait after hazard before attempting theft again)
    -- Hazard types per theft location type
    -- type: 'electrocution', 'burn', 'both', 'none'
    -- chance: percentage chance hazard occurs on failed skill check
    -- damage: min and max damage dealt (player health is 0-200)
    -- duration: how long the effect lasts in ms (for animations/screen effects)
    electrical = {
        type = 'electrocution',
        chance = 65,
        damage = { min = 15, max = 35 },
        duration = 3000,
    },
    plumbing = {
        type = 'none', -- Plumbing is relatively safe
        chance = 0,
        damage = { min = 0, max = 0 },
        duration = 0,
    },
    hvac = {
        type = 'both', -- Can get shocked or burned by refrigerant
        chance = 55,
        damage = { min = 10, max = 30 },
        duration = 2500,
    },
    infrastructure = {
        type = 'electrocution',
        chance = 70,
        damage = { min = 20, max = 45 },
        duration = 3500,
    },
    building = {
        type = 'electrocution',
        chance = 40,
        damage = { min = 10, max = 25 },
        duration = 2000,
    },
    vehicle = {
        type = 'burn', -- Hot engine components, battery acid
        chance = 45,
        damage = { min = 8, max = 20 },
        duration = 2000,
    },
}

-- Hazard screen effects
Config.HazardEffects = {
    electrocution = {
        screenEffect = 'MP_corona_switch', -- Taser-like screen effect
        ragdoll = true, -- Player falls down
        ragdollTime = 3000, -- How long player is ragdolled (taser effect)
        sound = true,
        taserAnim = true, -- Use taser stun animation
    },
    burn = {
        screenEffect = 'DrugsDrivingIn', -- Hazy effect
        ragdoll = false,
        ragdollTime = 0,
        sound = true,
        fireParticle = true, -- Small fire particle on player
        fireDuration = 2000,
    },
}

-- Progress Bar Settings
Config.ProgressTime = {
    electrical = 8000,  -- Time to strip electrical (ms)
    plumbing = 10000,   -- Time to cut pipes (ms)
    hvac = 15000,       -- Time to strip HVAC unit (ms)
    infrastructure = 12000, -- Time to strip infrastructure (ms)
    building = 10000,   -- Time to strip building materials (ms)
    vehicle = 8000,     -- Time to strip vehicle parts (ms)
}

-- Animation Settings
Config.Animations = {
    electrical = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
    plumbing = { dict = 'mini@repair', anim = 'fixing_a_player' },
    hvac = { dict = 'mp_arresting', anim = 'a_uncuff' },
    infrastructure = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', anim = 'machinic_loop_mechandplayer' },
    building = { dict = 'mp_arresting', anim = 'a_uncuff' },
    vehicle = { dict = 'mini@repair', anim = 'fixing_a_player' },
}

-- Required Tools for each type of theft
Config.RequiredTools = {
    electrical = { 'wire_cutters' },
    plumbing = { 'pipe_cutters' },
    hvac = { 'wire_cutters', 'crowbar' },
    infrastructure = { 'wire_cutters', 'crowbar' },
    building = { 'crowbar' },
    vehicle = { 'crowbar', 'wire_cutters' },
}

-- Tool Durability (how much durability is removed per use, percentage)
Config.ToolDurability = {
    wire_cutters = 5,
    pipe_cutters = 8,
    crowbar = 3,
}

-- Loot Tables (item name, min amount, max amount, chance 1-100)
Config.Loot = {
    electrical = {
        { item = 'copper_wire', min = 1, max = 4, chance = 80 },
        { item = 'copper_wire', min = 2, max = 6, chance = 40 },
    },
    plumbing = {
        { item = 'copper_pipe', min = 1, max = 3, chance = 85 },
        { item = 'copper_pipe', min = 2, max = 4, chance = 30 },
    },
    hvac = {
        { item = 'hvac_coil', min = 1, max = 2, chance = 70 },
        { item = 'ac_coil', min = 1, max = 2, chance = 60 },
        { item = 'copper_wire', min = 2, max = 5, chance = 90 },
    },
    infrastructure = {
        { item = 'copper_wire', min = 3, max = 8, chance = 75 },
        { item = 'copper_pipe', min = 1, max = 2, chance = 40 },
    },
    building = {
        { item = 'copper_wire', min = 1, max = 3, chance = 70 },
        { item = 'copper_pipe', min = 1, max = 2, chance = 50 },
    },
    vehicle = {
        { item = 'copper_wire', min = 2, max = 4, chance = 85 },
        { item = 'ac_coil', min = 1, max = 1, chance = 30 },
    },
}

-- Police Alert Settings
Config.PoliceAlert = {
    enabled = true,
    chance = 35, -- Percentage chance to alert police
    requiredCops = 0, -- Minimum cops online for alerts
    alertMessage = 'Suspicious activity reported - Possible copper theft',
}

-- Cooldown Settings (in seconds)
-- These control how long players must wait between theft attempts
Config.Cooldowns = {
    enabled = true, -- Enable/disable cooldown system
    lootsBeforeCooldown = 3, -- Number of successful loots allowed before cooldown kicks in (0 = cooldown after every loot)
    global = 60, -- Global cooldown between any theft (prevents spam across all props)
    perLocation = 300, -- Cooldown per specific prop (prevents re-looting the same prop for 5 minutes)
    -- Note: If lootsBeforeCooldown > 0, player can loot that many times before cooldown applies
    -- After reaching the limit, cooldown will apply to the next theft attempt
}

-- Blip Settings (for showing theft locations on map - disable for realism)
Config.Blips = {
    enabled = true, -- Set to true to show blips
    sprite = 618,
    color = 47,
    scale = 0.6,
    name = 'Copper Source',
}

-- Target Settings
Config.TargetDistance = 2.0 -- Distance to interact with targets

-- Theft Locations (Prop-Based)
-- Types: electrical, plumbing, hvac, infrastructure, building, vehicle
-- Now uses prop models instead of coordinates
-- Common GTA V prop models:
-- Electrical: prop_elecbox_01a, prop_elecbox_02a, prop_elecbox_03a, prop_elecbox_04a, prop_utilitybox_01a, prop_utilitybox_02a
-- HVAC: prop_ac_unit_01, prop_ac_leaflet_01
-- Plumbing: prop_pipe_01, prop_pipe_02, prop_pipe_03, prop_pipe_04, prop_pipe_05, prop_pipe_06
-- Infrastructure: prop_transformer_01, prop_transformer_02, prop_utilitybox_01a, prop_utilitybox_02a
-- Building: Various building props
-- Vehicle: Vehicle models (use vehicle hash)
Config.Locations = {
    -- ===== ELECTRICAL LOCATIONS =====
    -- These props can be found throughout the map
    {
        model = `prop_elecbox_01a`,
        type = 'electrical',
        label = 'Power Junction Box',
        description = 'Strip copper wiring from junction box',
    },
    {
        model = `prop_elecbox_01b`,
        type = 'electrical',
        label = 'Power Junction Box',
        description = 'Strip copper wiring from junction box',
    },
    {
        model = `prop_elecbox_02a`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_03a`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_04a`,
        type = 'electrical',
        label = 'Transformer Station',
        description = 'Strip grounding wires',
    },
    {
        model = `prop_elecbox_05a`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_07a`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_09`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_10_cr`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_11`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_13`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_14`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_15`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_15_cr`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_16`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_17`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_17_cr`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_19`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_20`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_23`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_elecbox_25`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Remove copper wiring from panel',
    },
    {
        model = `prop_utilitybox_01a`,
        type = 'electrical',
        label = 'Telecom Cabinet',
        description = 'Strip communication cables',
    },
    {
        model = `prop_utilitybox_02a`,
        type = 'electrical',
        label = 'Telecom Cabinet',
        description = 'Strip communication cables',
    },
    {
        model = `v_ind_cm_electricbox`,
        type = 'electrical',
        label = 'Industrial Electric Box',
        description = 'Strip industrial wiring',
    },
    {
        model = `m23_1_prop_m31_electricbox_01a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip copper wiring',
    },
    {
        model = `m23_1_prop_m31_electricbox_02a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip copper wiring',
    },
    {
        model = `m23_1_prop_m31_electricbox_03a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip copper wiring',
    },
    {
        model = `m24_1_prop_m41_electricbox_01a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip copper wiring',
    },
    {
        model = `xm3_prop_xm3_power_box_01a`,
        type = 'electrical',
        label = 'Power Box',
        description = 'Strip power wiring',
    },
    {
        model = `v_ind_meatbutton`,
        type = 'electrical',
        label = 'Control Panel',
        description = 'Strip control wiring',
    },
    {
        model = `tr_int1_mod_elec_01`,
        type = 'electrical',
        label = 'Electrical Panel',
        description = 'Strip electrical wiring',
    },
    {
        model = `v_29_contmetcabs`,
        type = 'electrical',
        label = 'Control Cabinet',
        description = 'Strip control wiring',
    },
    {
        model = `m24_1_prop_m41_circuitbox_01a`,
        type = 'electrical',
        label = 'Circuit Box',
        description = 'Strip circuit wiring',
    },
    {
        model = `m24_1_prop_m41_circuitbox_open_01a`,
        type = 'electrical',
        label = 'Circuit Box',
        description = 'Strip circuit wiring',
    },
    {
        model = `m23_1_prop_m31_controlpanel_02a`,
        type = 'electrical',
        label = 'Control Panel',
        description = 'Strip control wiring',
    },
    {
        model = `m24_1_prop_m41_controlpanel_01a`,
        type = 'electrical',
        label = 'Control Panel',
        description = 'Strip control wiring',
    },
    {
        model = `prop_byard_elecbox01`,
        type = 'electrical',
        label = 'Yard Electric Box',
        description = 'Strip yard wiring',
    },
    {
        model = `prop_byard_elecbox02`,
        type = 'electrical',
        label = 'Yard Electric Box',
        description = 'Strip yard wiring',
    },
    {
        model = `prop_byard_elecbox04`,
        type = 'electrical',
        label = 'Yard Electric Box',
        description = 'Strip yard wiring',
    },
    {
        model = `h4_prop_h4_lever_box_01a`,
        type = 'electrical',
        label = 'Control Box',
        description = 'Strip control wiring',
    },
    {
        model = `h4_prop_h4_fuse_box_01a`,
        type = 'electrical',
        label = 'Fuse Box',
        description = 'Strip fuse wiring',
    },
    {
        model = `h4_prop_h4_elecbox_01a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip electrical wiring',
    },
    {
        model = `m25_2_prop_m52_elecbox_01a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip electrical wiring',
    },
    {
        model = `prop_elecbox_23`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip electrical wiring',
    },
    {
        model = `vw_prop_vw_elecbox_01a`,
        type = 'electrical',
        label = 'Electric Box',
        description = 'Strip electrical wiring',
    },
    {
        model = `port_xr_elecbox_1`,
        type = 'electrical',
        label = 'Port Electric Box',
        description = 'Strip port wiring',
    },
    {
        model = `ch_prop_ch_fuse_box_01a`,
        type = 'electrical',
        label = 'Fuse Box',
        description = 'Strip fuse wiring',
    },
    {
        model = `v_med_lab_elecbox2`,
        type = 'electrical',
        label = 'Lab Electric Box',
        description = 'Strip lab wiring',
    },
    {
        model = `imp_carwarecarwarelecboxes2`,
        type = 'electrical',
        label = 'Car Warehouse Electric Box',
        description = 'Strip warehouse wiring',
    },
    {
        model = `h4_prop_h4_dj_t_wires_01a`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },
    {
        model = `v_25_securitywires`,
        type = 'electrical',
        label = 'Security Wires',
        description = 'Strip security wiring',
    },
    {
        model = `ba_prop_battle_dj_wires_tale`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },
    {
        model = `h4_prop_battle_dj_wires_madonna`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },
    {
        model = `h4_prop_battle_dj_wires_tale`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },
    {
        model = `ba_prop_battle_dj_wires_dixon`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },
    {
        model = `h4_prop_h4_dj_wires_01a`,
        type = 'electrical',
        label = 'DJ Wires',
        description = 'Strip DJ wiring',
    },

    -- ===== PLUMBING LOCATIONS =====
    {
        model = `prop_pipe_01`, -- Pipe prop
        type = 'plumbing',
        label = 'Exposed Pipes',
        description = 'Cut exposed copper pipes',
    },
    {
        model = `prop_pipe_02`, -- Pipe prop variant
        type = 'plumbing',
        label = 'Exposed Pipes',
        description = 'Cut exposed copper pipes',
    },
    {
        model = `prop_pipe_03`, -- Pipe prop variant
        type = 'plumbing',
        label = 'Construction Plumbing',
        description = 'Remove uninstalled copper pipes',
    },
    {
        model = `prop_pipe_04`, -- Pipe prop variant
        type = 'plumbing',
        label = 'Plumbing Fixtures',
        description = 'Strip plumbing fixtures',
    },
    {
        model = `prop_pipe_05`, -- Pipe prop variant
        type = 'plumbing',
        label = 'Copper Tubing',
        description = 'Cut copper water tubing',
    },
    {
        model = `prop_pipe_06`, -- Pipe prop variant
        type = 'plumbing',
        label = 'Copper Tubing',
        description = 'Cut copper water tubing',
    },

    -- ===== HVAC LOCATIONS =====
    {
        model = `prop_ac_unit_01`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_ac_leaflet_01`,
        type = 'hvac',
        label = 'Rooftop AC Unit',
        description = 'Remove AC coils',
    },
    {
        model = `prop_aircon_s_01a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_02a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_02b`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_03a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_03b`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_04a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_07a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_s_07b`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_01`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_02`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_03`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_04`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_05`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_07`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_m_08`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_l_01`,
        type = 'hvac',
        label = 'Large AC Unit',
        description = 'Strip large HVAC coils and wiring',
    },
    {
        model = `prop_aircon_l_02`,
        type = 'hvac',
        label = 'Large AC Unit',
        description = 'Strip large HVAC coils and wiring',
    },
    {
        model = `prop_aircon_l_03`,
        type = 'hvac',
        label = 'Large AC Unit',
        description = 'Strip large HVAC coils and wiring',
    },
    {
        model = `prop_aircon_l_03_dam`,
        type = 'hvac',
        label = 'Damaged AC Unit',
        description = 'Strip damaged HVAC coils and wiring',
    },
    {
        model = `prop_aircon_t_03`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_aircon_tna_02`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `prop_cs_aircon_01`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_prop_vw_aircon_m_01`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_aircon_01_lod`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_aircon_03_lod`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_aircon_04_lod`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_aircon_05_lod`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `vw_aircon_06_lod`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `m25_1_prop_m51_airconunit_01a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `m23_2_prop_m32_aircon_01a`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `ch_prop_ch_aircon_l_broken03`,
        type = 'hvac',
        label = 'Broken AC Unit',
        description = 'Strip broken HVAC coils and wiring',
    },
    {
        model = `hw1_17_aircon_climb`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `hw1_17_aircon_climb001`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },
    {
        model = `hw1_17_props_aircon_climb002`,
        type = 'hvac',
        label = 'AC Unit',
        description = 'Strip HVAC coils and wiring',
    },

    -- ===== INFRASTRUCTURE LOCATIONS =====
    {
        model = `prop_transformer_01`, -- Transformer
        type = 'infrastructure',
        label = 'Transformer Station',
        description = 'Strip signal wiring',
    },
    {
        model = `prop_transformer_02`, -- Transformer variant
        type = 'infrastructure',
        label = 'Transformer Station',
        description = 'Strip pump motor wiring',
    },
    {
        model = `prop_utilitybox_01a`, -- Utility box (shared with electrical)
        type = 'infrastructure',
        label = 'Traffic Signal Cabinet',
        description = 'Strip traffic signal wiring',
    },
    {
        model = `prop_utilitybox_02a`, -- Utility box variant (shared with electrical)
        type = 'infrastructure',
        label = 'Utility Box',
        description = 'Strip utility pole wiring',
    },

    -- ===== BUILDING LOCATIONS =====
    -- Note: Building props are less common, you may need to use specific building models
    -- For now, we'll use some common props that might be found in/on buildings
    {
        model = `prop_elecbox_01a`, -- Can be found on buildings
        type = 'building',
        label = 'Abandoned Building Wiring',
        description = 'Strip internal wiring',
    },
    {
        model = `prop_elecbox_02a`, -- Can be found on buildings
        type = 'building',
        label = 'Building Copper',
        description = 'Strip roofing and wiring',
    },

    -- ===== VEHICLE/MACHINERY LOCATIONS =====
    -- Note: For vehicles, you'll need to specify vehicle model hashes
    -- Common abandoned/industrial vehicles: 'sadler', 'bison', 'benson', 'mule', 'phantom'
    -- You can add specific vehicle models here if needed
    -- For now, we'll leave vehicle targeting to be handled differently if needed
}

-- Scrap Yard Settings
Config.ScrapYards = {
    blipsEnabled = true, -- Global setting to enable/disable all scrapyard blips
    
    -- Scrap Yard Locations (for selling copper)
    -- Now uses PEDs with model a_m_m_hillbilly_01
    locations = {
        {
            coords = vec3(2340.7, 3126.44, 48.21),
            heading = 0.38, -- PED facing direction (0-360)
            label = 'Sandy Shores Scrap',
            blip = {
                enabled = true,
                sprite = 566,
                color = 47,
                scale = 0.7,
                name = 'Scrap Yard',
            },
        },
        {
            coords = vec3(-498.93, -1714.08, 19.9),
            heading = 112.60, -- PED facing direction (0-360)
            label = 'LS Salvage',
            blip = {
                enabled = true,
                sprite = 566,
                color = 47,
                scale = 0.7,
                name = 'Scrap Yard',
            },
        },
    },
}

-- Sell Prices (price per item in dirty money or clean money)
Config.SellPrices = {
    copper_wire = { min = 15, max = 25 },
    copper_pipe = { min = 35, max = 55 },
    hvac_coil = { min = 75, max = 125 },
    ac_coil = { min = 85, max = 140 },
}

-- Use dirty money (markedbills) or clean money
Config.UseDirtyMoney = false
Config.DirtyMoneyItem = 'markedbills' -- Item to give if using dirty money

-- Notification Settings
Config.Notifications = {
    type = 'ox_lib', -- 'ox_lib', 'qb', or 'custom'
}

return Config
