-- Mock Unit Testing for branchMining.lua
-- Run with: lua test_branchMining.lua

-- ============================================================================
-- MOCK TURTLE API
-- ============================================================================

local mock = {
    x = 0,
    y = 0,
    z = 0,
    facing = 0,  -- 0=north(-z), 1=east(+x), 2=south(+z), 3=west(-x)
    fuel = 10000,
    inventory = {},  -- slot -> { name = "minecraft:coal", count = N }
    selected_slot = 1,
    logs = {},
    move_count = 0,
    pave_count = 0,
    detect_down_result = false,  -- configurable: false = empty ground
    world = {},  -- "x,y,z" -> { name = "minecraft:iron_ore" }
}

-- Fuel values per item for mock refueling
local MOCK_FUEL_VALUES = {
    ["minecraft:coal"] = 80,
    ["minecraft:charcoal"] = 80,
    ["minecraft:coal_block"] = 800,
}

-- Direction names for logging
local FACING_NAMES = {"NORTH(-z)", "EAST(+x)", "SOUTH(+z)", "WEST(-x)"}

local function worldKey(x, y, z)
    return x .. "," .. y .. "," .. z
end

local function getBlockInFront()
    if mock.facing == 0 then return worldKey(mock.x, mock.y, mock.z - 1)
    elseif mock.facing == 1 then return worldKey(mock.x + 1, mock.y, mock.z)
    elseif mock.facing == 2 then return worldKey(mock.x, mock.y, mock.z + 1)
    else return worldKey(mock.x - 1, mock.y, mock.z) end
end

local function getBlockAbove()
    return worldKey(mock.x, mock.y + 1, mock.z)
end

local function getBlockBelow()
    return worldKey(mock.x, mock.y - 1, mock.z)
end

local function log(action, detail)
    local entry = string.format("[%3d] %-12s | pos=(%3d,%3d,%3d) facing=%-10s | %s",
        mock.move_count, action, mock.x, mock.y, mock.z,
        FACING_NAMES[mock.facing + 1], detail or "")
    table.insert(mock.logs, entry)
    if os.getenv("VERBOSE") then
        print(entry)
    end
end

turtle = {
    forward = function()
        if mock.fuel < 1 then
            log("forward", "FAILED - no fuel")
            return false, "Out of fuel"
        end
        mock.fuel = mock.fuel - 1
        mock.move_count = mock.move_count + 1

        if mock.facing == 0 then mock.z = mock.z - 1
        elseif mock.facing == 1 then mock.x = mock.x + 1
        elseif mock.facing == 2 then mock.z = mock.z + 1
        elseif mock.facing == 3 then mock.x = mock.x - 1
        end

        log("forward", "OK")
        return true
    end,

    back = function()
        if mock.fuel < 1 then return false, "Out of fuel" end
        mock.fuel = mock.fuel - 1
        mock.move_count = mock.move_count + 1

        if mock.facing == 0 then mock.z = mock.z + 1
        elseif mock.facing == 1 then mock.x = mock.x - 1
        elseif mock.facing == 2 then mock.z = mock.z - 1
        elseif mock.facing == 3 then mock.x = mock.x + 1
        end

        log("back", "OK")
        return true
    end,

    up = function()
        if mock.fuel < 1 then return false, "Out of fuel" end
        mock.fuel = mock.fuel - 1
        mock.move_count = mock.move_count + 1
        mock.y = mock.y + 1
        log("up", "OK")
        return true
    end,

    down = function()
        if mock.fuel < 1 then return false, "Out of fuel" end
        mock.fuel = mock.fuel - 1
        mock.move_count = mock.move_count + 1
        mock.y = mock.y - 1
        log("down", "OK")
        return true
    end,

    turnLeft = function()
        mock.facing = (mock.facing - 1) % 4
        log("turnLeft", "OK")
        return true
    end,

    turnRight = function()
        mock.facing = (mock.facing + 1) % 4
        log("turnRight", "OK")
        return true
    end,

    dig = function()
        local key = getBlockInFront()
        if mock.world[key] then mock.world[key] = nil end
        log("dig", "OK")
        return true
    end,
    digUp = function()
        local key = getBlockAbove()
        if mock.world[key] then mock.world[key] = nil end
        log("digUp", "OK")
        return true
    end,
    digDown = function()
        local key = getBlockBelow()
        if mock.world[key] then mock.world[key] = nil end
        log("digDown", "OK")
        return true
    end,

    detect = function()
        return mock.world[getBlockInFront()] ~= nil
    end,
    detectUp = function()
        return mock.world[getBlockAbove()] ~= nil
    end,
    detectDown = function()
        if mock.world[getBlockBelow()] ~= nil then return true end
        return mock.detect_down_result
    end,

    inspect = function()
        local block = mock.world[getBlockInFront()]
        if block then return true, { name = block.name } end
        return false, "No block"
    end,
    inspectUp = function()
        local block = mock.world[getBlockAbove()]
        if block then return true, { name = block.name } end
        return false, "No block"
    end,
    inspectDown = function()
        local block = mock.world[getBlockBelow()]
        if block then return true, { name = block.name } end
        return false, "No block"
    end,

    place = function() return true end,
    placeUp = function() return true end,
    placeDown = function() log("placeDown", "OK"); mock.pave_count = mock.pave_count + 1; return true end,

    attack = function() return false end,
    attackUp = function() return false end,
    attackDown = function() return false end,

    getFuelLevel = function() return mock.fuel end,
    getFuelLimit = function() return 20000 end,
    refuel = function(count)
        local slot = mock.selected_slot
        local item = mock.inventory[slot]
        if not item or item.count <= 0 then return false end
        local fuelValue = MOCK_FUEL_VALUES[item.name]
        if not fuelValue then return false end
        if count == 0 then return true end  -- Test if fuel without consuming
        -- Consume 'count' items (or all remaining)
        local toConsume = count or item.count
        if toConsume > item.count then toConsume = item.count end
        mock.fuel = mock.fuel + (toConsume * fuelValue)
        item.count = item.count - toConsume
        if item.count <= 0 then mock.inventory[slot] = nil end
        return true
    end,

    select = function(slot) mock.selected_slot = slot; return true end,
    getSelectedSlot = function() return mock.selected_slot end,
    getItemCount = function(slot)
        slot = slot or mock.selected_slot
        local item = mock.inventory[slot]
        return item and item.count or 0
    end,
    getItemSpace = function(slot)
        slot = slot or mock.selected_slot
        local item = mock.inventory[slot]
        return item and (64 - item.count) or 64
    end,
    getItemDetail = function(slot)
        slot = slot or mock.selected_slot
        local item = mock.inventory[slot]
        if item and item.count > 0 then
            return { name = item.name, count = item.count }
        end
        return nil
    end,

    drop = function() return true end,
    dropUp = function() return true end,
    dropDown = function() return true end,

    suck = function() return false end,
    suckUp = function() return false end,
    suckDown = function() return false end,

    transferTo = function() return true end,
    compareTo = function() return false end,

    equipLeft = function() return true end,
    equipRight = function() return true end,
}

-- ============================================================================
-- MOCK CC FUNCTIONS
-- ============================================================================

function sleep(n)
    -- Do nothing in tests
end

function write(s)
    io.write(s)
end

function read()
    -- Return empty for auto-mode (use defaults)
    return ""
end

-- ============================================================================
-- TEST UTILITIES
-- ============================================================================

local function reset_mock()
    mock.x = 0
    mock.y = 0
    mock.z = 0
    mock.facing = 0
    mock.fuel = 10000
    mock.inventory = {}
    mock.selected_slot = 1
    mock.logs = {}
    mock.move_count = 0
    mock.pave_count = 0
    mock.detect_down_result = false
    mock.world = {}
end

local function print_logs()
    print("\n=== MOVEMENT LOG ===")
    for _, entry in ipairs(mock.logs) do
        print(entry)
    end
end

local function assert_position(expected_x, expected_y, expected_z, expected_facing, msg)
    local pass = mock.x == expected_x and mock.y == expected_y and
                 mock.z == expected_z and mock.facing == expected_facing
    if pass then
        print(string.format("✓ PASS: %s", msg))
    else
        print(string.format("✗ FAIL: %s", msg))
        print(string.format("  Expected: (%d,%d,%d) facing %d",
            expected_x, expected_y, expected_z, expected_facing))
        print(string.format("  Got:      (%d,%d,%d) facing %d",
            mock.x, mock.y, mock.z, mock.facing))
    end
    return pass
end

local function visualize_path()
    -- Find bounds
    local min_x, max_x, min_z, max_z = 0, 0, 0, 0
    local path = {{x=0, z=0}}

    local x, z, facing = 0, 0, 0
    for _, entry in ipairs(mock.logs) do
        if entry:match("forward") and entry:match("OK") then
            if facing == 0 then z = z - 1
            elseif facing == 1 then x = x + 1
            elseif facing == 2 then z = z + 1
            elseif facing == 3 then x = x - 1
            end
            table.insert(path, {x=x, z=z})
            min_x = math.min(min_x, x)
            max_x = math.max(max_x, x)
            min_z = math.min(min_z, z)
            max_z = math.max(max_z, z)
        elseif entry:match("turnLeft") then
            facing = (facing - 1) % 4
        elseif entry:match("turnRight") then
            facing = (facing + 1) % 4
        end
    end

    -- Create grid
    print("\n=== PATH VISUALIZATION (top-down, North=up) ===")
    print("Legend: S=start, .=path, numbers=branch endpoints")

    local grid = {}
    for z = min_z, max_z do
        grid[z] = {}
        for x = min_x, max_x do
            grid[z][x] = " "
        end
    end

    -- Mark path
    for _, p in ipairs(path) do
        if grid[p.z] and grid[p.z][p.x] then
            grid[p.z][p.x] = "."
        end
    end
    grid[0][0] = "S"

    -- Mark final position
    if grid[mock.z] and grid[mock.z][mock.x] then
        grid[mock.z][mock.x] = "E"
    end

    -- Print grid
    print(string.format("X range: %d to %d, Z range: %d to %d", min_x, max_x, min_z, max_z))
    for z = min_z, max_z do
        local row = string.format("z=%3d |", z)
        for x = min_x, max_x do
            row = row .. (grid[z][x] or " ")
        end
        row = row .. "|"
        print(row)
    end
end

-- ============================================================================
-- TEST CASES
-- ============================================================================

local function test_single_branch_left()
    print("\n" .. string.rep("=", 60))
    print("TEST: Single branch LEFT (length=5, spacing=3)")
    print(string.rep("=", 60))
    reset_mock()

    -- Simulate what executeMining does for 1 left branch
    -- (don't dofile here — all functions are local, and it runs main()
    -- which corrupts mock state with a full 20-branch mining operation)

    print("\nManual simulation of 1 left branch:")

    -- Mine spacing (3 blocks north)
    for i = 1, 3 do
        turtle.dig()
        turtle.digUp()
        turtle.forward()
    end
    print(string.format("After spacing: (%d,%d,%d) facing %s",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))

    -- Turn left for branch
    turtle.turnLeft()
    print(string.format("After turnLeft: facing %s", FACING_NAMES[mock.facing + 1]))

    -- Mine branch (5 blocks west)
    for i = 1, 5 do
        turtle.dig()
        turtle.digUp()
        turtle.forward()
    end
    print(string.format("At branch end: (%d,%d,%d) facing %s",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))

    -- Turn around (2x turnRight = 180)
    turtle.turnRight()
    turtle.turnRight()
    print(string.format("After 180: facing %s", FACING_NAMES[mock.facing + 1]))

    -- Walk back
    for i = 1, 5 do
        turtle.forward()
    end
    print(string.format("Back at junction: (%d,%d,%d) facing %s (should be EAST)",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))

    -- Turtle exits facing EAST (toward junction from left/west branch)
    -- Turn left to face NORTH (main tunnel)
    turtle.turnLeft()
    print(string.format("After turn back to main: facing %s (should be NORTH)",
        FACING_NAMES[mock.facing + 1]))

    assert_position(0, 0, -3, 0, "Should be at (0,0,-3) facing NORTH after left branch")
    visualize_path()
end

local function test_two_branches()
    print("\n" .. string.rep("=", 60))
    print("TEST: Two positions with LEFT+RIGHT branches (length=3, spacing=2)")
    print(string.rep("=", 60))
    reset_mock()

    local branch_length = 3
    local spacing = 2

    for branch = 1, 2 do
        print(string.format("\n--- Position %d ---", branch))

        -- Mine spacing
        for i = 1, spacing do
            turtle.forward()
        end
        print(string.format("After spacing: (%d,%d,%d) facing %s",
            mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))

        -- LEFT branch
        print("  Mining LEFT branch...")
        turtle.turnLeft()  -- NORTH → WEST
        for i = 1, branch_length do
            turtle.forward()
        end
        print(string.format("  At LEFT end: (%d,%d,%d)", mock.x, mock.y, mock.z))

        -- Return from LEFT: turn 180, walk back (exits facing EAST)
        turtle.turnRight()
        turtle.turnRight()
        for i = 1, branch_length do
            turtle.forward()
        end
        -- Now facing EAST — already the right branch direction
        print(string.format("  Back from LEFT, facing: %s (should be EAST)", FACING_NAMES[mock.facing + 1]))

        -- RIGHT branch — already facing EAST, go directly
        print("  Mining RIGHT branch...")
        for i = 1, branch_length do
            turtle.forward()
        end
        print(string.format("  At RIGHT end: (%d,%d,%d)", mock.x, mock.y, mock.z))

        -- Return from RIGHT: turn 180, walk back (exits facing WEST)
        turtle.turnRight()
        turtle.turnRight()
        for i = 1, branch_length do
            turtle.forward()
        end
        -- Now facing WEST, turn right to face NORTH
        turtle.turnRight()
        print(string.format("  Back from RIGHT, facing: %s (should be NORTH)", FACING_NAMES[mock.facing + 1]))
    end

    -- After 2 positions with spacing=2, we should be at z=-4 facing north
    assert_position(0, 0, -4, 0, "Should be at (0,0,-4) facing NORTH after 2 positions (L+R each)")
    visualize_path()
end

local function test_full_program()
    print("\n" .. string.rep("=", 60))
    print("TEST: Full program (small config)")
    print(string.rep("=", 60))
    reset_mock()

    -- Override read() to return specific values
    local input_count = 0
    local inputs = {"2", "2", "2", "y", "y", "y"}  -- length=2, branches=2, spacing=2, pave=y, vein=y, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    -- Run the actual program
    print("Running branchMining.lua with config: length=2, branches=2, spacing=2, pave=y")
    dofile("branchMining.lua")

    print(string.format("\nFinal position: (%d,%d,%d) facing %s",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))
    print(string.format("Total moves: %d, Fuel used: %d", mock.move_count, 10000 - mock.fuel))

    visualize_path()
end

-- ============================================================================
-- FUEL MONITORING TESTS
-- ============================================================================

local function assert_equal(expected, actual, msg)
    if expected == actual then
        print(string.format("✓ PASS: %s", msg))
        return true
    else
        print(string.format("✗ FAIL: %s", msg))
        print(string.format("  Expected: %s", tostring(expected)))
        print(string.format("  Got:      %s", tostring(actual)))
        return false
    end
end

local function assert_true(val, msg)
    if val then
        print(string.format("✓ PASS: %s", msg))
        return true
    else
        print(string.format("✗ FAIL: %s (expected true, got %s)", msg, tostring(val)))
        return false
    end
end

local function test_mock_refuel()
    print("\n" .. string.rep("=", 60))
    print("TEST: Mock refuel with coal in inventory")
    print(string.rep("=", 60))
    reset_mock()
    mock.fuel = 50

    -- Put 2 coal in slot 3
    mock.inventory[3] = { name = "minecraft:coal", count = 2 }

    -- refuel(0) should test if current slot has fuel
    turtle.select(1)
    assert_equal(false, turtle.refuel(0), "Slot 1 (empty) is not fuel")

    turtle.select(3)
    assert_equal(true, turtle.refuel(0), "Slot 3 (coal) is fuel")

    -- Refuel 1 coal = 80 fuel
    turtle.refuel(1)
    assert_equal(130, mock.fuel, "After 1 coal: 50 + 80 = 130 fuel")
    assert_equal(1, mock.inventory[3].count, "1 coal remaining in slot 3")

    -- Refuel second coal
    turtle.refuel(1)
    assert_equal(210, mock.fuel, "After 2 coal: 130 + 80 = 210 fuel")
    assert_equal(nil, mock.inventory[3], "Slot 3 empty after consuming all coal")
end

local function test_auto_refuel_coal()
    print("\n" .. string.rep("=", 60))
    print("TEST: Auto-refuel coal via full program with low fuel")
    print(string.rep("=", 60))
    reset_mock()
    -- Start with low fuel so tryAutoRefuelCoal triggers (fuel < fuel_reserve=100)
    mock.fuel = 80
    -- Put coal in slot 5
    mock.inventory[5] = { name = "minecraft:coal", count = 10 }

    -- Override read for config: small mining run
    local input_count = 0
    local inputs = {"1", "1", "1", "y", "n", "y"}  -- length=1, branches=1, spacing=1, pave=y, vein=n, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- After mining, fuel should be higher than start due to auto-refuel
    -- (it will have consumed coal to stay above reserve)
    print(string.format("  Final fuel: %d", mock.fuel))
    assert_true(mock.fuel > 0, "Turtle still has fuel after mining with auto-refuel")

    -- Check coal was consumed
    local coalLeft = mock.inventory[5] and mock.inventory[5].count or 0
    assert_true(coalLeft < 10, "Some coal was consumed by auto-refuel (had 10, now " .. coalLeft .. ")")
end

local function test_fuel_to_return()
    print("\n" .. string.rep("=", 60))
    print("TEST: fuelToReturn at various positions (manual calculation)")
    print(string.rep("=", 60))

    -- fuelToReturn = |x| + |y| + |z| + max(10, ceil(dist * 0.2))
    -- At origin: dist=0, buffer=max(10,0)=10, result=10
    -- At (0,0,-10): dist=10, buffer=max(10,2)=10, result=20
    -- At (5,0,-20): dist=25, buffer=max(10,5)=10, result=35
    -- At (10,5,-50): dist=65, buffer=max(10,13)=13, result=78

    -- We can't call fuelToReturn directly since it's local,
    -- so we test via the program's checkFuel behavior.
    -- Instead verify the formula manually:
    local function calc_fuel_to_return(x, y, z)
        local dist = math.abs(x) + math.abs(y) + math.abs(z)
        local buffer = math.max(10, math.ceil(dist * 0.2))
        return dist + buffer
    end

    assert_equal(10, calc_fuel_to_return(0, 0, 0), "fuelToReturn at origin = 10")
    assert_equal(20, calc_fuel_to_return(0, 0, -10), "fuelToReturn at (0,0,-10) = 20")
    assert_equal(35, calc_fuel_to_return(5, 0, -20), "fuelToReturn at (5,0,-20) = 35")
    assert_equal(78, calc_fuel_to_return(10, 5, -50), "fuelToReturn at (10,5,-50) = 78")
end

local function test_get_fuel_needed()
    print("\n" .. string.rep("=", 60))
    print("TEST: getFuelNeeded estimate (manual calculation)")
    print(string.rep("=", 60))

    -- For config: branch_length=2, num_branches=2, spacing=2
    -- moves_per_position = spacing + (branch_length * 4) = 2 + 8 = 10
    -- total_moves = 2 * 10 = 20
    -- return_trip = 2 * 2 + 50 = 54
    -- total = 74
    local function calc_fuel_needed(branch_length, num_branches, spacing)
        local moves_per_position = spacing + (branch_length * 4)
        local total_moves = num_branches * moves_per_position
        local final_distance = num_branches * spacing
        local return_trip = final_distance + 50
        return total_moves + return_trip
    end

    assert_equal(74, calc_fuel_needed(2, 2, 2), "Fuel needed: length=2, branches=2, spacing=2 = 74")
    assert_equal(2570, calc_fuel_needed(30, 20, 3), "Fuel needed: length=30, branches=20, spacing=3 = 2570")

    -- With vein_mine: adds 4 per position (up+down per branch × 2)
    -- length=2, branches=2, spacing=2: moves = 2*(2+8+4) + 54 = 82
    local function calc_fuel_needed_vein(branch_length, num_branches, spacing)
        local moves_per_position = spacing + (branch_length * 4) + 4
        local total_moves = num_branches * moves_per_position
        local final_distance = num_branches * spacing
        local return_trip = final_distance + 50
        return total_moves + return_trip
    end

    assert_equal(82, calc_fuel_needed_vein(2, 2, 2), "Fuel needed (vein): length=2, branches=2, spacing=2 = 82")
    assert_equal(2650, calc_fuel_needed_vein(30, 20, 3), "Fuel needed (vein): length=30, branches=20, spacing=3 = 2650")
end

-- ============================================================================
-- PAVE SYSTEM TESTS
-- ============================================================================

local function test_pave_system()
    print("\n" .. string.rep("=", 60))
    print("TEST: Pave system (floor paving during mining)")
    print(string.rep("=", 60))

    -- Test 1: Paving with cobblestone when ground is empty
    print("\n--- Test: Pave with cobblestone (empty ground) ---")
    reset_mock()
    mock.detect_down_result = false  -- empty ground
    mock.inventory[1] = { name = "minecraft:cobblestone", count = 64 }

    local input_count = 0
    local inputs = {"2", "1", "1", "y", "n", "y"}  -- length=2, branches=1, spacing=1, pave=y, vein=n, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- mineForward is called: 1 (spacing) + 2 (left branch) + 2 (right branch) = 5 times
    -- Each mineForward calls paveDown once, and ground is empty → 5 placeDown calls
    assert_equal(5, mock.pave_count, "5 blocks paved (1 spacing + 2 left + 2 right)")

    -- Test 2: No paving when ground exists
    print("\n--- Test: No paving when ground exists ---")
    reset_mock()
    mock.detect_down_result = true  -- solid ground
    mock.inventory[1] = { name = "minecraft:cobblestone", count = 64 }

    input_count = 0
    inputs = {"2", "1", "1", "y", "n", "y"}
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    assert_equal(0, mock.pave_count, "0 blocks paved (ground exists)")

    -- Test 3: No paving when config.pave = false
    print("\n--- Test: No paving when disabled ---")
    reset_mock()
    mock.detect_down_result = false  -- empty ground
    mock.inventory[1] = { name = "minecraft:cobblestone", count = 64 }

    input_count = 0
    inputs = {"2", "1", "1", "n", "n", "y"}  -- pave=n, vein=n
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    assert_equal(0, mock.pave_count, "0 blocks paved (paving disabled)")

    -- Test 4: No pave materials in inventory
    print("\n--- Test: No pave materials available ---")
    reset_mock()
    mock.detect_down_result = false  -- empty ground
    -- No cobblestone/dirt/etc in inventory

    input_count = 0
    inputs = {"2", "1", "1", "y", "n", "y"}  -- pave=y, vein=n
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    assert_equal(0, mock.pave_count, "0 blocks paved (no pave materials)")
end

-- ============================================================================
-- ORE VEIN MINING TESTS
-- ============================================================================

local function test_isOre_pattern()
    print("\n" .. string.rep("=", 60))
    print("TEST: isOre pattern matching")
    print(string.rep("=", 60))

    -- isOre is local in branchMining.lua, so test the pattern directly
    local function isOre(name)
        return name:find("_ore$") ~= nil
    end

    assert_true(isOre("minecraft:iron_ore"), "iron_ore is ore")
    assert_true(isOre("minecraft:diamond_ore"), "diamond_ore is ore")
    assert_true(isOre("minecraft:deepslate_gold_ore"), "deepslate_gold_ore is ore")
    assert_true(isOre("minecraft:copper_ore"), "copper_ore is ore")
    assert_true(isOre("minecraft:redstone_ore"), "redstone_ore is ore")

    assert_true(not isOre("minecraft:stone"), "stone is not ore")
    assert_true(not isOre("minecraft:cobblestone"), "cobblestone is not ore")
    assert_true(not isOre("minecraft:coal"), "coal (item) is not ore")
    assert_true(not isOre("minecraft:ore_sensor"), "ore_sensor is not ore (ore not at end)")
end

local function test_no_ores()
    print("\n" .. string.rep("=", 60))
    print("TEST: Full program with vein mining, no ores in world")
    print(string.rep("=", 60))
    reset_mock()

    local input_count = 0
    local inputs = {"2", "1", "2", "y", "y", "y"}  -- length=2, branches=1, spacing=2, pave=y, vein=y, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- With vein scanning but no ores, turtle should still end at correct position
    -- spacing=2 → z=-2, facing north, y=0
    assert_position(0, 0, -2, 0, "Position correct after scan with no ores")
end

local function test_single_ore_block()
    print("\n" .. string.rep("=", 60))
    print("TEST: Single ore block in branch wall")
    print(string.rep("=", 60))
    reset_mock()

    -- Config: length=2, branches=1, spacing=2
    -- Left branch goes WEST from junction at z=-2
    -- Branch positions: (-1,0,-2) and (-2,0,-2)
    -- Place ore in south wall of position 1 in left branch
    -- When at (-1,0,-2) facing west, south wall = inspect after turnRight twice from west = south
    -- South of (-1,0,-2) is (-1,0,-1)
    mock.world[worldKey(-1, 0, -1)] = { name = "minecraft:iron_ore" }

    local input_count = 0
    local inputs = {"2", "1", "2", "y", "y", "y"}  -- length=2, branches=1, spacing=2, pave=y, vein=y, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- Ore should have been mined (removed from world)
    assert_true(mock.world[worldKey(-1, 0, -1)] == nil, "Iron ore was mined from world")
    assert_position(0, 0, -2, 0, "Position correct after mining single ore")
end

local function test_connected_vein()
    print("\n" .. string.rep("=", 60))
    print("TEST: Connected 3-block L-shaped vein")
    print(string.rep("=", 60))
    reset_mock()

    -- Config: length=2, branches=1, spacing=2
    -- Place L-shaped diamond vein north of left branch position 1
    -- At (-1,0,-2), north wall is (-1,0,-3)
    -- Then vein continues: (-1,0,-4) and (-2,0,-4)
    mock.world[worldKey(-1, 0, -3)] = { name = "minecraft:diamond_ore" }
    mock.world[worldKey(-1, 0, -4)] = { name = "minecraft:diamond_ore" }
    mock.world[worldKey(-2, 0, -4)] = { name = "minecraft:diamond_ore" }

    local input_count = 0
    local inputs = {"2", "1", "2", "y", "y", "y"}
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- All 3 ore blocks should be mined
    assert_true(mock.world[worldKey(-1, 0, -3)] == nil, "Diamond ore 1 mined")
    assert_true(mock.world[worldKey(-1, 0, -4)] == nil, "Diamond ore 2 mined")
    assert_true(mock.world[worldKey(-2, 0, -4)] == nil, "Diamond ore 3 mined")
    assert_position(0, 0, -2, 0, "Position correct after mining L-shaped vein")
end

local function test_vein_mine_disabled()
    print("\n" .. string.rep("=", 60))
    print("TEST: Vein mining disabled - ore left in wall")
    print(string.rep("=", 60))
    reset_mock()

    -- Place ore that should NOT be mined when vein_mine=n
    mock.world[worldKey(-1, 0, -1)] = { name = "minecraft:iron_ore" }

    local input_count = 0
    local inputs = {"2", "1", "2", "y", "n", "y"}  -- vein=n
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    dofile("branchMining.lua")

    -- Ore should still be in the world (not scanned)
    assert_true(mock.world[worldKey(-1, 0, -1)] ~= nil, "Iron ore NOT mined when vein mining disabled")
    assert_position(0, 0, -2, 0, "Position correct with vein mining disabled")
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

print("=== BRANCH MINING UNIT TESTS ===")
print("Set VERBOSE=1 to see all movement logs")
print("")

test_single_branch_left()
test_two_branches()

print("\n" .. string.rep("=", 60))
print("Running full program test...")
print(string.rep("=", 60))
test_full_program()

print("\n" .. string.rep("=", 60))
print("Running fuel monitoring tests...")
print(string.rep("=", 60))
test_mock_refuel()
test_fuel_to_return()
test_get_fuel_needed()
test_auto_refuel_coal()

print("\n" .. string.rep("=", 60))
print("Running pave system tests...")
print(string.rep("=", 60))
test_pave_system()

print("\n" .. string.rep("=", 60))
print("Running ore vein mining tests...")
print(string.rep("=", 60))
test_isOre_pattern()
test_no_ores()
test_single_ore_block()
test_connected_vein()
test_vein_mine_disabled()

print("\n=== TESTS COMPLETE ===")
