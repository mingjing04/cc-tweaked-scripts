# CC:Tweaked Development Notes

## Turtle API Reference

### Fuel System (CRITICAL!)
Turtles need fuel to move. Without fuel, movement functions return `false`.

```lua
turtle.getFuelLevel()      -- Returns current fuel (number) or "unlimited"
turtle.getFuelLimit()      -- Returns max capacity (normal: 20,000, advanced: 100,000)
turtle.refuel([quantity])  -- Consume items from selected slot as fuel
turtle.refuel(0)           -- Test if selected item is fuel (doesn't consume)
```

**Fuel values (approximate):**
- Coal/Charcoal: 80 fuel
- Coal Block: 800 fuel
- Lava Bucket: 1000 fuel
- Blaze Rod: 120 fuel
- Wood/Planks: 15 fuel

### Movement Functions
All return `boolean, string?` - success and optional error message.

```lua
turtle.forward()    -- Move forward (costs 1 fuel)
turtle.back()       -- Move backward (costs 1 fuel)
turtle.up()         -- Move up (costs 1 fuel)
turtle.down()       -- Move down (costs 1 fuel)
turtle.turnLeft()   -- Turn left (FREE - no fuel cost)
turtle.turnRight()  -- Turn right (FREE - no fuel cost)
```

### Digging Functions
```lua
turtle.dig([side])      -- Dig block in front
turtle.digUp([side])    -- Dig block above
turtle.digDown([side])  -- Dig block below
-- side: optional "left" or "right" to use specific tool
```

### Block Detection
```lua
turtle.detect()       -- Returns true if solid block in front
turtle.detectUp()     -- Returns true if solid block above
turtle.detectDown()   -- Returns true if solid block below
```

### Block Inspection (returns block info)
```lua
turtle.inspect()      -- Returns hasBlock, blockInfo table
turtle.inspectUp()
turtle.inspectDown()
-- blockInfo: { name = "minecraft:stone", state = {...}, tags = {...} }
```

### Inventory Management
```lua
turtle.select(slot)           -- Select slot 1-16
turtle.getSelectedSlot()      -- Get current slot number
turtle.getItemCount([slot])   -- Count items in slot (default: selected)
turtle.getItemSpace([slot])   -- Space remaining in slot
turtle.getItemDetail([slot])  -- Get item info { name, count }
turtle.transferTo(slot, [count])  -- Move items to another slot
turtle.compareTo(slot)        -- Compare selected to another slot
```

### Interaction Functions
```lua
turtle.place()        -- Place block from selected slot
turtle.placeUp()
turtle.placeDown()

turtle.drop([count])      -- Drop items into inventory/world in front
turtle.dropUp([count])
turtle.dropDown([count])

turtle.suck([count])      -- Pick up items from inventory/world
turtle.suckUp([count])
turtle.suckDown([count])

turtle.attack([side])     -- Attack entity in front
turtle.attackUp([side])
turtle.attackDown([side])
```

### Equipment
```lua
turtle.equipLeft()        -- Equip item from selected slot to left
turtle.equipRight()       -- Equip item from selected slot to right
turtle.getEquippedLeft()  -- Get info about left upgrade
turtle.getEquippedRight() -- Get info about right upgrade
```

### Events
```lua
os.pullEvent("turtle_inventory")  -- Fired when inventory changes
```

---

## Common Patterns

### Safe Movement with Fuel Check
```lua
local function refuel(needed)
    local level = turtle.getFuelLevel()
    if level == "unlimited" then return true end
    if level >= needed then return true end

    -- Try to refuel from inventory
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) then  -- Test if fuel
                while turtle.getFuelLevel() < needed and turtle.getItemCount(slot) > 0 do
                    turtle.refuel(1)
                end
                if turtle.getFuelLevel() >= needed then
                    return true
                end
            end
        end
    end
    return false
end

local function safeForward()
    if not refuel(1) then
        print("Out of fuel!")
        return false
    end
    while not turtle.forward() do
        if turtle.detect() then
            if not turtle.dig() then
                return false  -- Bedrock or protected
            end
        elseif turtle.attack() then
            -- Attacked entity blocking path
        else
            sleep(0.5)
        end
    end
    return true
end
```

### Handling Gravel/Sand
```lua
local function digForward()
    while turtle.detect() do
        if not turtle.dig() then
            return false  -- Can't dig (bedrock)
        end
        sleep(0.5)  -- Wait for falling blocks
    end
    return true
end
```

### Ore Detection
```lua
local function isOre(name)
    return name:find("_ore$") ~= nil
end

local function checkForOres()
    local hasBlock, data = turtle.inspect()
    if hasBlock and isOre(data.name) then
        print("Found ore: " .. data.name)
        return true
    end
    return false
end
```

---

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

## Implementation Roadmap

### Phase 1: Core Movement & Mining (MVP) - CURRENT
- [x] Basic turtle movement functions (forward, back, turn, up, down)
- [x] Position tracking system (x, y, z, facing direction)
- [x] Safe dig function (dig until stable - handles gravel/sand)
- [x] Basic branch mining pattern (main tunnel + side branches)
- [x] Interactive prompts for configuration
- [x] **FIXED: Add fuel checking before movement**
- [x] **FIXED: Add auto-refuel from inventory**
- [x] **FIXED: Turn back to main tunnel after branch (see bug below)**
- [x] Better status output (shows LEFT/RIGHT, branch number)

---

## Bugs Found & Fixed

### BUG: Turtle not turning back to main tunnel after branch
**Found:** After `mineBranch()` returned, the turtle was facing INTO the branch instead of along the main tunnel.

**Cause:** Original code had 4x `turnRight()` in `mineBranch()`:
```lua
-- Original (wrong)
turnRight()  -- 1. Turn around (180°)
turnRight()  -- 2.
-- walk back --
turnRight()  -- 3. Turn another 180° (total 360° = same direction)
turnRight()  -- 4.
```
This made the turtle face the branch direction again, not the main tunnel.

**Fix:**
1. `mineBranch()` now only does 2x turnRight to turn around and walk back
2. `executeMining()` now turns back to main tunnel direction after each branch:
```lua
-- After mineBranch returns, turtle faces opposite of entry direction
if side == 0 then
    turnRight()  -- Entered via turnLeft, so turnRight to face main tunnel
else
    turnLeft()   -- Entered via turnRight, so turnLeft to face main tunnel
end
```

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
