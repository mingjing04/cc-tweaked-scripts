# CC:Tweaked Development Notes

## CI/CD: GitHub + wget

### Push to GitHub
```bash
git remote add origin https://github.com/yourusername/cc-tweaked-scripts.git
git branch -M main
git push -u origin main
```

### Update in CC
```lua
wget https://raw.githubusercontent.com/yourusername/cc-tweaked-scripts/main/branchMining.lua branchMining.lua
```

---

## Branch Mining Program Features

### Core Features
- **Branch mining pattern**: Main 2x2 tunnel with 2x1 branches every 3 blocks
- **Auto torch placement**: Place torches every 8 blocks to prevent mob spawns
- **Fuel management**: Return to start when fuel is low, refuel, and resume
- **Inventory management**: Return to start when inventory is full, dump to chest, and resume
- **Resume capability**: Save progress and resume after refuel/dump

### Safety Features
- **Gravel/sand detection**: Detect and clear falling blocks (keep mining until stable)
- **Liquid detection**: Detect water/lava and seal with cobblestone blocks
  - Turtles are immune to lava damage
  - Place blocks to prevent liquids from flooding the mine
- **Bedrock detection**: Stop when hitting bedrock

### Advanced Features
- **Configurable parameters**:
  - Branch length
  - Branch spacing
  - Mining depth/level
  - Number of branches
- **Progress tracking**: Display blocks mined, fuel used, time elapsed
- **Ore vein mining**:
  - Detect ores using `turtle.inspect()`
  - When ore found, recursively mine entire vein in all 6 directions
  - Save position before vein mining
  - Return to exact position after vein is complete
  - Track visited blocks to avoid infinite loops
- **Ore tracking**: Count and report valuable ores mined by type

### Configuration

**Interactive Prompts** (asked when you run the program):
- Branch length: How long each branch should be
- Number of branches: How many branches to mine
- Branch spacing: Blocks between each branch (recommended: 3)
- Target Y-level: Mining depth coordinate (recommended: -59 for diamonds)

**Config File** (`mining_config.txt` - edit manually):
```lua
{
  fuel_reserve = 500,           -- Min fuel before returning to refuel
  torch_interval = 8,           -- Blocks between torch placement
  return_when_full = true,      -- Auto-return when inventory full
  chest_slot = 1,               -- Which slot has the ender chest
  torch_slot = 2,               -- Which slot has torches
  cobble_slot = 3,              -- Which slot has cobblestone (for sealing liquids)
  mine_veins = true,            -- Enable automatic ore vein mining
  valuable_ores = {             -- Ores to track and vein mine
    "minecraft:diamond_ore",
    "minecraft:deepslate_diamond_ore",
    "minecraft:iron_ore",
    "minecraft:deepslate_iron_ore",
    "minecraft:gold_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:redstone_ore",
    "minecraft:deepslate_redstone_ore",
    "minecraft:lapis_ore",
    "minecraft:deepslate_lapis_ore",
    "minecraft:emerald_ore",
    "minecraft:deepslate_emerald_ore",
    "minecraft:copper_ore",
    "minecraft:deepslate_copper_ore"
  }
}
```

### Implementation Details

**Navigation System** (No GPS required):
- **Relative position tracking**: Track position relative to starting point (0, 0, 0)
- **Direction tracking**: Track facing direction (0=north, 1=east, 2=south, 3=west)
- **Movement counting**: Update position with each move (forward/back/up/down/turn)
- **Pathfinding**: Calculate path back to start for inventory dump/refuel
- **Limitation**: Position can desync if turtle is forcibly moved (picked up by player)
- **Future**: GPS integration for absolute positioning (optional upgrade)

**Ore Vein Mining Algorithm**:
1. During normal mining, inspect each block before breaking
2. If ore detected → save current position (x, y, z, facing)
3. Start recursive vein mining:
   - Mine current ore block
   - Check all 6 adjacent blocks
   - For each ore found, recursively mine it
   - Mark blocks as visited to prevent loops
4. When vein complete → navigate back to saved position
5. Resume normal mining pattern

**Liquid Handling**:
1. Detect liquid with `turtle.inspect()`
2. If liquid source found:
   - Select cobblestone slot
   - Place block to seal the source
   - Continue mining
3. If liquid keeps flowing → place multiple blocks to contain it

### Usage
```lua
> branchMining
Branch length? (default: 30): 25
Number of branches? (default: 20): 15
Spacing between branches? (default: 3): 3
Target Y-level? (default: -59): -59
Starting branch mining operation...
```

---

## Implementation Roadmap

### Phase 1: Core Movement & Mining (MVP)
- [ ] Basic turtle movement functions (forward, back, turn, up, down)
- [ ] Position tracking system (x, y, z, facing direction)
- [ ] Safe dig function (dig until stable - handles gravel/sand)
- [ ] Basic branch mining pattern (main tunnel + side branches)
- [ ] Interactive prompts for configuration

### Phase 2: Fuel & Inventory Management
- [ ] Fuel level monitoring
- [ ] Auto-refuel from mined coal in inventory
- [ ] Fuel estimation calculator (warn if not enough fuel to start)
- [ ] Inventory full detection
- [ ] Return to base and dump to chest
- [ ] Resume from saved position after dump

### Phase 3: Safety & Quality of Life
- [ ] Torch placement system (every N blocks)
- [ ] Liquid detection and sealing with cobblestone
- [ ] Bedrock detection and handling
- [ ] Progress display (blocks mined, fuel used, time elapsed)
- [ ] Save/resume state to file (recover from crashes/shutdowns)

### Phase 4: Ore Vein Mining
- [ ] Ore detection system using `turtle.inspect()`
- [ ] Recursive vein mining algorithm (6-direction search)
- [ ] Position saving before vein mining
- [ ] Navigation back to saved position
- [ ] Visited blocks tracking (prevent infinite loops)
- [ ] Ore counting and reporting by type

### Phase 5: Polish & Advanced Features
- [ ] Config file loading (`mining_config.txt`)
- [ ] Better error handling and recovery
- [ ] Status display/UI improvements
- [ ] Support for multiple chest types (ender, regular)
- [ ] Optimize pathfinding for return trips
- [ ] Add pause/resume commands

### Phase 6: GPS Integration (Optional Upgrade)
- [ ] Detect GPS availability on startup
- [ ] Use GPS for absolute positioning if available
- [ ] Fall back to relative tracking if GPS unavailable
- [ ] GPS-based position verification (detect if turtle was moved)
- [ ] Auto-correction when position desync detected
