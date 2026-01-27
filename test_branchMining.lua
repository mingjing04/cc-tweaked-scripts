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
    inventory = {},
    logs = {},
    move_count = 0,
}

-- Direction names for logging
local FACING_NAMES = {"NORTH(-z)", "EAST(+x)", "SOUTH(+z)", "WEST(-x)"}

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

    dig = function() log("dig", "OK"); return true end,
    digUp = function() log("digUp", "OK"); return true end,
    digDown = function() log("digDown", "OK"); return true end,

    detect = function() return false end,
    detectUp = function() return false end,
    detectDown = function() return false end,

    inspect = function() return false, "No block" end,
    inspectUp = function() return false, "No block" end,
    inspectDown = function() return false, "No block" end,

    place = function() return true end,
    placeUp = function() return true end,
    placeDown = function() return true end,

    attack = function() return false end,
    attackUp = function() return false end,
    attackDown = function() return false end,

    getFuelLevel = function() return mock.fuel end,
    getFuelLimit = function() return 20000 end,
    refuel = function(count)
        if count == 0 then return false end  -- No fuel items in mock
        return false
    end,

    select = function(slot) return true end,
    getSelectedSlot = function() return 1 end,
    getItemCount = function(slot) return 0 end,
    getItemSpace = function(slot) return 64 end,
    getItemDetail = function(slot) return nil end,

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
    mock.logs = {}
    mock.move_count = 0
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
    -- Load the module functions
    dofile("branchMining.lua")

    -- Can't easily call internal functions, so let's trace manually
    -- This test validates the mock works

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
    print(string.format("Back at junction: (%d,%d,%d) facing %s",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))

    -- Turn around again (2x turnRight = 180) - this is the 4 turnRight pattern
    turtle.turnRight()
    turtle.turnRight()
    print(string.format("After 4th turnRight: facing %s (should be WEST)",
        FACING_NAMES[mock.facing + 1]))

    -- Now turn right to face north (main tunnel)
    turtle.turnRight()
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
        turtle.turnLeft()
        for i = 1, branch_length do
            turtle.forward()
        end
        print(string.format("  At LEFT end: (%d,%d,%d)", mock.x, mock.y, mock.z))

        -- Return from LEFT: turn 180, walk back, turn 180
        turtle.turnRight()
        turtle.turnRight()
        for i = 1, branch_length do
            turtle.forward()
        end
        turtle.turnRight()
        turtle.turnRight()
        -- Now facing WEST (into left branch), turn right to face NORTH
        turtle.turnRight()
        print(string.format("  Back from LEFT, facing: %s", FACING_NAMES[mock.facing + 1]))

        -- RIGHT branch
        print("  Mining RIGHT branch...")
        turtle.turnRight()
        for i = 1, branch_length do
            turtle.forward()
        end
        print(string.format("  At RIGHT end: (%d,%d,%d)", mock.x, mock.y, mock.z))

        -- Return from RIGHT: turn 180, walk back, turn 180
        turtle.turnRight()
        turtle.turnRight()
        for i = 1, branch_length do
            turtle.forward()
        end
        turtle.turnRight()
        turtle.turnRight()
        -- Now facing EAST (into right branch), turn left to face NORTH
        turtle.turnLeft()
        print(string.format("  Back from RIGHT, facing: %s", FACING_NAMES[mock.facing + 1]))
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
    local inputs = {"2", "2", "2", "y"}  -- length=2, branches=2, spacing=2, confirm=y
    read = function()
        input_count = input_count + 1
        return inputs[input_count] or ""
    end

    -- Run the actual program
    print("Running branchMining.lua with config: length=2, branches=2, spacing=2")
    dofile("branchMining.lua")

    print(string.format("\nFinal position: (%d,%d,%d) facing %s",
        mock.x, mock.y, mock.z, FACING_NAMES[mock.facing + 1]))
    print(string.format("Total moves: %d, Fuel used: %d", mock.move_count, 10000 - mock.fuel))

    visualize_path()
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

print("\n=== TESTS COMPLETE ===")
