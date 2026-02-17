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
    spacing = 3,
    fuel_reserve = 100,  -- Minimum fuel to keep for emergencies
    auto_refuel_coal = true  -- Auto-consume coal/charcoal for fuel
}

local stats = {
    blocks_mined = 0,
    branches_completed = 0,
    fuel_used = 0
}

local FUEL_ITEMS = {
    ["minecraft:coal"] = true,
    ["minecraft:charcoal"] = true,
    ["minecraft:coal_block"] = true,
}

-- ============================================================================
-- FUEL MANAGEMENT (CRITICAL!)
-- ============================================================================

local function fuelToReturn()
    -- Manhattan distance from current position to origin + 20% buffer (minimum 10)
    local dist = math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z)
    local buffer = math.max(10, math.ceil(dist * 0.2))
    return dist + buffer
end

local function getFuelNeeded()
    -- Estimate fuel needed for the entire operation
    -- Each position: spacing + (branch_length * 2) for LEFT + (branch_length * 2) for RIGHT
    -- Total: num_branches * moves_per_position + return trip
    local moves_per_position = config.spacing + (config.branch_length * 4)  -- 2 branches, each goes out and back
    local total_moves = config.num_branches * moves_per_position
    -- Return trip: turtle will be at z = -(num_branches * spacing) at the end
    local final_distance = config.num_branches * config.spacing
    local return_trip = final_distance + 50  -- Extra buffer
    return total_moves + return_trip
end

local function refuel(needed)
    local level = turtle.getFuelLevel()

    -- Check if fuel is unlimited (creative mode or config)
    if level == "unlimited" then
        return true
    end

    -- Already have enough fuel
    if level >= needed then
        return true
    end

    -- Try to refuel from inventory
    local originalSlot = turtle.getSelectedSlot()

    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            -- Test if this item is fuel (refuel(0) doesn't consume)
            if turtle.refuel(0) then
                -- Consume fuel until we have enough
                while turtle.getFuelLevel() < needed and turtle.getItemCount(slot) > 0 do
                    turtle.refuel(1)
                end
                if turtle.getFuelLevel() >= needed then
                    turtle.select(originalSlot)
                    return true
                end
            end
        end
    end

    turtle.select(originalSlot)
    return turtle.getFuelLevel() >= needed
end

local function tryAutoRefuelCoal()
    if not config.auto_refuel_coal then return end

    local level = turtle.getFuelLevel()
    if level == "unlimited" then return end
    if level >= config.fuel_reserve then return end

    local originalSlot = turtle.getSelectedSlot()
    local refueled = false

    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and FUEL_ITEMS[detail.name] then
            turtle.select(slot)
            while turtle.getFuelLevel() < config.fuel_reserve and turtle.getItemCount(slot) > 0 do
                turtle.refuel(1)
            end
            refueled = true
            if turtle.getFuelLevel() >= config.fuel_reserve then
                break
            end
        end
    end

    if refueled then
        print(string.format("  [Fuel] Auto-refueled to %d", turtle.getFuelLevel()))
    end

    turtle.select(originalSlot)
end

local function checkFuel()
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        return true
    end

    -- Need at least 1 fuel to move
    if level < 1 then
        if not refuel(config.fuel_reserve) then
            print("WARNING: Out of fuel!")
            print("Current fuel: " .. level)
            print("Please add fuel items to inventory")
            return false
        end
    end

    -- Return-trip awareness: warn if fuel is getting low relative to distance home
    local returnCost = fuelToReturn()
    if level <= returnCost then
        print(string.format("  [Fuel] WARNING: Fuel (%d) <= return cost (%d)!", level, returnCost))
        -- Try to refuel enough for return + reserve
        local target = returnCost + config.fuel_reserve
        if not refuel(target) then
            print(string.format("  [Fuel] CRITICAL: Cannot refuel to %d! Current: %d", target, turtle.getFuelLevel()))
        end
    end

    return true
end

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
    -- Check fuel before attempting to move
    if not checkFuel() then
        return false, "Out of fuel"
    end

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
        stats.fuel_used = stats.fuel_used + 1
        return true
    end
    return false, "Movement blocked"
end

local function back()
    -- Check fuel before attempting to move
    if not checkFuel() then
        return false, "Out of fuel"
    end

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
        stats.fuel_used = stats.fuel_used + 1
        return true
    end
    return false, "Movement blocked"
end

local function up()
    -- Check fuel before attempting to move
    if not checkFuel() then
        return false, "Out of fuel"
    end

    if turtle.up() then
        updatePosition(0, 1, 0)
        stats.fuel_used = stats.fuel_used + 1
        return true
    end
    return false, "Movement blocked"
end

local function down()
    -- Check fuel before attempting to move
    if not checkFuel() then
        return false, "Out of fuel"
    end

    if turtle.down() then
        updatePosition(0, -1, 0)
        stats.fuel_used = stats.fuel_used + 1
        return true
    end
    return false, "Movement blocked"
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

    -- Try to move forward, handle obstacles
    local attempts = 0
    while not forward() do
        attempts = attempts + 1
        if attempts > 10 then
            print("ERROR: Cannot move forward after 10 attempts")
            return false
        end

        -- Check if blocked by a block
        if turtle.detect() then
            if not turtle.dig() then
                print("ERROR: Cannot dig block (bedrock?)")
                return false
            end
        -- Check if blocked by entity
        elseif turtle.attack() then
            -- Attacked something, try again
        else
            -- Unknown blockage, wait and retry
            sleep(0.5)
        end
    end
    return true
end

local function mineBranch(length)
    -- Mine a 2-high branch tunnel
    local actualLength = length
    for i = 1, length do
        if not mineForward() then
            print("  Branch mining stopped at block " .. i)
            -- Still need to return, so update actual length
            actualLength = i - 1
            break
        end
    end

    -- Clear ceiling at branch endpoint (mineForward only digs up BEFORE moving)
    digUp()

    -- Turn around to face back toward main tunnel (180°)
    turnRight()
    turnRight()

    -- Return to main tunnel
    for i = 1, actualLength do
        if not forward() then
            -- Try to dig through if blocked
            digForward()
            if not forward() then
                print("ERROR: Cannot return from branch!")
                return false
            end
        end
    end

    -- Turtle now exits facing TOWARD the junction (opposite of branch direction)
    -- The caller handles turning to the next direction
    return true
end

-- ============================================================================
-- FUEL STATUS REPORTING
-- ============================================================================

local function printFuelStatus(branch_num)
    local level = turtle.getFuelLevel()
    if level == "unlimited" then return end

    local returnCost = fuelToReturn()
    local remaining_branches = config.num_branches - branch_num
    local moves_per_branch = config.spacing + (config.branch_length * 4)
    local fuel_to_finish = remaining_branches * moves_per_branch
    local efficiency = "N/A"
    if stats.fuel_used > 0 then
        efficiency = string.format("%.1f", stats.blocks_mined / stats.fuel_used)
    end

    print(string.format("  [Fuel] Level: %d | Return cost: %d | To finish: ~%d | Blocks/fuel: %s",
        level, returnCost, fuel_to_finish, efficiency))
end

-- ============================================================================
-- MAIN MINING PATTERN
-- ============================================================================

local function executeMining()
    -- Check initial fuel
    local fuelLevel = turtle.getFuelLevel()
    local fuelNeeded = getFuelNeeded()

    print("=== Fuel Check ===")
    if fuelLevel == "unlimited" then
        print("Fuel: unlimited (creative mode)")
    else
        print(string.format("Current fuel: %d", fuelLevel))
        print(string.format("Estimated needed: %d", fuelNeeded))

        if fuelLevel < fuelNeeded then
            print("")
            print("WARNING: Low fuel! Attempting to refuel...")
            if not refuel(fuelNeeded) then
                print("Could not get enough fuel.")
                print("Continuing anyway, will try to refuel during operation.")
            else
                print(string.format("Refueled! New level: %d", turtle.getFuelLevel()))
            end
        end
    end
    print("")

    print("Starting branch mining operation...")
    print(string.format("Position: x=%d, y=%d, z=%d, facing=%d", pos.x, pos.y, pos.z, pos.facing))
    print("")

    for branch = 1, config.num_branches do
        -- Mine forward in main tunnel by spacing amount
        print(string.format("[Branch %d/%d] Mining main tunnel (%d blocks)...",
            branch, config.num_branches, config.spacing))
        for step = 1, config.spacing do
            if not mineForward() then
                print("ERROR: Mining stopped in main tunnel")
                return false
            end
        end

        -- Mine LEFT branch
        print(string.format("[Branch %d/%d] Mining LEFT branch (%d blocks)...",
            branch, config.num_branches, config.branch_length))
        turnLeft()  -- NORTH → WEST
        if not mineBranch(config.branch_length) then
            print("ERROR: Left branch mining failed")
            return false
        end
        -- After mineBranch, facing EAST (walked back from WEST branch)
        -- EAST is already the right branch direction — go directly
        tryAutoRefuelCoal()

        -- Mine RIGHT branch
        print(string.format("[Branch %d/%d] Mining RIGHT branch (%d blocks)...",
            branch, config.num_branches, config.branch_length))
        if not mineBranch(config.branch_length) then
            print("ERROR: Right branch mining failed")
            return false
        end
        -- After mineBranch, facing WEST (walked back from EAST branch)
        -- Turn right to face NORTH
        tryAutoRefuelCoal()
        turnRight()  -- WEST → NORTH

        -- Update stats and display progress
        stats.branches_completed = stats.branches_completed + 1
        local currentFuel = turtle.getFuelLevel()
        local fuelStr = (currentFuel == "unlimited") and "unlimited" or tostring(currentFuel)
        print(string.format("[Branch %d/%d] DONE (L+R) | Mined: %d | Fuel: %s | Pos: %d,%d,%d",
            branch, config.num_branches, stats.blocks_mined,
            fuelStr, pos.x, pos.y, pos.z))
        printFuelStatus(branch)
        print("")
    end

    print("")
    print("=== Mining Complete! ===")
    print(string.format("Total branches: %d", stats.branches_completed))
    print(string.format("Total blocks mined: %d", stats.blocks_mined))
    print(string.format("Fuel used: %d", stats.fuel_used))
    local endFuel = turtle.getFuelLevel()
    if endFuel ~= "unlimited" then
        print(string.format("Ending fuel: %d", endFuel))
        if stats.fuel_used > 0 then
            print(string.format("Mining efficiency: %.1f blocks/fuel", stats.blocks_mined / stats.fuel_used))
        end
    end
    print(string.format("Final position: x=%d, y=%d, z=%d", pos.x, pos.y, pos.z))
    return true
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
