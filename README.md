# bs_coppertheft

A copper theft script for FiveM servers running the Qbox Framework. 
Players can steal copper from various props throughout the map using tools and sell their haul at scrap yards.

## Features

- **Prop-Based Theft System**: Interact with electrical boxes, AC units, pipes, and other props throughout the map
- **Multiple Theft Types**: Electrical, Plumbing, HVAC, Infrastructure, Building, and Vehicle locations
- **Tool Requirements**: Different locations require different tools (wire cutters, pipe cutters, crowbar)
- **Tool Durability**: Tools degrade over use and can break
- **Skill Checks**: Optional ox_lib skill checks for added difficulty
- **Hazard System**: Failed skill checks can result in electrocution or burns with realistic effects
- **Visual Effects**: Broken props show smoke/spark effects after being looted
- **Police Alerts**: Configurable chance to alert police during theft
- **Smart Cooldown System**: Configurable loot limit before cooldown kicks in
- **Scrap Yard Selling**: Sell stolen copper at scrap yard PEDs for cash or dirty money
- **Full ox_target Integration**: Easy-to-use prop and PED targeting
- **Circular Progress Bars**: Modern circular progress indicators
- **Sound Effects**: Custom sound integration via InteractSound
- **Highly Configurable**: Nearly every aspect can be customized in config.lua

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core) - Qbox Core Framework
- [ox_lib](https://github.com/overextended/ox_lib) - Overextended Library
- [ox_target](https://github.com/overextended/ox_target) - Target System
- [ox_inventory](https://github.com/overextended/ox_inventory) - Inventory System
- [interact-sound](https://github.com/plunkettscott/interact-sound) - Sound System (optional, for custom sounds)

## Installation

1. **Download and Extract**
   - Place the `bs__coppertheft` folder in your server's `resources` directory

2. **Add Items to ox_inventory**
   - Open `ox_inventory/data/items.lua`
   - Add the item definitions from `items.lua` included in this resource:
   
   ```lua
   -- Tools
   ['wire_cutters'] = {
       label = 'Wire Cutters',
       weight = 350,
       stack = false,
       close = true,
       description = 'Heavy duty wire cutters for cutting copper wiring',
       durability = 100,
   },
   ['pipe_cutters'] = {
       label = 'Pipe Cutters',
       weight = 500,
       stack = false,
       close = true,
       description = 'Professional pipe cutters for cutting copper pipes',
       durability = 100,
   },
   ['crowbar'] = {
       label = 'Crowbar',
       weight = 800,
       stack = false,
       close = true,
       description = 'A sturdy crowbar for prying open panels and units',
       durability = 100,
   },
   
   -- Loot Items
   ['copper_wire'] = {
       label = 'Copper Wire',
       weight = 150,
       stack = true,
       close = true,
       description = 'Stripped copper wiring, valuable at scrap yards',
   },
   ['copper_pipe'] = {
       label = 'Copper Pipe',
       weight = 400,
       stack = true,
       close = true,
       description = 'Cut copper plumbing pipes, good scrap value',
   },
   ['hvac_coil'] = {
       label = 'HVAC Coil',
       weight = 1200,
       stack = true,
       close = true,
       description = 'Copper heating coil from an HVAC unit',
   },
   ['ac_coil'] = {
       label = 'AC Coil',
       weight = 1500,
       stack = true,
       close = true,
       description = 'Copper cooling coil from an air conditioning unit',
   },
   ```

3. **Install InteractSound (Optional but Recommended)**
   - Download from: https://github.com/plunkettscott/interact-sound
   - Place in your `resources` folder
   - Add `ensure interact-sound` to your `server.cfg`
   - Place `electrocute.ogg` and `wire_cut.ogg` in `interact-sound/client/html/sounds/`
   - Add the sound files to `interact-sound/fxmanifest.lua` or `__resource.lua`:
     ```lua
     files({
         'client/html/index.html',
         'client/html/sounds/electrocute.ogg',
         'client/html/sounds/wire_cut.ogg',
     })
     ```

4. **Add to server.cfg**
   ```cfg
   ensure ox_lib
   ensure ox_target
   ensure ox_inventory
   ensure qbx_core
   ensure interact-sound  # Optional, for custom sounds
   ensure bs__coppertheft
   ```

5. **Configure the Script**
   - Edit `config.lua` to customize props, loot tables, prices, and more

## Configuration

### Prop-Based Theft Locations

The script uses a **prop-based approach** - players can interact with specific prop models throughout the map. Each location in `Config.Locations` has the following structure:

```lua
{
    model = `prop_elecbox_01a`,  -- GTA V prop model hash
    type = 'electrical',         -- Type: electrical, plumbing, hvac, infrastructure, building, vehicle
    label = 'Power Junction Box', -- Display label for target
    description = 'Strip copper wiring from junction box', -- Progress bar text
}
```

**Supported Prop Models:**
- **Electrical**: `prop_elecbox_*`, `prop_utilitybox_*`, and many more (see config for full list)
- **HVAC**: `prop_aircon_*`, `prop_ac_unit_*`, and various AC unit models
- **Plumbing**: `prop_pipe_*` series
- **Infrastructure**: `prop_transformer_*`, utility boxes
- And many more - see `config.lua` for the complete list

### Cooldown System

Configure how many successful loots are allowed before cooldown applies:

```lua
Config.Cooldowns = {
    enabled = true,
    lootsBeforeCooldown = 3,  -- Number of successful loots before cooldown (0 = cooldown after every loot)
    global = 60,               -- Global cooldown in seconds
    perLocation = 300,        -- Per-prop cooldown in seconds (5 minutes)
}
```

### Hazard Recovery Time

Configure how long players must wait after being electrocuted/burned:

```lua
Config.Hazards = {
    enabled = true,
    recoveryTime = 5000,  -- Global recovery time in ms (how long player must wait after hazard)
    electrical = {
        type = 'electrocution',
        chance = 65,
        damage = { min = 15, max = 35 },
        duration = 3000,
    },
    -- ... other types
}
```

### Loot Tables

Configure what items drop and their chances:

```lua
Config.Loot = {
    electrical = {
        { item = 'copper_wire', min = 1, max = 4, chance = 80 },
        { item = 'copper_wire', min = 2, max = 6, chance = 40 },
    },
    -- Add more as needed
}
```

### Tool Requirements

Define which tools are needed for each type:

```lua
Config.RequiredTools = {
    electrical = { 'wire_cutters' },
    plumbing = { 'pipe_cutters' },
    hvac = { 'wire_cutters', 'crowbar' },
    -- etc.
}
```

### Scrapyard Configuration

Scrapyards use PEDs with the model `a_m_m_hillbilly_01`:

```lua
Config.ScrapYards = {
    blipsEnabled = true,  -- Global toggle for scrapyard blips
    locations = {
        {
            coords = vec3(x, y, z),
            heading = 180.0,  -- PED facing direction (0-360)
            label = 'Scrapyard Name',
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
```

### Sell Prices

Configure prices at scrap yards:

```lua
Config.SellPrices = {
    copper_wire = { min = 15, max = 25 },
    copper_pipe = { min = 35, max = 55 },
    hvac_coil = { min = 75, max = 125 },
    ac_coil = { min = 85, max = 140 },
}
```

### Progress Bar Settings

Progress bars are circular and positioned at the bottom center:

```lua
Config.ProgressTime = {
    electrical = 8000,   -- Time in milliseconds
    plumbing = 10000,
    hvac = 15000,
    -- etc.
}
```

## Admin Commands

- `/givecoppertools` - Give yourself all copper theft tools (requires admin)
- `/givecopper` - Give yourself copper items for testing (requires admin)
- `/resetcopperhazard` - Reset stuck hazard state (debug command)

## Theft Types Explained

| Type | Description | Required Tools | Typical Loot | Hazard Type |
|------|-------------|----------------|--------------|-------------|
| Electrical | Power lines, transformers, junction boxes | Wire Cutters | Copper Wire | Electrocution (65%) |
| Plumbing | Pipes from buildings, construction sites | Pipe Cutters | Copper Pipe | None |
| HVAC | AC units, rooftop units | Wire Cutters + Crowbar | HVAC Coil, AC Coil, Copper Wire | Both (55%) |
| Infrastructure | Utility poles, railroad signals, water pumps | Wire Cutters + Crowbar | Copper Wire, Copper Pipe | Electrocution (70%) |
| Building | Abandoned buildings, gutters, internal wiring | Crowbar | Copper Wire, Copper Pipe | Electrocution (40%) |
| Vehicle | Abandoned vehicles, industrial machinery | Crowbar + Wire Cutters | Copper Wire, AC Coil | Burn (45%) |

## Hazard System

When a player fails a skill check, there's a chance they'll suffer a hazard based on the location type:

### Electrocution
- **Triggered by**: Electrical, Infrastructure, Building, and HVAC locations
- **Effects**: 
  - Electric particle effects on player
  - Ragdoll (player falls down)
  - Sound effect (electrocute.ogg via InteractSound)
  - No screen flashing (removed for better experience)
- **Damage**: Configurable min/max damage
- **Recovery Time**: Configurable global recovery time

### Burns
- **Triggered by**: Vehicle and HVAC locations
- **Effects**: Fire particles on player, damage over time
- **Damage**: Applied in ticks over the duration

### Configuration

```lua
Config.Hazards = {
    enabled = true,
    recoveryTime = 5000,  -- Global recovery time in ms
    electrical = {
        type = 'electrocution',  -- 'electrocution', 'burn', 'both', 'none'
        chance = 65,              -- % chance on failed skill check
        damage = { min = 15, max = 35 },
        duration = 3000,          -- Effect duration in ms
    },
    -- Configure other types...
}

Config.HazardEffects = {
    electrocution = {
        ragdoll = true,
        ragdollTime = 3000,
        sound = true,
        taserAnim = true,
    },
    burn = {
        screenEffect = 'DrugsDrivingIn',
        ragdoll = false,
        sound = true,
        fireParticle = true,
        fireDuration = 2000,
    },
}
```

## Visual Effects

### Broken Props
After successfully looting a prop:
- **Spark animations** appear immediately (larger size for visibility)
- **Black smoke effects** appear after 1 second
- Props are marked as broken and cannot be looted again
- Effects persist until the prop is removed or resource stops

### Progress Bars
- All progress bars are **circular**
- Positioned at **bottom center** of screen
- Shows progress with smooth animation

## Sound System

The script uses **InteractSound** for custom sound effects:

- **electrocute.ogg** - Plays when player gets electrocuted
- **wire_cut.ogg** - Plays during progress bar when successfully looting

If InteractSound is not installed, the script falls back to native GTA V sounds.

## Dispatch Integration

The script supports police alerts and integrates with:
- Default QB police alerts
- ps-dispatch (if installed)

Configure alerts in `Config.PoliceAlert`:

```lua
Config.PoliceAlert = {
    enabled = true,
    chance = 35,           -- % chance to trigger alert
    requiredCops = 0,      -- Minimum cops online
    alertMessage = 'Suspicious activity reported - Possible copper theft',
}
```

## Money System

Configure whether selling gives dirty money or clean cash:

```lua
Config.UseDirtyMoney = false  -- Set to true for marked bills, false for clean cash
Config.DirtyMoneyItem = 'markedbills'  -- Item for dirty money
```

## Troubleshooting

**Items not showing in inventory:**
- Make sure you added all items to `ox_inventory/data/items.lua`
- Restart ox_inventory after adding items

**Props not targetable:**
- Ensure ox_target is properly installed and running
- Enable `Config.Debug = true` to see prop registration messages
- Check that the prop models exist in your game

**Sound effects not playing:**
- Ensure InteractSound resource is installed and running
- Check that sound files are in `interact-sound/client/html/sounds/`
- Verify sound files are added to the resource manifest
- Check F8 console for debug messages about sound playback

**Scrapyard PEDs not appearing:**
- Check that the PED model `a_m_m_hillbilly_01` is valid
- Enable `Config.Debug = true` to see PED spawn messages
- Verify coordinates are correct in config

**Hazard state stuck:**
- Use `/resetcopperhazard` command to manually reset
- Check recovery time configuration
- Enable debug mode to see recovery progress

**Progress bars not showing:**
- Ensure ox_lib is properly installed and updated
- Check that circular progress bars are supported in your ox_lib version

## License

This resource is provided as-is for use on your FiveM server. Feel free to modify and adapt it to your needs.

## Support

For issues or feature requests, please open an issue on the repository or contact the script author.

