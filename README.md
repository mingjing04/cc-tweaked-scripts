# ComputerCraft: Tweaked Scripts

This repository contains Lua scripts for ComputerCraft: Tweaked in Minecraft.

## Scripts

- [branchMining.lua](branchMining.lua) - Branch mining automation

## CI/CD Deployment Methods

### Method 1: Direct File Sync (Recommended for Local Development)

Automatically sync your code to the Minecraft saves folder whenever you make changes.

#### Setup:

1. Find your Minecraft saves folder:
   - Windows: `%APPDATA%\.minecraft\saves\<world-name>\computercraft\computer\<computer-id>`
   - macOS: `~/Library/Application Support/minecraft/saves/<world-name>/computercraft/computer/<computer-id>`
   - Linux: `~/.minecraft/saves/<world-name>/computercraft/computer/<computer-id>`

2. Configure the sync script:
   ```bash
   cp sync-config.example.sh sync-config.local.sh
   # Edit sync-config.local.sh with your paths
   ```

3. Run the file watcher:
   ```bash
   ./watch-and-sync.sh
   ```

This will automatically copy files to Minecraft whenever you save changes!

### Method 2: Pastebin Upload (Best for Sharing)

Upload scripts to Pastebin and download them in-game.

#### Setup:

1. Get a Pastebin API key from https://pastebin.com/doc_api

2. Configure the upload script:
   ```bash
   export PASTEBIN_API_KEY="your_api_key_here"
   ```

3. Upload a script:
   ```bash
   ./upload-to-pastebin.sh branchMining.lua
   ```

4. In ComputerCraft, download with:
   ```lua
   pastebin get <paste-id> branchMining
   ```

### Method 3: GitHub + wget (Best for Version Control)

Use GitHub as your source and wget in-game to pull updates.

#### Setup:

1. Push your code to GitHub:
   ```bash
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/cc-tweaked-scripts.git
   git push -u origin main
   ```

2. In ComputerCraft, download with:
   ```lua
   wget https://raw.githubusercontent.com/yourusername/cc-tweaked-scripts/main/branchMining.lua branchMining.lua
   ```

3. Create an update script in-game:
   ```lua
   -- update.lua
   local scripts = {
     "branchMining.lua"
   }

   local baseUrl = "https://raw.githubusercontent.com/yourusername/cc-tweaked-scripts/main/"

   for _, script in ipairs(scripts) do
     print("Downloading " .. script .. "...")
     shell.run("wget", baseUrl .. script, script)
   end

   print("All scripts updated!")
   ```

## Development Workflow

1. **Edit** your Lua files in your favorite editor
2. **Test** in ComputerCraft (auto-synced with Method 1)
3. **Commit** to git when working
4. **Push** to GitHub for backup and sharing

## Useful ComputerCraft Commands

- `edit <filename>` - Edit a file in-game
- `rm <filename>` - Delete a file
- `ls` - List files
- `reboot` - Restart the computer (reloads scripts)
- `pastebin get <id> <name>` - Download from Pastebin
- `wget <url> <name>` - Download from URL

## Testing

Always test your scripts in a creative world first before deploying to survival!

## License

MIT
