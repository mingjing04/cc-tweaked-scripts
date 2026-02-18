# CC:Tweaked Branch Mining

An automated branch mining program for [ComputerCraft: Tweaked](https://tweaked.cc/) turtles. Mines a grid of branch tunnels, auto-refuels from coal in inventory, paves gaps in the floor, and recursively mines ore veins found in tunnel walls.

## Quick Start

Run this on your turtle's terminal:

```lua
wget https://raw.githubusercontent.com/mingjing04/cc-tweaked-scripts/main/branchMining.lua branchMining.lua
branchMining
```

## Features

- **Branch mining pattern** -- Mines a 2-high main tunnel with evenly spaced left + right branches
- **Ore vein mining** -- Scans branch walls, floor, and ceiling for ore, then recursively mines connected veins in all 6 directions
- **Auto fuel management** -- Monitors fuel level, auto-consumes coal/charcoal from inventory, warns when fuel is low relative to return distance
- **Floor paving** -- Fills empty ground below the turtle with cobblestone, deepslate, dirt, or netherrack from inventory
- **Gravel/sand handling** -- Keeps digging until blocks stop falling
- **Position tracking** -- Tracks x/y/z coordinates and facing direction throughout the operation

## Configuration

The program prompts you before mining starts:

| Setting | Default | Description |
|---------|---------|-------------|
| Branch length | 30 | How far each side branch extends |
| Number of branches | 20 | How many branch pairs to mine |
| Spacing | 3 | Blocks between branches along the main tunnel |
| Floor paving | yes | Fill empty ground with cobblestone/dirt |
| Ore vein mining | yes | Scan branches for ore veins after mining |

## Setup Tips

- **Fuel**: Load coal or charcoal into the turtle's inventory before starting. The program estimates total fuel needed and warns you if it's short.
- **Paving material**: Bring cobblestone, cobbled deepslate, dirt, or netherrack for floor paving.
- **Starting position**: Place the turtle facing the direction you want the main tunnel to go. It mines forward from where it stands.
- **Fuel values**: Coal/Charcoal = 80, Coal Block = 800, Lava Bucket = 1000.

## How It Works

```
  LEFT        |        RIGHT
  ############|############    branch 3
              |
  ############|############    branch 2
              |
  ############|############    branch 1
              S

  # = mined tunnel (2 blocks tall)
  | = main tunnel
  S = start position, facing north (up)
```

1. Mines forward along the main tunnel by `spacing` blocks
2. Turns left, mines a branch, returns to the main tunnel
3. Continues east, mines a right branch, returns
4. If ore vein mining is on: scans each branch at two heights (y=0 and y=1), inspecting walls, floor, and ceiling for ore
5. When ore is found, recursively mines the entire connected vein in all 6 directions
6. Repeats for the configured number of branches

## Updating

To update to the latest version:

```lua
wget https://raw.githubusercontent.com/mingjing04/cc-tweaked-scripts/main/branchMining.lua branchMining.lua
```

Select `y` when prompted to overwrite the existing file.

## License

MIT
