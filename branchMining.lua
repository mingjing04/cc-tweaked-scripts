-- Branch Mining Program for ComputerCraft: Tweaked
-- Phase 1: Core Movement & Mining (MVP)

-- ============================================================================
-- GLOBAL STATE
-- ============================================================================

local pos = {x = 0, y = 0, z = 0, facing = 0}
-- facing: 0=north(-z), 1=east(+x), 2=south(+z), 3=west(-x)

local config = {
    branch_length = 30,
    num_branches = 20,
    spacing = 3
}

local stats = {
    blocks_mined = 0,
    branches_completed = 0
}

-- ============================================================================
-- POSITION TRACKING
-- ============================================================================

local function updatePosition(dx, dy, dz)
    pos.x = pos.x + dx
    pos.y = pos.y + dy
    pos.z = pos.z + dz
end

local function updateFacing(delta)
    pos.facing = (pos.facing + delta) % 4
end

-- ============================================================================
-- CORE MOVEMENT FUNCTIONS
-- ============================================================================

local function forward()
    if turtle.forward() then
        -- Update position based on facing direction
        if pos.facing == 0 then
            updatePosition(0, 0, -1)  -- North
        elseif pos.facing == 1 then
            updatePosition(1, 0, 0)   -- East
        elseif pos.facing == 2 then
            updatePosition(0, 0, 1)   -- South
        elseif pos.facing == 3 then
            updatePosition(-1, 0, 0)  -- West
        end
        return true
    end
    return false
end

local function back()
    if turtle.back() then
        -- Update position (opposite of forward)
        if pos.facing == 0 then
            updatePosition(0, 0, 1)   -- Moving back from north
        elseif pos.facing == 1 then
            updatePosition(-1, 0, 0)  -- Moving back from east
        elseif pos.facing == 2 then
            updatePosition(0, 0, -1)  -- Moving back from south
        elseif pos.facing == 3 then
            updatePosition(1, 0, 0)   -- Moving back from west
        end
        return true
    end
    return false
end

local function up()
    if turtle.up() then
        updatePosition(0, 1, 0)
        return true
    end
    return false
end

local function down()
    if turtle.down() then
        updatePosition(0, -1, 0)
        return true
    end
    return false
end

local function turnLeft()
    turtle.turnLeft()
    updateFacing(-1)
end

local function turnRight()
    turtle.turnRight()
    updateFacing(1)
end

-- ============================================================================
-- SAFE DIGGING FUNCTIONS
-- ============================================================================

local function digForward()
    local dug = false
    while turtle.detect() do
        if turtle.dig() then
            dug = true
            stats.blocks_mined = stats.blocks_mined + 1
        else
            return false  -- Can't dig (bedrock or protected block)
        end
        sleep(0.5)  -- Wait for falling blocks
    end
    return dug
end

local function digUp()
    local dug = false
    while turtle.detectUp() do
        if turtle.digUp() then
            dug = true
            stats.blocks_mined = stats.blocks_mined + 1
        else
            return false
        end
        sleep(0.5)
    end
    return dug
end

local function digDown()
    local dug = false
    while turtle.detectDown() do
        if turtle.digDown() then
            dug = true
            stats.blocks_mined = stats.blocks_mined + 1
        else
            return false
        end
        sleep(0.5)
    end
    return dug
end

-- ============================================================================
-- MINING FUNCTIONS
-- ============================================================================

local function mineForward()
    -- Dig 2-high tunnel (front and up)
    digForward()
    digUp()
    forward()
end

local function mineBranch(length)
    -- Mine a 2-high branch tunnel
    for i = 1, length do
        mineForward()
    end

    -- Return to main tunnel
    turnRight()
    turnRight()
    for i = 1, length do
        forward()
    end
    turnRight()
    turnRight()
end

-- ============================================================================
-- MAIN MINING PATTERN
-- ============================================================================

local function executeMining()
    print("Starting branch mining operation...")
    print(string.format("Position: x=%d, y=%d, z=%d, facing=%d", pos.x, pos.y, pos.z, pos.facing))
    print("")

    local side = 0  -- 0 for left, 1 for right

    for branch = 1, config.num_branches do
        -- Mine forward in main tunnel by spacing amount
        for step = 1, config.spacing do
            mineForward()
        end

        -- Turn to side branch direction (alternate left/right)
        if side == 0 then
            turnLeft()
        else
            turnRight()
        end

        -- Mine the branch
        mineBranch(config.branch_length)

        -- Update stats and display progress
        stats.branches_completed = stats.branches_completed + 1
        print(string.format("Branch %d/%d completed | Blocks mined: %d | Position: x=%d, y=%d, z=%d",
            stats.branches_completed, config.num_branches, stats.blocks_mined, pos.x, pos.y, pos.z))

        -- Alternate side for next branch
        side = 1 - side
    end

    print("")
    print("Mining operation complete!")
    print(string.format("Total branches: %d", stats.branches_completed))
    print(string.format("Total blocks mined: %d", stats.blocks_mined))
    print(string.format("Final position: x=%d, y=%d, z=%d", pos.x, pos.y, pos.z))
end

-- ============================================================================
-- USER INTERFACE
-- ============================================================================

local function getUserInput(prompt, default)
    write(prompt .. " (default: " .. tostring(default) .. "): ")
    local input = read()
    if input == "" or input == nil then
        return default
    end
    return tonumber(input) or default
end

local function getConfiguration()
    print("=== Branch Mining Configuration ===")
    print("")

    config.branch_length = getUserInput("Branch length", 30)
    config.num_branches = getUserInput("Number of branches", 20)
    config.spacing = getUserInput("Spacing between branches", 3)

    print("")
    print("Configuration:")
    print("  Branch length: " .. config.branch_length)
    print("  Number of branches: " .. config.num_branches)
    print("  Spacing: " .. config.spacing)
    print("")

    write("Start mining? (y/n): ")
    local confirm = read()
    return confirm == "y" or confirm == "Y" or confirm == ""
end

-- ============================================================================
-- MAIN PROGRAM
-- ============================================================================

local function main()
    print("=== ComputerCraft Branch Mining Program ===")
    print("Phase 1: MVP")
    print("")

    if getConfiguration() then
        executeMining()
    else
        print("Mining cancelled.")
    end
end

-- Run the program
main()
