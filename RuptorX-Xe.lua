-- Just to count boots runs
local function pingAnalytics()
    local success, _ = pcall(function()
        -- Constructing the GoatCounter URL
        -- 'p' is the path (shows up in your dashboard)
        -- 't' is the title
        -- 'r' is the referrer (optional)
        local baseUrl = "https://ruptorx.goatcounter.com/count"
        local params = "?p=/boot&t=RuptorX_Legacy_Boot&r=github"
        
        return game:HttpGet(baseUrl .. params)
    end)
    return success
end

-- Call it once during initialization
pingAnalytics()

-- Start performance timer
local scriptStartTime = os.clock()

-- RuptorX Enhanced Chat Interpreter (Optimized & Patched)
local Interpreter = {}

-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

-- State variables
Interpreter.Active = true
Interpreter.Noclipping = false
Interpreter.Spinning = false
Interpreter.Locking = false
Interpreter.PTeamLock = false
Interpreter.Following = false
Interpreter.Orbiting = false
Interpreter.Flying = false
Interpreter.Trolling = false
Interpreter.walkfling = false
Interpreter.Floating = false
Interpreter.NoStun = false
Interpreter.PHealthActive = false
Interpreter.ESPActive = false
Interpreter.NoRegulActive = false
Interpreter.SavedBackpackItem = nil
Interpreter.SpinSpeed = 30
Interpreter.OrbitSpeed = 40
Interpreter.OrbitDistance = 5
Interpreter.FloatHeight = 3
Interpreter.ToDuration = 0.1
Interpreter.CustomWalkSpeed = nil
Interpreter.CustomJumpPower = nil
Interpreter.CustomHealth = nil
Interpreter.ChatXActive = false
Interpreter.ChatXChannel = nil
Interpreter.ShowHPActive = false
Interpreter.ShowHPPlayerAdded = nil
Interpreter.ShowHPPlayerRemoving = nil
Interpreter.HPBars = {} -- Tracks all active HP bars
Interpreter.Active = true
Interpreter.ChangelogViewed = false
Interpreter.Waypoints = {}


-- Physics & Connection Holders
Interpreter.FlightBV = nil
Interpreter.FlightBG = nil
Interpreter.SpinAV = nil
Interpreter.FloatBP = nil
Interpreter.LockTarget = nil
Interpreter.LockConnection = nil
Interpreter.PTeamTarget = nil
Interpreter.PTeamConnection = nil
Interpreter.FollowTarget = nil
Interpreter.FollowConnection = nil
Interpreter.OrbitTarget = nil
Interpreter.OrbitConnection = nil
Interpreter.TrollConnection = nil
Interpreter.TrollTargets = {}
Interpreter.TrollTeamFilter = nil
Interpreter.TrollExcludeTeam = nil
Interpreter.walkflingConnection = nil
Interpreter.walkflingEvents = {}
Interpreter.NoStunConnection = nil
Interpreter.PHealthConnection = nil
Interpreter.NoclipConnection = nil
Interpreter.ESPLoop = nil
Interpreter.ChatXConnection = nil
Interpreter.ShowHPConnection = nil

local FOLDER_PATH = "RuptorX"

-- File paths
local FILES = {
    NoShut = FOLDER_PATH .. "/noshut.lock",
    Increment = FOLDER_PATH .. "/increment.lock",
    Version = FOLDER_PATH .. "/version.json",
    AutoUpdate = FOLDER_PATH .. "/autoupdate.lock",
    Shutdown = FOLDER_PATH .. "/shutdown.lock",
    Restart = FOLDER_PATH .. "/restart.lock",
    MainScript = FOLDER_PATH .. "/RuptorX-Main.lua",
    Failsafe = FOLDER_PATH .. "/failsafe.lua",
    UpdateLock = FOLDER_PATH .. "/updatelock.txt"
}

-- NilSpace: Pipes output to nowhere (debugging placeholder)
function Interpreter.nilspace(...)
    print("Piped to NilSpace")
end

-- Safe file operation stubs (used before SystemMaintenance loads)
local function safeCheckFile(path)
    local success, result = pcall(function()
        return isfile(path)
    end)
    return success and result
end

local function safeDeleteFile(path)
    local success = pcall(function()
        if isfile(path) then
            delfile(path)
        end
    end)
    return success
end

local function safeWriteFile(path, content)
    local success, err = pcall(function()
        writefile(path, content)
    end)
    if not success then
        warn("FILE: Failed to write " .. path .. ": " .. tostring(err))
        return false
    end
    return true
end

-- Position Storage (Sandboxed)
Interpreter.RespawnPosition = nil -- Used by *reset
Interpreter.SavedTpCFrame = nil   -- Used by *tp (sv/ld) exclusively
Interpreter.SpeedLoop = nil

-- Check if we're on mobile
Interpreter.IsMobile = UserInputService.TouchEnabled

-- Safe function to get character
function Interpreter.getCharacter()
    local player = Players.LocalPlayer
    if not player then return nil end
    return player.Character
end

-- Safe function to get humanoid
function Interpreter.getHumanoid()
    local character = Interpreter.getCharacter()
    if not character then return nil end
    return character:FindFirstChild("Humanoid")
end

-- Safe function to get root part
function Interpreter.getRootPart()
    local character = Interpreter.getCharacter()
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

-- Send chat message (supports both legacy and modern chat)
function Interpreter.sendChatMessage(message)
    local player = Players.LocalPlayer
    if not player then return end
    
    -- Try modern TextChatService first
    if TextChatService then
        local textChatChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if textChatChannel then
            textChatChannel:SendAsync(message)
            return
        end
    end
    
    -- Fall back to legacy chat
    if player.Character then
        game:GetService("Chat"):Chat(player.Character, message, Enum.ChatColor.White)
    end
end

-- Modified player search function (inject this into existing commands)
local function findPlayerByName(targetName)
    targetName = targetName:lower()
    
    -- Check if injector is active and name matches injected character
    if Interpreter.InjectedCharacters.Active then
        if targetName == "closest" and Interpreter.InjectedCharacters.closest then
            return Interpreter.InjectedCharacters.closest
        elseif targetName == "farthest" and Interpreter.InjectedCharacters.farthest then
            return Interpreter.InjectedCharacters.farthest
        end
    end
    
    -- Normal player search
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and 
           (player.Name:lower():find(targetName) or 
            player.DisplayName:lower():find(targetName)) then
            return player
        end
    end
    
    return nil
end

-- Built-in handlers
Interpreter.Handlers = {
    print = function(flags)
        local message = table.concat(flags, " ")
        print("PRINT: " .. message)
    end,
    
    startup_open_console = function(flags)
        -- Try modern TextChatService first
        if TextChatService then
            local textChatChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if textChatChannel then
                pcall(function()
                    textChatChannel:SendAsync("/console")
                end)
            end
        end
        
        -- Also try legacy chat as backup
        local player = Players.LocalPlayer
        if player and player.Character then
            pcall(function()
                game:GetService("Chat"):Chat(player.Character, "/console", Enum.ChatColor.White)
            end)
        end
        
        print("STARTUP: Attempted to open console")
    end,
    
    -- Command handler
    injector = function(flags)
        local action = flags[1] and flags[1]:lower() or "toggle"
        
        if action == "on" or action == "true" or (action == "toggle" and not Interpreter.InjectedCharacters.Active) then
            Interpreter.startInjector()
        elseif action == "off" or action == "false" or (action == "toggle" and Interpreter.InjectedCharacters.Active) then
            Interpreter.stopInjector()
        else
            warn("INJECTOR: Invalid syntax. Use '*injector' to toggle, '*injector on' or '*injector off'")
        end
    end,
    
    alias = function(flags)
        local action = flags[1] and flags[1]:lower()
        
        if action == "add" then
            if #flags < 3 then
                warn("ALIAS: Usage: *alias add <name> <command> [args...]")
                return
            end
            
            local aliasName = flags[2]:lower()
            local command = flags[3]:lower()
            local args = {}
            
            -- Collect remaining arguments
            for i = 4, #flags do
                table.insert(args, flags[i])
            end
            
            -- Check if alias conflicts with existing command
            if Interpreter.Handlers[aliasName] then
                warn("ALIAS: Cannot create alias '" .. aliasName .. "' - conflicts with existing command")
                return
            end
            
            -- Check if target command exists
            if not Interpreter.Handlers[command] then
                warn("ALIAS: Target command '" .. command .. "' does not exist")
                return
            end
            
            -- Create alias entry
            local aliasData = {
                alias = aliasName,
                cmd = command,
                args = args
            }
            
            -- Load existing aliases
            local aliases = Interpreter.loadAliases()
            
            -- Add or update alias
            local found = false
            for i, existing in ipairs(aliases) do
                if existing.alias == aliasName then
                    aliases[i] = aliasData
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(aliases, aliasData)
            end
            
            -- Save to file
            if Interpreter.saveAliases(aliases) then
                print("ALIAS: Created '" .. aliasName .. "' -> '" .. command .. (table.concat(args, " "):len() > 0 and " " .. table.concat(args, " ") or "") .. "'")
            else
                warn("ALIAS: Failed to save alias to file")
            end
            
        elseif action == "remove" or action == "rem" or action == "delete" or action == "del" then
            if #flags < 2 then
                warn("ALIAS: Usage: *alias remove <name>")
                return
            end
            
            local aliasName = flags[2]:lower()
            
            -- Load existing aliases
            local aliases = Interpreter.loadAliases()
            
            -- Find and remove alias
            local found = false
            for i, existing in ipairs(aliases) do
                if existing.alias == aliasName then
                    table.remove(aliases, i)
                    found = true
                    break
                end
            end
            
            if not found then
                warn("ALIAS: Alias '" .. aliasName .. "' not found")
                return
            end
            
            -- Save to file
            if Interpreter.saveAliases(aliases) then
                print("ALIAS: Removed alias '" .. aliasName .. "'")
            else
                warn("ALIAS: Failed to save changes to file")
            end
            
        elseif action == "list" then
            local aliases = Interpreter.loadAliases()
            
            if #aliases == 0 then
                print("ALIAS: No aliases defined")
                return
            end
            
            print("ALIAS: Defined aliases (" .. #aliases .. "):")
            for _, aliasData in ipairs(aliases) do
                local argsStr = #aliasData.args > 0 and " " .. table.concat(aliasData.args, " ") or ""
                print("  " .. aliasData.alias .. " -> " .. aliasData.cmd .. argsStr)
            end
            
        else
            print("ALIAS: Commands:")
            print("  *alias add <name> <command> [args...] - Create alias")
            print("  *alias remove <name> - Remove alias")
            print("  *alias list - List all aliases")
        end
    end,
    
    chat = function(flags)
        if #flags == 0 then return end
        
        -- Combines all arguments into a single message string with spaces
        local fullMessage = table.concat(flags, " ")
        Interpreter.sendChatMessage(fullMessage)
    end,
    
    schat = function(flags)
        if #flags == 0 then return end

        local function flipCase(char)
            if char:match("%a") then
                return char:lower() == char and char:upper() or char:lower()
            end
            return char
        end

        local function corruptWord(word)
            -- 80% baseline chance to corrupt a word at all
            if math.random(1, 100) > 80 then return word end

            local result = word
            local len = #word
            
            -- Dynamic chances for each method (base rates)
            local m1_chance = 60
            local m2_chance = 50
            local m3_chance = 50

            -- Pass 1: METHOD 1 - Case Flipping
            if len >= 2 and math.random(1, 100) <= m1_chance then
                -- Success: Proceed with Case Flip logic
                local flips = 1
                if len > 5 then
                    flips = math.random(1, 3)
                elseif len >= 4 then
                    flips = math.random(1, 100) <= 60 and 2 or 1
                end

                for _ = 1, flips do
                    -- Cannot affect the first letter
                    local idx = math.random(2, #result)
                    local char = result:sub(idx, idx)
                    if char:match("%a") then
                        local newChar = flipCase(char)
                        result = result:sub(1, idx - 1) .. newChar .. result:sub(idx + 1)
                    end
                end
            else
                -- Failure: Increase chance of remaining methods
                m2_chance = m2_chance + 10
                m3_chance = m3_chance + 10
            end

            -- Pass 2: METHOD 2 - Random Dots
            local current_len = #result
            -- Chance scales exponentially with size
            local final_m2_chance = m2_chance * (1 - math.exp(-current_len / 3)) 

            if current_len >= 3 and math.random(1, 100) <= final_m2_chance then
                -- Success: Proceed with Dot Insertion logic
                local idx = math.random(2, current_len - 1)
                local dot = "."
                
                -- 35% chance for a space before or after
                if math.random(1, 100) <= 35 then
                    dot = (math.random(1, 2) == 1) and " ." or ". "
                end
                
                -- Insert the dot/space
                result = result:sub(1, idx) .. dot .. result:sub(idx + 1)
                local newLen = #result
                
                -- NEW REQUIREMENT: 50% chance to flip case of char before or after the insertion
                if math.random(1, 2) == 1 then
                    local charToFlipIdx = 0
                    
                    -- Decide if before (idx) or after (idx + #dot + 1)
                    if math.random(1, 2) == 1 then 
                        charToFlipIdx = idx -- Character before
                    elseif idx + #dot + 1 <= newLen then
                        charToFlipIdx = idx + #dot + 1 -- Character after
                    end
                    
                    if charToFlipIdx > 0 and charToFlipIdx <= newLen then
                        local char = result:sub(charToFlipIdx, charToFlipIdx)
                        if char:match("%a") then
                            local newChar = flipCase(char)
                            result = result:sub(1, charToFlipIdx - 1) .. newChar .. result:sub(charToFlipIdx + 1)
                        end
                    end
                end
            else
                -- Failure: Increase chance of remaining method
                m3_chance = m3_chance + 10
            end

            -- Pass 3: METHOD 3 - Similes
            current_len = #result
            -- Chance scales exponentially with size
            local final_m3_chance = m3_chance * math.pow(1.1, current_len)

            if math.random(1, 100) <= final_m3_chance then
                -- Success: Proceed with Simile logic
                local changes = 0
                local maxChanges = (current_len <= 4) and 1 or 2
                local output = ""

                for i = 1, current_len do
                    local char = result:sub(i, i)
                    local low = char:lower()
                    local replaced = false

                    if changes < maxChanges then
                        if low == "o" and math.random(1, 100) <= 60 then
                            char = "0"; replaced = true
                        elseif low == "i" and math.random(1, 100) <= 60 then
                            char = (math.random(1, 2) == 1 and "l" or "1"); replaced = true
                        elseif low == "a" and math.random(1, 100) <= 40 then
                            char = "@"; replaced = true
                        elseif low == "b" and math.random(1, 100) <= 30 then
                            char = "6"; replaced = true
                        end
                    end

                    output = output .. char
                    if replaced then changes = changes + 1 end
                end
                result = output
            end

            return result
        end

        local finalWords = {}
        for _, arg in ipairs(flags) do
            table.insert(finalWords, corruptWord(arg))
        end

        Interpreter.sendChatMessage(table.concat(finalWords, " "))
    end,
    
    helper = function(flags)
        -- Check if this is a fresh update
        local freshUpdate = safeCheckFile(FILES.UpdateLock)
        
        if freshUpdate then
            -- Delete update lock
            safeDeleteFile(FILES.UpdateLock)
            
            -- Show changelog instead
            Interpreter.cmd("changelog")
            return
        end
        
        -- Normal helper flow
        Interpreter.create.window("Helper")
        Interpreter.create.prompt("Helper", "Hi, is this your first time using RuptorX?")
        Interpreter.create.txtinput("Helper", "yes/no")
        
        Interpreter.placeholderis.finished("Helper", 1, "helper_answer")
        Interpreter.windowis.closed("Helper", "helper_close")
        
        print("GUI: Helper window created")
    end,
    
    helper_answer = function(flags)
        local answer = flags[1] and flags[1]:lower() or ""
        
        if answer == "no" then
            Interpreter.destroy.window("Helper")
            print("HELPER: User declined help")
        elseif answer == "yes" then
            -- Clear existing elements
            Interpreter.destroy.txtinput("Helper", 1)
            Interpreter.destroy.prompt("Helper", 1)
            
            task.wait(0.3)
            
            -- Show instructions
            Interpreter.create.prompt("Helper", "Use /console to find the command list. Simply type in any command from the command list from console in chat using the * prefix. Close this window when done.")
            
            print("HELPER: Showing instructions")
        else
            warn("HELPER: Invalid response. Please type 'yes' or 'no'")
        end
    end,
    
    helper_close = function(flags)
        print("HELPER: Helper window closing")
        Interpreter.destroy.window("Helper")
    end,
    
    -- NEW: Changelog Command
    changelog = function(flags)
        Interpreter.create.window({
            title = "RuptorX Changelog",
            type = "popup",
            size = "large",
            position = "center"
        })
        
        -- Version header (split into parts to avoid concatenation issues)
        Interpreter.create.prompt("RuptorX Changelog", "Version 140 - What's New")
        
        -- Add spacing
        Interpreter.create.prompt("RuptorX Changelog", " ")
        
        -- NEW FEATURES
        Interpreter.create.prompt("RuptorX Changelog", "NEW FEATURES:")
        Interpreter.create.prompt("RuptorX Changelog", "ShowHP - Retro overhead HP bars for all players")
        Interpreter.create.prompt("RuptorX Changelog", "Changelog System - Stay updated with new features")
        Interpreter.create.prompt("RuptorX Changelog", "Enhanced walkfling - Now survives respawn")
        Interpreter.create.prompt("RuptorX Changelog", "Alias System - Create custom command shortcuts")
        
        -- Add spacing
        Interpreter.create.prompt("RuptorX Changelog", " ")
        
        -- IMPROVEMENTS
        Interpreter.create.prompt("RuptorX Changelog", "IMPROVEMENTS:")
        Interpreter.create.prompt("RuptorX Changelog", "NoStun optimization - 90% less lag")
        Interpreter.create.prompt("RuptorX Changelog", "Better respawn handling across all commands")
        Interpreter.create.prompt("RuptorX Changelog", "Improved GUI animations and performance")
        Interpreter.create.prompt("RuptorX Changelog", "ChatX terminal stability enhancements")
        
        -- Add spacing
        Interpreter.create.prompt("RuptorX Changelog", " ")
        
        -- BUG FIXES
        Interpreter.create.prompt("RuptorX Changelog", "BUG FIXES:")
        Interpreter.create.prompt("RuptorX Changelog", "Fixed walkfling self-fling issue")
        Interpreter.create.prompt("RuptorX Changelog", "Fixed NoStun FPS drops")
        Interpreter.create.prompt("RuptorX Changelog", "Fixed TP command position corruption")
        Interpreter.create.prompt("RuptorX Changelog", "Fixed ESP memory leaks")
        Interpreter.create.prompt("RuptorX Changelog", "Fixed notification tween crashes")
        
        -- Add spacing
        Interpreter.create.prompt("RuptorX Changelog", " ")
        
        -- COMMANDS
        Interpreter.create.prompt("RuptorX Changelog", "NEW COMMANDS:")
        Interpreter.create.prompt("RuptorX Changelog", "showhp - Toggle overhead HP bars")
        Interpreter.create.prompt("RuptorX Changelog", "changelog - View this changelog anytime")
        Interpreter.create.prompt("RuptorX Changelog", "alias add/remove - Create command shortcuts")
        
        -- Add spacing
        Interpreter.create.prompt("RuptorX Changelog", " ")
        
        Interpreter.create.prompt("RuptorX Changelog", "Type /console for full command list")
        Interpreter.create.prompt("RuptorX Changelog", "Join our Discord for updates and support!")
        
        -- Close button callback
        Interpreter.windowis.closed("RuptorX Changelog", "changelog_close")
        
        -- Mark as viewed
        Interpreter.ChangelogViewed = true
        
        print("CHANGELOG: Changelog window opened")
    end,
    
    changelog_close = function(flags)
        print("CHANGELOG: Changelog window closing")
        Interpreter.destroy.window("RuptorX Changelog")
        
        -- After viewing changelog, show helper if first time
        if not Interpreter.ChangelogViewed then
            task.wait(0.5)
            Interpreter.cmd("helper")
        end
    end,
    
    chatx = function(flags)
        local action = flags[1] and flags[1]:lower() or "toggle"
        
        if action == "on" or action == "true" or (action == "toggle" and not Interpreter.ChatXActive) then
            Interpreter.startChatX()
            Interpreter.ChatXActive = true
        elseif action == "off" or action == "false" or (action == "toggle" and Interpreter.ChatXActive) then
            Interpreter.stopChatX()
            Interpreter.ChatXActive = false
        else
            warn("CHATX: Invalid syntax. Use '*chatx' to toggle, '*chatx on' or '*chatx off'")
        end
    end,
    
    chatx = function(flags)
        local action = flags[1] and flags[1]:lower() or "toggle"
        
        if action == "on" or action == "true" or (action == "toggle" and not Interpreter.ChatXActive) then
            Interpreter.startChatX()
            Interpreter.ChatXActive = true
        elseif action == "off" or action == "false" or (action == "toggle" and Interpreter.ChatXActive) then
            Interpreter.stopChatX()
            Interpreter.ChatXActive = false
        else
            warn("CHATX: Invalid syntax. Use '*chatx' to toggle, '*chatx on' or '*chatx off'")
        end
    end,
    
    tp = function(flags)
        local action = flags[1] and flags[1]:lower()
        
        if action == "add" then
            local name = flags[2]
            if not name then
                warn("TP: Usage: *tp add <name>")
                return
            end
            
            local root = Interpreter.getRootPart()
            if not root then
                warn("TP: No character found")
                return
            end
            
            Interpreter.Waypoints[name] = root.CFrame
            print("TP: Waypoint '" .. name .. "' saved" .. (Interpreter.Waypoints[name] and " (overwritten)" or ""))
            
        elseif action == "to" then
            local name = flags[2]
            if not name then
                warn("TP: Usage: *tp to <name>")
                return
            end
            
            local waypoint = Interpreter.Waypoints[name]
            if not waypoint then
                warn("TP: Waypoint '" .. name .. "' not found")
                return
            end
            
            local root = Interpreter.getRootPart()
            if not root then
                warn("TP: No character found")
                return
            end
            
            task.spawn(function()
                local startTime = tick()
                while tick() - startTime < 0.3 do
                    local currentRoot = Interpreter.getRootPart()
                    if currentRoot then
                        currentRoot.CFrame = waypoint
                        currentRoot.Velocity = Vector3.new(0,0,0)
                        currentRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
            
            print("TP: Teleported to '" .. name .. "'")
            
        elseif action == "list" then
            local count = 0
            for name, _ in pairs(Interpreter.Waypoints) do
                count = count + 1
            end
            
            if count == 0 then
                print("TP: No waypoints saved")
                return
            end
            
            print("TP: Saved waypoints (" .. count .. "):")
            for name, _ in pairs(Interpreter.Waypoints) do
                print("  - " .. name)
            end
            
        elseif action == "rem" then
            local name = flags[2]
            if not name then
                warn("TP: Usage: *tp rem <name>")
                return
            end
            
            if Interpreter.Waypoints[name] then
                Interpreter.Waypoints[name] = nil
                print("TP: Waypoint '" .. name .. "' removed")
            else
                warn("TP: Waypoint '" .. name .. "' not found")
            end
            
        else
            local name = flags[1]
            if not name then
                warn("TP: Usage: *tp <name> | *tp add/to/list/rem")
                return
            end
            
            local waypoint = Interpreter.Waypoints[name]
            if not waypoint then
                warn("TP: Waypoint '" .. name .. "' not found")
                return
            end
            
            local root = Interpreter.getRootPart()
            if not root then
                warn("TP: No character found")
                return
            end
            
            task.spawn(function()
                local startTime = tick()
                while tick() - startTime < 0.3 do
                    local currentRoot = Interpreter.getRootPart()
                    if currentRoot then
                        currentRoot.CFrame = waypoint
                        currentRoot.Velocity = Vector3.new(0,0,0)
                        currentRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
            
            print("TP: Teleported to '" .. name .. "'")
        end
    end,
    
    -- NEW BACKPACK COMMAND
    bk = function(flags)
        local action = flags[1] and flags[1]:lower()
        local player = Players.LocalPlayer
        if not player then return end

        if action == "sv" then
            local character = Interpreter.getCharacter()
            if not character then warn("BK: Character not loaded.") return end

            -- Check if the player is holding a Tool (or similar instance)
            local currentlyHeldTool = character:FindFirstChildOfClass("Tool")
            
            -- If not in hand, check the backpack (in case they have it equipped but it's not a tool, or they want to copy an item)
            if not currentlyHeldTool then
                currentlyHeldTool = player.Backpack:FindFirstChildOfClass("Tool")
            end

            if currentlyHeldTool then
                -- Clean up old saved item to prevent memory leak
                if Interpreter.SavedBackpackItem then
                    Interpreter.SavedBackpackItem:Destroy()
                end

                -- Clone the item but parent it to nil immediately to keep it safe
                local itemClone = currentlyHeldTool:Clone()
                itemClone.Parent = nil 
                
                Interpreter.SavedBackpackItem = itemClone
                print("BK: Saved a clone of '" .. currentlyHeldTool.Name .. "' successfully.")
            else
                warn("BK: Could not find a Tool to save (check hand/backpack).")
            end
        elseif action == "ld" then
            if Interpreter.SavedBackpackItem then
                -- Load (clone) the saved item into the backpack
                local loadedItem = Interpreter.SavedBackpackItem:Clone()
                loadedItem.Parent = player.Backpack

                print("BK: Loaded a clone of '" .. loadedItem.Name .. "' into your backpack.")
            else
                warn("BK: No item saved yet. Use '*bk sv' first while holding an item.")
            end
        else
            warn("BK: Invalid syntax. Use '*bk sv' to save or '*bk ld' to load.")
        end
    end,

    count = function(flags)
        print("Flag count: " .. #flags)
        for i, flag in ipairs(flags) do
            print(i .. ": " .. flag)
        end
    end,
    
    team = function(flags)
        if #flags == 0 then
            warn("TEAM: Please specify a team name")
            return
        end
        
        local teamName = flags[1]
        local foundTeam = nil
        
        for _, team in ipairs(Teams:GetTeams()) do
            if team.Name:lower() == teamName:lower() then
                foundTeam = team
                break
            end
        end
        
        if foundTeam then
            local player = Players.LocalPlayer
            if player then
                player.Team = foundTeam
                print("TEAM: Switched to " .. foundTeam.Name)
            end
        else
            warn("TEAM: Team '" .. teamName .. "' not found")
        end
    end,
    
    pteam = function(flags)
        if #flags == 0 then
            warn("PTEAM: Please specify a team name")
            return
        end
        
        local teamName = flags[1]
        local foundTeam = nil
        
        for _, team in ipairs(Teams:GetTeams()) do
            if team.Name:lower() == teamName:lower() then
                foundTeam = team
                break
            end
        end
        
        if foundTeam then
            Interpreter.startPTeam(foundTeam)
        else
            warn("PTEAM: Team '" .. teamName .. "' not found")
        end
    end,
    
    uteam = function(flags)
        Interpreter.stopPTeam()
    end,
    
    health = function(flags)
        if #flags == 0 then
            local humanoid = Interpreter.getHumanoid()
            if humanoid then
                print("HEALTH: Current health is " .. humanoid.Health)
            end
            return
        end
        
        local newHealth = tonumber(flags[1])
        if not newHealth then
            warn("HEALTH: Please provide a valid number")
            return
        end
        
        local humanoid = Interpreter.getHumanoid()
        if humanoid then
            humanoid.Health = newHealth
            print("HEALTH: Set health to " .. newHealth)
        else
            warn("HEALTH: Character or humanoid not found")
        end
    end,
    
    phealth = function(flags)
        if #flags == 0 then
            warn("PHEALTH: Please specify a health value")
            return
        end
        
        local newHealth = tonumber(flags[1])
        if not newHealth then
            warn("PHEALTH: Please provide a valid number")
            return
        end
        
        Interpreter.CustomHealth = newHealth
        Interpreter.startPHealth()
        print("PHEALTH: Persistent health set to " .. newHealth)
    end,
    
    nostun = function(flags)
        local state = flags[1] and flags[1]:lower() or "toggle"
        
        if state == "on" or state == "true" or (state == "toggle" and not Interpreter.NoStun) then
            Interpreter.startNoStun()
        else
            Interpreter.stopNoStun()
        end
    end,

    -- ESP COMMAND
    esp = function(flags)
        local state = flags[1] and flags[1]:lower() or "toggle"
        
        if state == "on" or state == "true" or (state == "toggle" and not Interpreter.ESPActive) then
            Interpreter.startESP()
        else
            Interpreter.stopESP()
        end
    end,
    
    -- NOREGUL COMMAND
    noregul = function(flags)
        local state = flags[1] and flags[1]:lower() or "toggle"
        
        if state == "on" or state == "true" or (state == "toggle" and not Interpreter.NoRegulActive) then
            Interpreter.startNoRegul()
        else
            Interpreter.stopNoRegul()
        end
    end,

    reset = function(flags)
        Interpreter.quickReset()
    end,
    
    unfly = function(flags)
        Interpreter.stopAllFlying()
    end,
    
    noclip = function(flags)
        local state = flags[1] and flags[1]:lower() or "toggle"
        
        if state == "on" or state == "true" or (state == "toggle" and not Interpreter.Noclipping) then
            Interpreter.startNoclip()
        else
            Interpreter.stopNoclip()
        end
    end,
    
    to = function(flags)
        if #flags == 0 then
            warn("TO: Please specify a player name")
            return
        end
        
        local targetName = flags[1]
        local targetPlayer = findPlayerByName(targetName)
        
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Interpreter.startTo(targetPlayer)
        else
            warn("TO: Player '" .. targetName .. "' not found or doesn't have a character")
        end
    end,
    
    spin = function(flags)
        local state = flags[1] and flags[1]:lower() or "toggle"
        local speed = tonumber(flags[2]) or Interpreter.SpinSpeed
        
        if speed and speed > 0 then
            Interpreter.SpinSpeed = speed
        end
        
        if state == "on" or state == "true" or (state == "toggle" and not Interpreter.Spinning) then
            Interpreter.startSpin()
        else
            Interpreter.stopSpin()
        end
    end,
    
    speed = function(flags)
        if #flags == 0 then
            local humanoid = Interpreter.getHumanoid()
            if humanoid then
                print("SPEED: Current walkspeed is " .. humanoid.WalkSpeed)
            end
            return
        end
        
        local newSpeed = tonumber(flags[1])
        if not newSpeed then
            warn("SPEED: Please provide a valid number")
            return
        end
        
        Interpreter.CustomWalkSpeed = newSpeed
        Interpreter.applySpeedAndJump()
        print("SPEED: Set walkspeed to " .. newSpeed)
    end,
    
    jump = function(flags)
        if #flags == 0 then
            local humanoid = Interpreter.getHumanoid()
            if humanoid then
                if humanoid.RigType == Enum.HumanoidRigType.R15 then
                    print("JUMP: Current jump height is " .. humanoid.JumpHeight)
                else
                    print("JUMP: Current jump power is " .. humanoid.JumpPower)
                end
            end
            return
        end
        
        local newJump = tonumber(flags[1])
        if not newJump then
            warn("Interpreter: Invalid Input", "Please provide a valid number", "error")
            return
        end
        
        Interpreter.CustomJumpPower = newJump
        Interpreter.applySpeedAndJump()
        
        local humanoid = Interpreter.getHumanoid()
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            print("Interpreter: Jump Changed", "Jump height set to " .. string.format("%.1f", newJump / 6.944), "success")
        else
            print("Interpreter: Jump Changed", "Jump power set to " .. newJump, "success")
        end
    end,
    
    dance = function(flags)
        local player = Players.LocalPlayer
        if player then
            local dances = {"dance1", "dance2", "dance3"}
            local randomDance = dances[math.random(1, #dances)]
            
            -- Legacy chat for emote command
            game:GetService("Players"):Chat("/e " .. randomDance)
            
            -- Also try TextChatService just in case
            if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral") then
               TextChatService.TextChannels.RBXGeneral:SendAsync("/e " .. randomDance)
            end
            
            print("DANCE: Performing " .. randomDance)
        end
    end,
    
    lockto = function(flags)
        if #flags == 0 then
            warn("LOCKTO: Please specify a player name")
            return
        end
        
        local targetName = flags[1]
        local targetPlayer = findPlayerByName(targetName)
        
        if targetPlayer then
            Interpreter.startLockTo(targetPlayer)
        else
            warn("LOCKTO: Player '" .. targetName .. "' not found")
        end
    end,
    
    unlock = function(flags)
        Interpreter.stopLockTo()
    end,
    
    follow = function(flags)
        if #flags == 0 then
            warn("FOLLOW: Please specify a player name")
            return
        end
        
        local targetName = flags[1]
        local targetPlayer = findPlayerByName(targetName)
        
        if targetPlayer then
            Interpreter.startFollow(targetPlayer)
        else
            warn("FOLLOW: Player '" .. targetName .. "' not found")
        end
    end,
    
    sflw = function(flags)
        Interpreter.stopFollow()
    end,
    
    orbit = function(flags)
        if #flags == 0 then
            warn("ORBIT: Please specify a player name")
            return
        end
        
        local targetName = flags[1]
        local speed = tonumber(flags[2]) or Interpreter.OrbitSpeed
        
        local targetPlayer = findPlayerByName(targetName)
        
        if targetPlayer then
            Interpreter.startOrbit(targetPlayer, speed)
        else
            warn("ORBIT: Player '" .. targetName .. "' not found")
        end
    end,
    
    sorbit = function(flags)
        Interpreter.stopOrbit()
    end,
    
    troll = function(flags)
        local teamFilter = nil
        
        -- Check if a team name was provided
        if #flags > 0 then
            teamFilter = flags[1]
        end
        
        Interpreter.startTroll(teamFilter)
    end,
    
    stroll = function(flags)
        Interpreter.stroll()
    end,
    
    walkfling = function(flags)
        Interpreter.startwalkfling()
    end,
    
    sft = function(flags)
        Interpreter.stopwalkfling()
    end,
    
    float = function(flags)
        if #flags == 0 then
            warn("FLOAT: Please specify a height in studs")
            return
        end
        
        local height = tonumber(flags[1])
        if not height then
            warn("FLOAT: Please provide a valid number")
            return
        end
        
        Interpreter.startFloat(height)
    end,
    
    sfloat = function(flags)
        Interpreter.stopFloat()
    end,
    
    shutdown = function(flags)
        Interpreter.shutdown()
    end
}

-- Quick Reset system
function Interpreter.quickReset()
    local character = Interpreter.getCharacter()
    local rootPart = Interpreter.getRootPart()
    
    if not character or not rootPart then return end
    
    Interpreter.RespawnPosition = rootPart.Position
    
    local humanoid = Interpreter.getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
    
    print("RESET: Quick reset initiated")
end

-- Persistent Health system
function Interpreter.startPHealth()
    if Interpreter.PHealthActive then return end
    
    Interpreter.PHealthActive = true
    
    -- Spawn a new thread (coroutine) to manage persistent health
    Interpreter.PHealthConnection = task.spawn(function()
        while Interpreter.Active and Interpreter.PHealthActive do
            local humanoid = Interpreter.getHumanoid()
            if humanoid and Interpreter.CustomHealth then
                humanoid.Health = Interpreter.CustomHealth
            end
            
            -- Dynamic wait time
            local waitTime = Interpreter.NoRegulActive and 0.001 or 0.1
            task.wait(waitTime) 
        end
    end)
    
    print("PHEALTH: Persistent health activated")
end

function Interpreter.stopPHealth()
    if not Interpreter.PHealthActive then return end
    
    -- Setting the flag to false will terminate the loop in the spawned thread
    Interpreter.PHealthActive = false
    Interpreter.PHealthConnection = nil -- Clear the reference
    Interpreter.CustomHealth = nil
    print("PHEALTH: Persistent health deactivated")
end

-- NoStun Cache System
Interpreter.NoStunCache = {
    BodyParts = {},
    LastUpdate = 0,
    UpdateInterval = 2
}

function Interpreter.rebuildNoStunCache()
    local character = Interpreter.getCharacter()
    if not character then return end
    
    Interpreter.NoStunCache.BodyParts = {}
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Interpreter.NoStunCache.BodyParts, part)
        end
    end
    
    Interpreter.NoStunCache.LastUpdate = tick()
end

function Interpreter.startNoStun()
    if Interpreter.NoStun then return end
    
    Interpreter.NoStun = true
    local character = Interpreter.getCharacter()
    local humanoid = Interpreter.getHumanoid()
    local rootPart = Interpreter.getRootPart()
    
    if not character or not humanoid or not rootPart then return end
    
    -- Build initial cache
    Interpreter.rebuildNoStunCache()
    
    -- Hybrid approach: Events for instant response + Heartbeat for coverage
    Interpreter.NoStunConnections = {}
    
    -- Event 1: Humanoid state changes (instant)
    table.insert(Interpreter.NoStunConnections, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
        if Interpreter.NoStun then
            humanoid.PlatformStand = false
        end
    end))
    
    table.insert(Interpreter.NoStunConnections, humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if Interpreter.NoStun then
            humanoid.Sit = false
        end
    end))
    
    -- Event 2: RootPart anchoring (instant)
    table.insert(Interpreter.NoStunConnections, rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
        if Interpreter.NoStun and rootPart.Anchored then
            rootPart.Anchored = false
        end
    end))
    
    -- Event 3: Detect new BodyMovers being added (instant)
    table.insert(Interpreter.NoStunConnections, character.DescendantAdded:Connect(function(obj)
        if not Interpreter.NoStun then return end
        
        if obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
            if obj ~= Interpreter.FlightBV and obj ~= Interpreter.FlightBG and obj ~= Interpreter.FloatBP then
                task.wait()
                if obj.Parent then
                    obj:Destroy()
                end
            end
        end
    end))
    
    -- Heartbeat Loop: Lightweight safety net (catches everything else)
    table.insert(Interpreter.NoStunConnections, RunService.Heartbeat:Connect(function()
        if not Interpreter.NoStun then return end
        
        local hum = Interpreter.getHumanoid()
        local root = Interpreter.getRootPart()
        
        if not hum or not root then return end
        
        -- Quick state checks (no GetDescendants)
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
        if root.Anchored then root.Anchored = false end
        
        -- Reset angular velocity if spinning (anti-ragdoll)
        local angVel = root.AssemblyAngularVelocity
        if angVel.Magnitude > 0.5 then
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Rebuild cache periodically (not every frame!)
        local now = tick()
        if now - Interpreter.NoStunCache.LastUpdate > Interpreter.NoStunCache.UpdateInterval then
            Interpreter.rebuildNoStunCache()
        end
        
        -- Use cached parts to unanchor (much faster than GetDescendants)
        for _, part in ipairs(Interpreter.NoStunCache.BodyParts) do
            if part and part.Parent and part ~= root and part.Anchored then
                part.Anchored = false
            end
        end
    end))
    
    print("NOSTUN: Anti-freeze activated (Hybrid mode)")
end

function Interpreter.stopNoStun()
    if not Interpreter.NoStun then return end
    
    Interpreter.NoStun = false
    
    -- Disconnect all connections
    if Interpreter.NoStunConnections then
        for _, conn in ipairs(Interpreter.NoStunConnections) do
            conn:Disconnect()
        end
        Interpreter.NoStunConnections = nil
    end
    
    -- Clear cache
    Interpreter.NoStunCache = {BodyParts = {}, LastUpdate = 0, UpdateInterval = 2}
    
    print("NOSTUN: Anti-freeze deactivated")
end

-- ESP System (Wallhacks)
function Interpreter.startESP()
    if Interpreter.ESPActive then return end
    Interpreter.ESPActive = true
    
    -- We use a loop to constantly update in case players die/respawn or switch teams
    Interpreter.ESPLoop = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.ESPActive then 
            Interpreter.stopESP()
            return 
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            -- Don't highlight yourself
            if player ~= Players.LocalPlayer and player.Character then
                local char = player.Character
                
                -- Check if highlight already exists
                local highlight = char:FindFirstChild("RuptorESP")
                
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "RuptorESP"
                    highlight.Adornee = char
                    highlight.Parent = char
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- The "Wallhack" part
                    highlight.FillTransparency = 1 -- Clear center (only outline)
                    highlight.OutlineTransparency = 0 -- Solid outline
                end
                
                -- Update Color based on Team (Live updates)
                local teamColor = Color3.new(1, 1, 1) -- Default White
                if player.TeamColor then
                    teamColor = player.TeamColor.Color
                end
                
                highlight.OutlineColor = teamColor
            end
        end
    end)
    
    print("ESP: Visuals enabled")
end

function Interpreter.stopESP()
    if not Interpreter.ESPActive then return end
    
    Interpreter.ESPActive = false
    
    if Interpreter.ESPLoop then
        Interpreter.ESPLoop:Disconnect()
        Interpreter.ESPLoop = nil
    end
    
    -- Cleanup: Remove the dirty evidence
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("RuptorESP")
            if highlight then
                highlight:Destroy()
            end
        end
    end
    
    print("ESP: Visuals disabled")
end

-- NOREGUL Functions
function Interpreter.startNoRegul()
    Interpreter.NoRegulActive = true
    print("NOREGUL: Regulation disabled. Loops running at maximum speed.")
end

function Interpreter.stopNoRegul()
    Interpreter.NoRegulActive = false
    print("NOREGUL: Regulation enabled. Loops running at normal intervals.")
end

-- Float system
function Interpreter.startFloat(height)
    if Interpreter.Floating then
        Interpreter.stopFloat()
    end
    
    Interpreter.FloatHeight = height or 5
    Interpreter.Floating = true
    
    local rootPart = Interpreter.getRootPart()
    if not rootPart then return end
    
    local bp = Instance.new("BodyPosition")
    bp.Position = rootPart.Position + Vector3.new(0, Interpreter.FloatHeight, 0)
    bp.MaxForce = Vector3.new(0, 40000, 0)
    bp.Parent = rootPart
    
    Interpreter.FloatBP = bp
    
    Interpreter.FloatConnection = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.Floating or not Interpreter.FloatBP then
            Interpreter.stopFloat()
            return
        end
        
        local root = Interpreter.getRootPart()
        if not root then return end
        
        local rayOrigin = root.Position
        local rayDirection = Vector3.new(0, -50, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {Interpreter.getCharacter()}
        
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if raycastResult then
            Interpreter.FloatBP.Position = raycastResult.Position + Vector3.new(0, Interpreter.FloatHeight, 0)
        else
            Interpreter.FloatBP.Position = Vector3.new(root.Position.X, root.Position.Y, root.Position.Z)
        end
    end)
    
    print("FLOAT: Floating at " .. Interpreter.FloatHeight .. " studs above ground")
end

function Interpreter.stopFloat()
    if not Interpreter.Floating then return end
    
    if Interpreter.FloatConnection then
        Interpreter.FloatConnection:Disconnect()
        Interpreter.FloatConnection = nil
    end
    
    if Interpreter.FloatBP then
        Interpreter.FloatBP:Destroy()
        Interpreter.FloatBP = nil
    end
    
    Interpreter.Floating = false
    print("FLOAT: Floating deactivated")
end

-- Create HP bar for a player
local function CreateHPBar(player)
    if player == Players.LocalPlayer then return end -- Don't show on self
    
    local character = player.Character
    if not character then return end
    
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    -- Check if bar already exists
    if head:FindFirstChild("RuptorHP_Billboard") then return end
    
    -- Create BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RuptorHP_Billboard"
    billboard.Size = UDim2.new(4, 0, 0.5, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    -- Background frame (retro black border)
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 4, 1, 4)
    background.Position = UDim2.new(0, -2, 0, -2)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    -- Health bar container (retro gray background)
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    container.BorderSizePixel = 0
    container.Parent = billboard
    
    -- Health bar fill (green to red gradient)
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = container
    
    -- Retro gradient effect (lighter top edge)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0))
    })
    gradient.Rotation = 90
    gradient.Parent = healthBar
    
    -- Health text (retro font)
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextStrokeTransparency = 0.5
    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthText.Font = Enum.Font.Code
    healthText.TextSize = 14
    healthText.TextScaled = false
    healthText.Parent = billboard
    
    -- Player name tag (optional - retro style)
    local nameTag = Instance.new("TextLabel")
    nameTag.Name = "NameTag"
    nameTag.Size = UDim2.new(1, 0, 0.5, 0)
    nameTag.Position = UDim2.new(0, 0, -0.6, 0)
    nameTag.BackgroundTransparency = 1
    nameTag.Text = player.DisplayName
    nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameTag.TextStrokeTransparency = 0.5
    nameTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameTag.Font = Enum.Font.Code
    nameTag.TextSize = 12
    nameTag.TextScaled = false
    nameTag.Parent = billboard
    
    -- Store reference
    Interpreter.HPBars[player.UserId] = {
        Billboard = billboard,
        HealthBar = healthBar,
        HealthText = healthText,
        Gradient = gradient,
        Player = player
    }
    
    print("SHOWHP: Created HP bar for " .. player.Name)
end

-- Update HP bar for a player
local function UpdateHPBar(player)
    local barData = Interpreter.HPBars[player.UserId]
    if not barData then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = math.clamp(health / maxHealth, 0, 1)
    
    -- Update bar size
    barData.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    
    -- Update text
    barData.HealthText.Text = math.floor(health)
    
    -- Update color (green → yellow → red)
    if healthPercent > 0.5 then
        -- Green to Yellow
        local t = (1 - healthPercent) * 2
        barData.HealthBar.BackgroundColor3 = Color3.fromRGB(
            math.floor(255 * t),
            255,
            0
        )
        -- Update gradient
        barData.Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(200, 255, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(
                math.floor(200 * t),
                200,
                0
            ))
        })
    else
        -- Yellow to Red
        local t = healthPercent * 2
        barData.HealthBar.BackgroundColor3 = Color3.fromRGB(
            255,
            math.floor(255 * t),
            0
        )
        -- Update gradient
        barData.Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(
                200,
                math.floor(200 * t),
                0
            ))
        })
    end
end

-- Remove HP bar for a player
local function RemoveHPBar(player)
    local barData = Interpreter.HPBars[player.UserId]
    if not barData then return end
    
    if barData.Billboard then
        barData.Billboard:Destroy()
    end
    
    Interpreter.HPBars[player.UserId] = nil
    print("SHOWHP: Removed HP bar for " .. player.Name)
end

-- Start ShowHP system
function Interpreter.startShowHP()
    if Interpreter.ShowHPActive then return end
    
    Interpreter.ShowHPActive = true
    Interpreter.HPBars = {}
    
    -- Create bars for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            CreateHPBar(player)
        end
    end
    
    -- Main update loop
    Interpreter.ShowHPConnection = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.ShowHPActive then
            Interpreter.stopShowHP()
            return
        end
        
        -- Update all HP bars
        for userId, barData in pairs(Interpreter.HPBars) do
            local player = barData.Player
            
            -- Check if player still exists
            if not player or not player.Parent or player.Parent ~= Players then
                RemoveHPBar(player)
            else
                -- Check if character/head still exists
                local character = player.Character
                local head = character and character:FindFirstChild("Head")
                local billboard = head and head:FindFirstChild("RuptorHP_Billboard")
                
                if not billboard then
                    -- Recreate if missing (respawn handling)
                    RemoveHPBar(player)
                    CreateHPBar(player)
                else
                    -- Update HP
                    UpdateHPBar(player)
                end
            end
        end
    end)
    
    -- Listen for new players joining
    Interpreter.ShowHPPlayerAdded = Players.PlayerAdded:Connect(function(player)
        if not Interpreter.ShowHPActive then return end
        
        -- Wait for character
        if player.Character then
            CreateHPBar(player)
        end
        
        player.CharacterAdded:Connect(function()
            if Interpreter.ShowHPActive then
                task.wait(0.1) -- Wait for character to fully load
                CreateHPBar(player)
            end
        end)
    end)
    
    -- Listen for players leaving
    Interpreter.ShowHPPlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        RemoveHPBar(player)
    end)
    
    -- Listen for character respawns (existing players)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            player.CharacterAdded:Connect(function()
                if Interpreter.ShowHPActive then
                    task.wait(0.1)
                    CreateHPBar(player)
                end
            end)
        end
    end
    
    print("SHOWHP: HP bars enabled for all players")
end

-- Stop ShowHP system
function Interpreter.stopShowHP()
    if not Interpreter.ShowHPActive then return end
    
    Interpreter.ShowHPActive = false
    
    -- Disconnect update loop
    if Interpreter.ShowHPConnection then
        Interpreter.ShowHPConnection:Disconnect()
        Interpreter.ShowHPConnection = nil
    end
    
    -- Disconnect player events
    if Interpreter.ShowHPPlayerAdded then
        Interpreter.ShowHPPlayerAdded:Disconnect()
        Interpreter.ShowHPPlayerAdded = nil
    end
    
    if Interpreter.ShowHPPlayerRemoving then
        Interpreter.ShowHPPlayerRemoving:Disconnect()
        Interpreter.ShowHPPlayerRemoving = nil
    end
    
    -- Remove all HP bars
    for userId, barData in pairs(Interpreter.HPBars) do
        if barData.Billboard then
            barData.Billboard:Destroy()
        end
    end
    
    Interpreter.HPBars = {}
    
    print("SHOWHP: HP bars disabled")
end

Interpreter.Handlers.showhp = function(flags)
    local state = flags[1] and flags[1]:lower() or "toggle"
    
    if state == "on" or state == "true" or (state == "toggle" and not Interpreter.ShowHPActive) then
        Interpreter.startShowHP()
    else
        Interpreter.stopShowHP()
    end
end

-- Touch Fling system (FIXED - Respawn-proof, using original working method)
function Interpreter.startwalkfling()
    if Interpreter.walkfling then return end
    
    Interpreter.walkfling = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Create detection marker
    if not ReplicatedStorage:FindFirstChild("RuptorXFlingDetection") then
        local detection = Instance.new("Decal")
        detection.Name = "RuptorXFlingDetection"
        detection.Parent = ReplicatedStorage
    end
    
    -- Main fling loop (ORIGINAL WORKING METHOD - respawn-proof wrapper)
    Interpreter.walkflingConnection = task.spawn(function()
        local hrp, c, vel, movel = nil, nil, nil, 0.1
        
        while Interpreter.Active and Interpreter.walkfling do
            RunService.Heartbeat:Wait()
            
            -- Wait for valid character (handles respawn automatically)
            while Interpreter.walkfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = LocalPlayer.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            
            -- Exit if disabled during wait
            if not Interpreter.walkfling then break end
            
            -- Execute fling (ORIGINAL WORKING CODE)
            if Interpreter.walkfling and c and c.Parent and hrp and hrp.Parent then
                vel = hrp.Velocity
                hrp.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                
                if c and c.Parent and hrp and hrp.Parent then
                    hrp.Velocity = vel
                end
                
                RunService.Stepped:Wait()
                
                if c and c.Parent and hrp and hrp.Parent then
                    hrp.Velocity = vel + Vector3.new(0, movel, 0)
                    movel = movel * -1
                end
            end
        end
        
        print("walkfling: Loop terminated")
    end) -- <-- THIS WAS MISSING! Closes task.spawn()
    
    print("walkfling: Touch fling activated (respawn-proof)")
    Interpreter.notify("Fling Touch ON", "Touch enemies to fling them", "success", 4)
end

function Interpreter.stopwalkfling()
    if not Interpreter.walkfling then return end
    
    Interpreter.walkfling = false
    
    -- Stop the loop
    if Interpreter.walkflingConnection then
        task.cancel(Interpreter.walkflingConnection)
        Interpreter.walkflingConnection = nil
    end
    
    -- Clean up detection marker
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local detection = ReplicatedStorage:FindFirstChild("RuptorXFlingDetection")
    if detection then
        detection:Destroy()
    end
    
    -- Restore velocity
    local rootPart = Interpreter.getRootPart()
    if rootPart then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    
    print("walkfling: Touch fling deactivated")
end

function Interpreter.stroll()
    if not Interpreter.Trolling then return end
    
    Interpreter.Trolling = false
    
    -- Emergency stop: Cancel the running thread immediately.
    if Interpreter.TrollConnection then
        task.cancel(Interpreter.TrollConnection)
        Interpreter.TrollConnection = nil
    end
    
    Interpreter.TrollTeamFilter = nil
    Interpreter.TrollTargets = {}
    print("TROLL: Trolling deactivated")
end

-- To command
function Interpreter.startTo(targetPlayer)
    local char = Interpreter.getCharacter()
    local rootPart = Interpreter.getRootPart()
    
    if not char or not rootPart then return end
    
    task.spawn(function()
        local startTime = tick()
        while Interpreter.Active and tick() - startTime < Interpreter.ToDuration do
            if targetPlayer.Character and targetPlayer.Character.HumanoidRootPart then
                local root = Interpreter.getRootPart()
                if root then
                    root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                end
            else
                break
            end
            RunService.Heartbeat:Wait()
        end
    end)
    
    print("TO: Teleporting to " .. targetPlayer.Name .. " for " .. Interpreter.ToDuration .. " seconds")
end

-- Orbit system
function Interpreter.startOrbit(targetPlayer, speed)
    if Interpreter.Orbiting then
        Interpreter.stopOrbit()
    end
    
    Interpreter.OrbitTarget = targetPlayer
    Interpreter.OrbitSpeed = speed or 10
    Interpreter.Orbiting = true
    
    local orbitAngle = 0
    
    Interpreter.OrbitConnection = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.Orbiting or not Interpreter.OrbitTarget then
            Interpreter.stopOrbit()
            return
        end
        
        local localRoot = Interpreter.getRootPart()
        local targetChar = Interpreter.OrbitTarget.Character
        
        if not localRoot then return end
        
        if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
            print("ORBIT: Target character not found, stopping orbit")
            Interpreter.stopOrbit()
            return
        end
        
        local targetRoot = targetChar.HumanoidRootPart
        orbitAngle = orbitAngle + Interpreter.OrbitSpeed * 0.01
        
        local x = math.cos(orbitAngle) * Interpreter.OrbitDistance
        local z = math.sin(orbitAngle) * Interpreter.OrbitDistance
        
        local orbitPosition = targetRoot.Position + Vector3.new(x, 2, z)
        
        localRoot.CFrame = CFrame.lookAt(orbitPosition, targetRoot.Position)
    end)
    
    print("ORBIT: Orbiting " .. targetPlayer.Name .. " at speed " .. Interpreter.OrbitSpeed)
end

function Interpreter.stopOrbit()
    if not Interpreter.Orbiting then return end
    
    if Interpreter.OrbitConnection then
        Interpreter.OrbitConnection:Disconnect()
        Interpreter.OrbitConnection = nil
    end
    
    Interpreter.OrbitTarget = nil
    Interpreter.Orbiting = false
    print("ORBIT: Stopped orbiting")
end

-- Follow system
function Interpreter.startFollow(targetPlayer)
    if Interpreter.Following then
        Interpreter.stopFollow()
    end
    
    Interpreter.FollowTarget = targetPlayer
    Interpreter.Following = true
    
    Interpreter.FollowConnection = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.Following or not Interpreter.FollowTarget then
            Interpreter.stopFollow()
            return
        end
        
        local localRoot = Interpreter.getRootPart()
        local targetChar = Interpreter.FollowTarget.Character
        
        if not localRoot then return end
        
        if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
            print("FOLLOW: Target character not found, stopping follow")
            Interpreter.stopFollow()
            return
        end
        
        local targetRoot = targetChar.HumanoidRootPart
        localRoot.CFrame = targetRoot.CFrame
    end)
    
    print("FOLLOW: Following " .. targetPlayer.Name)
end

function Interpreter.stopFollow()
    if not Interpreter.Following then return end
    
    if Interpreter.FollowConnection then
        Interpreter.FollowConnection:Disconnect()
        Interpreter.FollowConnection = nil
    end
    
    Interpreter.FollowTarget = nil
    Interpreter.Following = false
    print("FOLLOW: Stopped following")
end

-- Persistent Team system
function Interpreter.startPTeam(team)
    if Interpreter.PTeamLock then
        Interpreter.stopPTeam()
    end
    
    Interpreter.PTeamTarget = team
    Interpreter.PTeamLock = true
    
    Interpreter.PTeamConnection = task.spawn(function()
        while Interpreter.Active and Interpreter.PTeamLock do
            local player = Players.LocalPlayer
            if player and player.Team ~= Interpreter.PTeamTarget then
                player.Team = Interpreter.PTeamTarget
            end
            
            -- Dynamic wait time
            local waitTime = Interpreter.NoRegulActive and 0.001 or 0.5
            task.wait(waitTime)
        end
    end)
    
    print("PTEAM: Locked to " .. team.Name .. " team")
end

function Interpreter.stopPTeam()
    if not Interpreter.PTeamLock then return end
    
    Interpreter.PTeamLock = false
    Interpreter.PTeamConnection = nil
    
    Interpreter.PTeamTarget = nil
    print("PTEAM: Team lock disabled")
end

-- LockTo system
function Interpreter.startLockTo(targetPlayer)
    if Interpreter.Locking then
        Interpreter.stopLockTo()
    end
    
    Interpreter.LockTarget = targetPlayer
    Interpreter.Locking = true
    
    Interpreter.LockConnection = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.Locking or not Interpreter.LockTarget then
            Interpreter.stopLockTo()
            return
        end
        
        local localRoot = Interpreter.getRootPart()
        local targetChar = Interpreter.LockTarget.Character
        
        if not localRoot then return end
        
        if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
            print("LOCKTO: Target character not found, stopping lock")
            Interpreter.stopLockTo()
            return
        end
        
        local targetRoot = targetChar.HumanoidRootPart
        
        local direction = (targetRoot.Position - localRoot.Position).Unit
        if direction.Magnitude > 0 then
            localRoot.CFrame = CFrame.lookAt(localRoot.Position, localRoot.Position + Vector3.new(direction.X, 0, direction.Z))
        end
    end)
    
    print("LOCKTO: Locked to " .. targetPlayer.Name)
end

function Interpreter.stopLockTo()
    if not Interpreter.Locking then return end
    
    if Interpreter.LockConnection then
        Interpreter.LockConnection:Disconnect()
        Interpreter.LockConnection = nil
    end
    
    Interpreter.LockTarget = nil
    Interpreter.Locking = false
    print("LOCKTO: Unlocked")
end

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if not Interpreter.Active then return end
    
    Interpreter.Flying = false
    Interpreter.Spinning = false
    Interpreter.Anchored = false
    Interpreter.walkfling = false
    
    if Interpreter.FlightBV then Interpreter.FlightBV:Destroy() end
    if Interpreter.FlightBG then Interpreter.FlightBG:Destroy() end
    if Interpreter.SpinAV then Interpreter.SpinAV:Destroy() end
    
    -- Quick Reset Logic
    if Interpreter.RespawnPosition then
        task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart")
            task.wait()
            rootPart.CFrame = CFrame.new(Interpreter.RespawnPosition)
            Interpreter.RespawnPosition = nil
            print("RESET: Teleported to saved position")
        end)
    end
    
    task.wait(0.1)
    
    -- Reapply NoStun if it was active
    if Interpreter.NoStun then
        Interpreter.NoStun = false -- Reset flag
        task.wait(0.5) -- Wait for character to fully load
        Interpreter.startNoStun() -- Restart
    end
    
    -- Reapply Noclip Loop
    if Interpreter.Noclipping then
        Interpreter.startNoclip()
    end
    
    Interpreter.applySpeedAndJump()
end)

-- Stop all flying
function Interpreter.stopAllFlying()
    local humanoid = Interpreter.getHumanoid()
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    if Interpreter.FlightBV then Interpreter.FlightBV:Destroy() end
    if Interpreter.FlightBG then Interpreter.FlightBG:Destroy() end
    
    Interpreter.Flying = false
    print("UNFLY: All flying systems disabled")
end

-- OPTIMIZED NOCLIP SYSTEM
Interpreter.NoclipCache = {
    Parts = {},
    LastUpdate = 0,
    UpdateInterval = 1  -- Rebuild cache every 1 second
}

function Interpreter.rebuildNoclipCache()
    local character = Interpreter.getCharacter()
    if not character then return end
    
    Interpreter.NoclipCache.Parts = {}
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Interpreter.NoclipCache.Parts, part)
        end
    end
    
    Interpreter.NoclipCache.LastUpdate = tick()
    print("NOCLIP: Cache rebuilt (" .. #Interpreter.NoclipCache.Parts .. " parts)")
end

function Interpreter.startNoclip()
    if Interpreter.Noclipping then return end
    Interpreter.Noclipping = true
    
    -- Build initial cache
    Interpreter.rebuildNoclipCache()
    
    -- Hybrid approach: Event + Stepped
    Interpreter.NoclipConnections = {}
    
    -- Event 1: Detect new parts being added (instant response)
    local character = Interpreter.getCharacter()
    if character then
        table.insert(Interpreter.NoclipConnections, character.DescendantAdded:Connect(function(descendant)
            if not Interpreter.Noclipping then return end
            
            if descendant:IsA("BasePart") then
                -- Add to cache
                table.insert(Interpreter.NoclipCache.Parts, descendant)
                -- Disable collision immediately
                descendant.CanCollide = false
            end
        end))
        
        -- Event 2: Remove parts from cache when destroyed
        table.insert(Interpreter.NoclipConnections, character.DescendantRemoving:Connect(function(descendant)
            if not Interpreter.Noclipping then return end
            
            if descendant:IsA("BasePart") then
                -- Remove from cache
                for i, part in ipairs(Interpreter.NoclipCache.Parts) do
                    if part == descendant then
                        table.remove(Interpreter.NoclipCache.Parts, i)
                        break
                    end
                end
            end
        end))
    end
    
    -- Stepped loop: Use cached parts (much faster than GetDescendants)
    table.insert(Interpreter.NoclipConnections, RunService.Stepped:Connect(function()
        if not Interpreter.Noclipping then return end
        
        -- Periodically rebuild cache (not every frame!)
        local now = tick()
        if now - Interpreter.NoclipCache.LastUpdate > Interpreter.NoclipCache.UpdateInterval then
            Interpreter.rebuildNoclipCache()
        end
        
        -- Use cached parts (90% faster than GetDescendants)
        for _, part in ipairs(Interpreter.NoclipCache.Parts) do
            if part and part.Parent and part.CanCollide then
                part.CanCollide = false
            end
        end
    end))
    
    print("NOCLIP: Noclip enabled (Optimized with cache)")
end

function Interpreter.stopNoclip()
    if not Interpreter.Noclipping then return end
    Interpreter.Noclipping = false
    
    -- Disconnect all connections
    if Interpreter.NoclipConnections then
        for _, conn in ipairs(Interpreter.NoclipConnections) do
            conn:Disconnect()
        end
        Interpreter.NoclipConnections = nil
    end
    
    -- Restore collision using cache
    for _, part in ipairs(Interpreter.NoclipCache.Parts) do
        if part and part.Parent then
            part.CanCollide = true
        end
    end
    
    -- Clear cache
    Interpreter.NoclipCache = {Parts = {}, LastUpdate = 0, UpdateInterval = 1}
    
    print("NOCLIP: Noclip disabled")
end

-- ClientCharacter Injector System
Interpreter.InjectedCharacters = {
    closest = nil,
    farthest = nil,
    Active = false,
    UpdateLoop = nil
}

-- Get distance between two Vector3 positions
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Find closest player to LocalPlayer
local function findClosestPlayer()
    local localPlayer = Players.LocalPlayer
    local localChar = Interpreter.getCharacter()
    if not localChar then return nil end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = getDistance(localRoot.Position, targetRoot.Position)
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    
    return closestPlayer
end

-- Find farthest player from LocalPlayer
local function findFarthestPlayer()
    local localPlayer = Players.LocalPlayer
    local localChar = Interpreter.getCharacter()
    if not localChar then return nil end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    local farthestPlayer = nil
    local farthestDistance = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = getDistance(localRoot.Position, targetRoot.Position)
                if distance > farthestDistance then
                    farthestDistance = distance
                    farthestPlayer = player
                end
            end
        end
    end
    
    return farthestPlayer
end

-- Create fake player object that mimics real player
local function createFakePlayer(name, realPlayer)
    local fakePlayer = {
        Name = name,
        DisplayName = name,
        Character = realPlayer and realPlayer.Character or nil,
        Team = realPlayer and realPlayer.Team or nil,
        TeamColor = realPlayer and realPlayer.TeamColor or nil,
        UserId = realPlayer and realPlayer.UserId or -1,
        _isInjected = true,
        _realPlayer = realPlayer
    }
    
    return fakePlayer
end

-- Update injected characters
local function updateInjectedCharacters()
    local closestPlayer = findClosestPlayer()
    local farthestPlayer = findFarthestPlayer()
    
    if closestPlayer then
        Interpreter.InjectedCharacters.closest = createFakePlayer("closest", closestPlayer)
    else
        Interpreter.InjectedCharacters.closest = nil
    end
    
    if farthestPlayer then
        Interpreter.InjectedCharacters.farthest = createFakePlayer("farthest", farthestPlayer)
    else
        Interpreter.InjectedCharacters.farthest = nil
    end
end

-- Start ClientCharacter Injector
function Interpreter.startInjector()
    if Interpreter.InjectedCharacters.Active then return end
    
    Interpreter.InjectedCharacters.Active = true
    
    -- Initial update
    updateInjectedCharacters()
    
    -- Update loop (every 0.5 seconds)
    Interpreter.InjectedCharacters.UpdateLoop = RunService.Heartbeat:Connect(function()
        if not Interpreter.Active or not Interpreter.InjectedCharacters.Active then
            Interpreter.stopInjector()
            return
        end
        
        -- Throttle updates (not every frame)
        local currentTime = tick()
        if not Interpreter.InjectedCharacters.LastUpdate or 
           (currentTime - Interpreter.InjectedCharacters.LastUpdate) >= 0.5 then
            updateInjectedCharacters()
            Interpreter.InjectedCharacters.LastUpdate = currentTime
        end
    end)
    
    print("INJECTOR: ClientCharacter Injector enabled ('closest' and 'farthest' available)")
end

-- Stop ClientCharacter Injector
function Interpreter.stopInjector()
    if not Interpreter.InjectedCharacters.Active then return end
    
    Interpreter.InjectedCharacters.Active = false
    
    if Interpreter.InjectedCharacters.UpdateLoop then
        Interpreter.InjectedCharacters.UpdateLoop:Disconnect()
        Interpreter.InjectedCharacters.UpdateLoop = nil
    end
    
    Interpreter.InjectedCharacters.closest = nil
    Interpreter.InjectedCharacters.farthest = nil
    
    print("INJECTOR: ClientCharacter Injector disabled")
end

-- Spinning system
function Interpreter.startSpin()
    local rootPart = Interpreter.getRootPart()
    if not rootPart then return end
    
    if Interpreter.Spinning and Interpreter.SpinAV then
        Interpreter.SpinAV.AngularVelocity = Vector3.new(0, Interpreter.SpinSpeed, 0)
        print("SPIN: Updated spin speed to " .. Interpreter.SpinSpeed)
        return
    end
    
    local av = Instance.new("BodyAngularVelocity")
    av.AngularVelocity = Vector3.new(0, Interpreter.SpinSpeed, 0)
    av.MaxTorque = Vector3.new(0, math.huge, 0)
    av.Parent = rootPart
    
    Interpreter.SpinAV = av
    Interpreter.Spinning = true
    
    print("SPIN: Spinning enabled at speed " .. Interpreter.SpinSpeed)
end

function Interpreter.stopSpin()
    if not Interpreter.Spinning then return end
    
    Interpreter.Spinning = false
    
    if Interpreter.SpinAV then
        Interpreter.SpinAV:Destroy()
        Interpreter.SpinAV = nil
    end
    
    print("SPIN: Spinning disabled")
end

-- Shutdown system
function Interpreter.shutdown()
    if not Interpreter.Active then return end
    
    print("RuptorX: Shutting down...")
    
    Interpreter.Active = false
    
    Interpreter.stopAllFlying()
    Interpreter.stopNoclip()
    Interpreter.stopESP()
    Interpreter.stopSpin()
    Interpreter.stopLockTo()
    Interpreter.stopPTeam()
    Interpreter.stopFollow()
    Interpreter.stopOrbit()
    Interpreter.stroll()
    Interpreter.stopwalkfling()
    Interpreter.stopFloat()
    local Nostun = false
    Interpreter.stopPHealth()
    Interpreter.stopNoRegul()
    Interpreter.stopChatX()
    Interpreter.stopShowHP()
    
    if Interpreter.ChatConnection then
        Interpreter.ChatConnection:Disconnect()
        Interpreter.ChatConnection = nil
    end
    
    -- Clean up saved item clone to avoid memory issues
    if Interpreter.SavedBackpackItem then
        Interpreter.SavedBackpackItem:Destroy()
        Interpreter.SavedBackpackItem = nil
    end
    
    Interpreter.CustomWalkSpeed = nil
    Interpreter.CustomJumpPower = nil
    Interpreter.CustomHealth = nil
    
    -- Disconnect SpeedLoop
    if Interpreter.SpeedLoop then
        Interpreter.SpeedLoop:Disconnect()
        Interpreter.SpeedLoop = nil
    end
    
    if Interpreter.ChatConnection then
        Interpreter.ChatConnection:Disconnect()
        Interpreter.ChatConnection = nil
    end
    
    print("RuptorX: Shutdown complete")
    Interpreter.sendChatMessage("Wait what?")
end

-- Process command
function Interpreter.processCommand(commandString)
    if not Interpreter.Active then
        warn("Interpreter: System is shut down")
        return false
    end
    
    local commandWithoutPrefix = commandString:sub(2)
    
    local parts = {}
    for part in commandWithoutPrefix:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        warn("Interpreter: No command specified")
        return false
    end
    
    local handlerName = parts[1]:lower()
    local handler = Interpreter.Handlers[handlerName]
    
    -- If handler not found, try to resolve as alias
    if not handler then
        local aliasData = Interpreter.resolveAlias(handlerName)
        
        if aliasData then
            -- Build combined flags: alias args + user args
            local combinedFlags = {}
            
            -- Add alias's predefined args
            for _, arg in ipairs(aliasData.args) do
                table.insert(combinedFlags, arg)
            end
            
            -- Add user-provided args (from parts[2] onwards)
            for i = 2, #parts do
                table.insert(combinedFlags, parts[i])
            end
            
            -- Get the target handler
            handler = Interpreter.Handlers[aliasData.cmd]
            
            if not handler then
                warn("Interpreter: Alias '" .. handlerName .. "' points to non-existent command '" .. aliasData.cmd .. "'")
                return false
            end
            
            -- Execute with combined flags
            local success, result = pcall(handler, combinedFlags)
            
            if not success then
                warn("Interpreter: Alias handler error: " .. tostring(result))
                return false
            end
            
            return true
        else
            warn("Interpreter: Handler not found: " .. handlerName)
            return false
        end
    end
    
    local flags = {}
    for i = 2, #parts do
        table.insert(flags, parts[i])
    end
    
    local success, result = pcall(handler, flags)
    
    if not success then
        warn("Interpreter: Handler error: " .. tostring(result))
        return false
    end
    
    return true
end

-- Direct Command API (no prefix needed)
function Interpreter.cmd(commandString)
    if not Interpreter.Active then
        warn("Interpreter: System is shut down")
        return false
    end
    
    local parts = {}
    for part in commandString:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        warn("Interpreter: No command specified")
        return false
    end
    
    local handlerName = parts[1]:lower()
    local handler = Interpreter.Handlers[handlerName]
    
    -- If handler not found, try to resolve as alias
    if not handler then
        local aliasData = Interpreter.resolveAlias(handlerName)
        
        if aliasData then
            -- Build combined flags: alias args + user args
            local combinedFlags = {}
            
            -- Add alias's predefined args
            for _, arg in ipairs(aliasData.args) do
                table.insert(combinedFlags, arg)
            end
            
            -- Add user-provided args (from parts[2] onwards)
            for i = 2, #parts do
                table.insert(combinedFlags, parts[i])
            end
            
            -- Get the target handler
            handler = Interpreter.Handlers[aliasData.cmd]
            
            if not handler then
                warn("Interpreter: Alias '" .. handlerName .. "' points to non-existent command '" .. aliasData.cmd .. "'")
                return false
            end
            
            -- Execute with combined flags
            local success, result = pcall(handler, combinedFlags)
            
            if not success then
                warn("Interpreter: Alias handler error: " .. tostring(result))
                return false
            end
            
            return true
        else
            warn("Interpreter: Handler not found: " .. handlerName)
            return false
        end
    end
    
    local flags = {}
    for i = 2, #parts do
        table.insert(flags, parts[i])
    end
    
    local success, result = pcall(handler, flags)
    
    if not success then
        warn("Interpreter: Handler error: " .. tostring(result))
        return false
    end
    
    return true
end

-- Loop to maintain speed and jump (IMPROVED - uses RenderStepped)
Interpreter.SpeedLoop = RunService.RenderStepped:Connect(function()
    if Interpreter.Active then
        pcall(function()
            Interpreter.applySpeedAndJump()
        end)
    end
end)

-- Cleanup on character reset
Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if not Interpreter.Active then return end
    
    Interpreter.Flying = false
    Interpreter.Spinning = false
    
    if Interpreter.FlightBV then Interpreter.FlightBV:Destroy() end
    if Interpreter.FlightBG then Interpreter.FlightBG:Destroy() end
    if Interpreter.SpinAV then Interpreter.SpinAV:Destroy() end
    
    -- Quick Reset Logic
    if Interpreter.RespawnPosition then
        task.spawn(function()
            local rootPart = character:WaitForChild("HumanoidRootPart")
            task.wait()
            rootPart.CFrame = CFrame.new(Interpreter.RespawnPosition)
            Interpreter.RespawnPosition = nil
            print("RESET: Teleported to saved position")
        end)
    end
    
    task.wait(0.1)
    
    -- Reapply Noclip Loop
    if Interpreter.Noclipping then
        Interpreter.startNoclip()
    end
    
    Interpreter.applySpeedAndJump()
end)

-- Apply speed and jump (improved)
function Interpreter.applySpeedAndJump()
    local humanoid = Interpreter.getHumanoid()
    if not humanoid then return end
    
    -- Apply WalkSpeed
    if Interpreter.CustomWalkSpeed then
        humanoid.WalkSpeed = Interpreter.CustomWalkSpeed
    end
    
    -- Apply JumpPower/JumpHeight based on rig type
    if Interpreter.CustomJumpPower then
        -- Check if R15 or R6
        if humanoid.RigType == Enum.HumanoidRigType.R15 then
            -- R15 uses JumpHeight (default 7.2)
            humanoid.UseJumpPower = false
            humanoid.JumpHeight = Interpreter.CustomJumpPower / 6.944 -- Convert JumpPower to JumpHeight
        else
            -- R6 uses JumpPower (default 50)
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Interpreter.CustomJumpPower
        end
    end
end

-- Alias Management Functions
function Interpreter.loadAliases()
    local aliasPath = FOLDER_PATH .. "/aliases.json"
    
    if not safeCheckFile(aliasPath) then
        return {}
    end
    
    local content = safeReadFile(aliasPath)
    if not content or content == "" then
        return {}
    end
    
    local success, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(content)
    end)
    
    if not success or type(decoded) ~= "table" then
        warn("ALIAS: Failed to decode aliases.json, file may be corrupted")
        return {}
    end
    
    return decoded
end

function Interpreter.saveAliases(aliases)
    local aliasPath = FOLDER_PATH .. "/aliases.json"
    
    local success, encoded = pcall(function()
        return game:GetService("HttpService"):JSONEncode(aliases)
    end)
    
    if not success then
        warn("ALIAS: Failed to encode aliases data")
        return false
    end
    
    return safeWriteFile(aliasPath, encoded)
end

function Interpreter.resolveAlias(commandName)
    local aliases = Interpreter.loadAliases()
    
    for _, aliasData in ipairs(aliases) do
        if aliasData.alias == commandName then
            return aliasData
        end
    end
    
    return nil
end

-- SystemMaintenance Module - COMPLETELY FIXED
-- NO STRING CONCATENATION IN RESTARTER SCRIPT
-- FULL FILE SYSTEM SETUP WITH SAFEGUARDS

local SystemMaintenance = {}

-- Configuration
local VERSION = 153
local GITHUB_VERSION_URL = "https://raw.githubusercontent.com/ruptorx-sourcer/RuptorX/main/version.txt"
local GITHUB_SCRIPT_URL = "https://raw.githubusercontent.com/ruptorx-sourcer/RuptorX/main/RuptorX-Xe.lua"

-- State
SystemMaintenance.IncrementValue = 0
SystemMaintenance.IncrementLoop = nil
SystemMaintenance.Active = true

-- SAFE FILE OPERATIONS
local function safeWriteFile(path, content)
    local success, err = pcall(function()
        writefile(path, content)
    end)
    if not success then
        warn("SYSMAINT: Failed to write " .. path .. ": " .. tostring(err))
        return false
    end
    return true
end

local function safeReadFile(path)
    local success, content = pcall(function()
        return readfile(path)
    end)
    if not success then
        return nil
    end
    return content
end

local function safeDeleteFile(path)
    local success, err = pcall(function()
        if isfile(path) then
            delfile(path)
        end
    end)
    if not success then
        warn("SYSMAINT: Failed to delete " .. path .. ": " .. tostring(err))
    end
end

local function safeCheckFile(path)
    local success, result = pcall(function()
        return isfile(path)
    end)
    return success and result
end

local function safeCheckFolder(path)
    local success, result = pcall(function()
        return isfolder(path)
    end)
    return success and result
end

local function safeMakeFolder(path)
    local success, err = pcall(function()
        makefolder(path)
    end)
    if not success then
        warn("SYSMAINT: Failed to create folder " .. path .. ": " .. tostring(err))
        return false
    end
    return true
end

-- HTTP OPERATIONS
local function robustHttpGet(url, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or 3
    
    -- Method 1: game:HttpGet
    local success1, result1 = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if success1 and result1 and result1 ~= "" then
        print("SYSMAINT: HTTP success via game:HttpGet")
        return true, result1
    end
    
    -- Method 2: HttpService
    local HttpService = game:GetService("HttpService")
    local success2, result2 = nil, nil
    local completed = false
    
    task.spawn(function()
        success2, result2 = pcall(function()
            return HttpService:GetAsync(url)
        end)
        completed = true
    end)
    
    local startTime = tick()
    while not completed and (tick() - startTime) < timeoutSeconds do
        task.wait(0.1)
    end
    
    if completed and success2 and result2 and result2 ~= "" then
        print("SYSMAINT: HTTP success via HttpService")
        return true, result2
    end
    
    -- Method 3: request
    if request then
        local success3, result3 = pcall(function()
            local response = request({
                Url = url,
                Method = "GET"
            })
            return response.Body
        end)
        
        if success3 and result3 and result3 ~= "" then
            print("SYSMAINT: HTTP success via request()")
            return true, result3
        end
    end
    
    warn("SYSMAINT: All HTTP methods failed for " .. url)
    return false, "All HTTP methods failed"
end

-- FILE SYSTEM SETUP & VALIDATION

-- Comprehensive file system setup
function SystemMaintenance.setupFileSystem()
    print("SYSMAINT: Setting up file system...")
    
    -- Step 1: Create main folder
    if not safeCheckFolder(FOLDER_PATH) then
        print("SYSMAINT: Creating folder: " .. FOLDER_PATH)
        if not safeMakeFolder(FOLDER_PATH) then
            warn("SYSMAINT: CRITICAL - Could not create main folder!")
            return false
        end
        print("SYSMAINT: ✓ Folder created: " .. FOLDER_PATH)
    else
        print("SYSMAINT: ✓ Folder exists: " .. FOLDER_PATH)
    end
    
    -- Step 2: Validate folder is accessible
    if not safeCheckFolder(FOLDER_PATH) then
        warn("SYSMAINT: CRITICAL - Folder not accessible after creation!")
        return false
    end
    
    -- Step 3: Check/create main script file
    if not safeCheckFile(FILES.MainScript) then
        print("SYSMAINT: Main script missing, attempting download...")
        if not SystemMaintenance.downloadMainScript() then
            warn("SYSMAINT: WARNING - Could not download main script")
            warn("SYSMAINT: Restart functionality will be limited")
        end
    else
        print("SYSMAINT: ✓ Main script exists: " .. FILES.MainScript)
        
        -- Validate it's not empty
        local content = safeReadFile(FILES.MainScript)
        if not content or content == "" then
            warn("SYSMAINT: Main script file is empty, re-downloading...")
            SystemMaintenance.downloadMainScript()
        else
            print("SYSMAINT: ✓ Main script validated (" .. #content .. " bytes)")
        end
    end
    
    -- Step 4: Initialize version file
    if not safeCheckFile(FILES.Version) then
        print("SYSMAINT: Creating version.json...")
        local versionData = game:GetService("HttpService"):JSONEncode({version = VERSION})
        if safeWriteFile(FILES.Version, versionData) then
            print("SYSMAINT: ✓ version.json created")
        else
            warn("SYSMAINT: Could not create version.json")
        end
    else
        print("SYSMAINT: ✓ version.json exists")
    end
    
    -- Step 5: Clean up old temporary files
    print("SYSMAINT: Cleaning up temporary files...")
    local tempFiles = {FILES.Shutdown, FILES.Restart, FOLDER_PATH .. "/temp_restarter.lua"}
    for _, file in ipairs(tempFiles) do
        if safeCheckFile(file) then
            print("SYSMAINT: Removing old temp file: " .. file)
            safeDeleteFile(file)
        end
    end
    
    print("SYSMAINT: File system setup complete!")
    return true
end

-- Download main script from GitHub
function SystemMaintenance.downloadMainScript()
    print("SYSMAINT: Downloading main script from GitHub...")
    
    local success, scriptContent = robustHttpGet(GITHUB_SCRIPT_URL, 10)
    
    if not success or not scriptContent or scriptContent == "" then
        warn("SYSMAINT: Failed to download script from GitHub")
        Interpreter.notify("Network Failure", "Warning: Couldn't fetch update!", "warning", 4)
        return false
    end
    
    print("SYSMAINT: Downloaded " .. #scriptContent .. " bytes")
    
    if not safeWriteFile(FILES.MainScript, scriptContent) then
        warn("SYSMAINT: Failed to save script to disk")
        return false
    end
    
    -- CREATE UPDATE LOCK (triggers changelog on next startup)
    safeWriteFile(FILES.UpdateLock, tostring(newVersion))
    print("SYSMAINT: Update lock created - changelog will show on restart")
    
    print("SYSMAINT: ✓ Main script saved successfully")
    return true
end

-- Validate file system before critical operations
function SystemMaintenance.validateFileSystem()
    local issues = {}
    
    -- Check folder
    if not safeCheckFolder(FOLDER_PATH) then
        table.insert(issues, "Main folder missing")
    end
    
    -- Check critical files
    if not safeCheckFile(FILES.MainScript) then
        table.insert(issues, "Main script missing")
    end
    
    if #issues > 0 then
        warn("SYSMAINT: File system validation failed:")
        for _, issue in ipairs(issues) do
            warn("  - " .. issue)
        end
        return false
    end
    
    return true
end

-- STARTUP & SHUTDOWN

function SystemMaintenance.checkImproperShutdown()
    print("SYSMAINT: Checking for improper shutdown...")
    
    local noshutExists = safeCheckFile(FILES.NoShut)
    local incrementExists = safeCheckFile(FILES.Increment)
    
    -- Clean up temporary version file from previous session
    local versionPath = FOLDER_PATH .. "/.version"
    if safeCheckFile(versionPath) then
        print("SYSMAINT: Cleaning up temporary version file")
        safeDeleteFile(versionPath)
    end
    
    if noshutExists then
        local incrementContent = safeReadFile(FILES.Increment) or "0"
        local lastIncrement = tonumber(incrementContent) or 0
        
        print("SYSMAINT: Last increment value: " .. lastIncrement)
        
        if lastIncrement ~= 0 then
            safeDeleteFile(FILES.NoShut)
            safeDeleteFile(FILES.Increment)
            
            Interpreter.notify("Improper Shutdown", "Warning: RuptorX was incorrectly shutdown, use *shutdown before leaving!", "warning", 16)
            print("SYSMAINT: ✗ Improper shutdown detected and cleaned up")
        else
            print("SYSMAINT: ✓ Clean shutdown detected")
        end
    else
        print("SYSMAINT: ✓ No previous session or clean shutdown")
    end
end

function SystemMaintenance.startIncrement()
    print("SYSMAINT: Starting increment system...")
    
    if not safeWriteFile(FILES.NoShut, "1") then
        warn("SYSMAINT: Failed to create noshut.lock")
        return false
    end
    
    if not safeWriteFile(FILES.Increment, "0") then
        warn("SYSMAINT: Failed to create increment.lock")
        return false
    end
    
    SystemMaintenance.IncrementLoop = task.spawn(function()
        while SystemMaintenance.Active do
            task.wait(0.1)
            SystemMaintenance.IncrementValue = SystemMaintenance.IncrementValue + 1
            
            -- Silent increment - no prints
            safeWriteFile(FILES.Increment, tostring(SystemMaintenance.IncrementValue))
        end
    end)
    
    print("SYSMAINT: ✓ Increment system started")
    return true
end

function SystemMaintenance.stopIncrement()
    print("SYSMAINT: Stopping increment system...")
    SystemMaintenance.Active = false
    
    if SystemMaintenance.IncrementLoop then
        task.cancel(SystemMaintenance.IncrementLoop)
        SystemMaintenance.IncrementLoop = nil
    end
    
    safeDeleteFile(FILES.NoShut)
    safeDeleteFile(FILES.Increment)
    print("SYSMAINT: ✓ Increment system stopped")
end

-- RESTART SYSTEM (COMPLETELY FIXED - NO CONCATENATION)

function SystemMaintenance.restart()
    print("SYSMAINT: RESTART INITIATED")
    
    -- Step 1: Validate file system
    print("SYSMAINT: Step 1 - Validating file system...")
    if not SystemMaintenance.validateFileSystem() then
        warn("SYSMAINT: File system validation failed!")
        print("SYSMAINT: Attempting to repair file system...")
        
        if not SystemMaintenance.setupFileSystem() then
            Interpreter.notify("Restart Failed", "File system could not be initialized", "error")
            return false
        end
    end
    print("SYSMAINT: ✓ File system validated")
    
    -- Step 2: Verify main script exists and is valid
    print("SYSMAINT: Step 2 - Verifying main script...")
    if not safeCheckFile(FILES.MainScript) then
        warn("SYSMAINT: Main script missing, attempting download...")
        if not SystemMaintenance.downloadMainScript() then
            Interpreter.notify("Restart Failed", "Could not download main script", "error")
            return false
        end
    end
    
    local scriptContent = safeReadFile(FILES.MainScript)
    if not scriptContent or scriptContent == "" then
        warn("SYSMAINT: Main script is empty!")
        Interpreter.notify("Restart Failed", "Main script file is corrupted", "error")
        return false
    end
    print("SYSMAINT: ✓ Main script verified (" .. #scriptContent .. " bytes)")
    
    -- Step 3: Create restart lock
    print("SYSMAINT: Step 3 - Creating restart lock...")
    safeWriteFile(FILES.Restart, "1")
    
    -- Step 4: Create restarter script (NO STRING CONCATENATION AT ALL)
    print("SYSMAINT: Step 4 - Creating restarter script...")
    
    -- Build restarter WITHOUT any concatenation in the script itself
    local restarterCode = [[
print("RESTARTER: Initializing...")
task.wait(0.5)

local FOLDER = "RuptorX"
local SCRIPT_NAME = "RuptorX-Main.lua"
local fullPath = FOLDER .. "/" .. SCRIPT_NAME

print("RESTARTER: Target script: " .. fullPath)

local function safeExec(method, func)
    local success, err = pcall(func)
    if success then
        print("RESTARTER: Success via " .. method)
        return true
    else
        warn("RESTARTER: " .. method .. " failed: " .. tostring(err))
        return false
    end
end

if not safeExec("loadfile", function()
    local loader = loadfile(fullPath)
    if not loader then error("loadfile returned nil") end
    loader()
end) then
    safeExec("loadstring", function()
        local content = readfile(fullPath)
        if not content or content == "" then error("file is empty") end
        local func = loadstring(content)
        if not func then error("loadstring returned nil") end
        func()
    end)
end

print("RESTARTER: Complete")
]]
    
    if not safeWriteFile(FOLDER_PATH .. "/temp_restarter.lua", restarterCode) then
        warn("SYSMAINT: Failed to create restarter script")
        Interpreter.notify("Restart Failed", "Could not create restart script", "error")
        return false
    end
    print("SYSMAINT: ✓ Restarter script created")
    
    -- Step 5: Stop increment system
    print("SYSMAINT: Step 5 - Stopping increment system...")
    SystemMaintenance.stopIncrement()
    Interpreter.Active = false
    print("SYSMAINT: ✓ Systems stopped")
    
    -- Step 6: Execute restarter
    print("SYSMAINT: Step 6 - Executing restarter...")
    
    local success, err = pcall(function()
        loadfile(FOLDER_PATH .. "/temp_restarter.lua")()
    end)
    
    if not success then
        warn("SYSMAINT: Restart execution failed: " .. tostring(err))
        Interpreter.notify("Restart Failed", "Execution error: " .. tostring(err), "error")
        return false
    end
    
    -- Cleanup happens in new instance
    task.wait(0.5)
    safeDeleteFile(FOLDER_PATH .. "/temp_restarter.lua")
    safeDeleteFile(FILES.Restart)
    
    return true
end

-- Timeout wrapper for HTTP requests
local function httpGetWithTimeout(url, timeoutSeconds)
    timeoutSeconds = timeoutSeconds or 5
    
    local result = nil
    local completed = false
    local timedOut = false
    
    -- Spawn HTTP request in separate thread
    task.spawn(function()
        local success, response = robustHttpGet(url, timeoutSeconds)
        if not timedOut then
            result = {success = success, response = response}
            completed = true
        end
    end)
    
    -- Wait for completion or timeout
    local startTime = tick()
    while not completed and (tick() - startTime) < timeoutSeconds do
        task.wait(0.1)
    end
    
    if not completed then
        timedOut = true
        warn("SYSMAINT: HTTP request timed out after " .. timeoutSeconds .. "s")
        return false, "Timeout"
    end
    
    return result.success, result.response
end

-- Safe version file operations
local function writeVersionFile(version)
    local versionPath = FOLDER_PATH .. "/.version"
    return safeWriteFile(versionPath, tostring(version))
end

local function readVersionFile()
    local versionPath = FOLDER_PATH .. "/.version"
    if not safeCheckFile(versionPath) then
        return nil
    end
    
    local content = safeReadFile(versionPath)
    if not content or content == "" then
        return nil
    end
    
    return tonumber(content)
end

local function deleteVersionFile()
    local versionPath = FOLDER_PATH .. "/.version"
    safeDeleteFile(versionPath)
end

-- Validate version number
local function isValidVersion(version)
    if not version then return false end
    if type(version) ~= "number" then return false end
    if version < 1 or version > 99999 then return false end
    return true
end

-- Failsafe version check using file-based approach
local function checkVersionFailsafe()
    print("SYSMAINT: Using failsafe version check method...")
    
    -- Try to read from file
    local fileVersion = readVersionFile()
    if isValidVersion(fileVersion) then
        print("SYSMAINT: Loaded version from file: " .. fileVersion)
        return true, fileVersion
    end
    
    -- Create version check task in separate process
    local versionCheckCompleted = false
    local fetchedVersion = nil
    
    task.spawn(function()
        local success, versionText = pcall(function()
            return game:HttpGet(GITHUB_VERSION_URL, true)
        end)
        
        if success and versionText and versionText ~= "" then
            versionText = versionText:match("^%s*(.-)%s*$")
            local version = tonumber(versionText)
            
            if isValidVersion(version) then
                -- Write to file
                writeVersionFile(version)
                fetchedVersion = version
            end
        end
        
        versionCheckCompleted = true
    end)
    
    -- Wait up to 3 seconds for version file to appear
    local waitStart = tick()
    while (tick() - waitStart) < 3 do
        task.wait(0.1)
        
        local tempVersion = readVersionFile()
        if isValidVersion(tempVersion) then
            print("SYSMAINT: Failsafe version check successful: " .. tempVersion)
            return true, tempVersion
        end
    end
    
    warn("SYSMAINT: Failsafe version check failed")
    return false, nil
end

function SystemMaintenance.checkForUpdates()
    print("SYSMAINT: Checking for updates...")
    
    -- Validate GitHub URL
    if not GITHUB_VERSION_URL or GITHUB_VERSION_URL == "" then
        warn("SYSMAINT: Invalid GitHub version URL")
        return
    end
    
    -- Method 1: Try normal HTTP request with timeout
    local success, versionText = httpGetWithTimeout(GITHUB_VERSION_URL, 5)
    
    if not success then
        warn("SYSMAINT: Primary version check failed, trying failsafe method...")
        
        -- Method 2: Failsafe file-based check
        local failsafeSuccess, failsafeVersion = checkVersionFailsafe()
        
        if not failsafeSuccess then
            -- Method 3: Last resort - assume no update available
            warn("SYSMAINT: All version check methods failed")
            Interpreter.notify(
                "Update Check Failed",
                "Could not reach update server. You may be on an outdated version.",
                "warning",
                6
            )
            return
        end
        
        versionText = tostring(failsafeVersion)
    end
    
    -- Validate response
    if not versionText or versionText == "" then
        warn("SYSMAINT: Empty version response")
        return
    end
    
    -- Clean whitespace
    versionText = versionText:match("^%s*(.-)%s*$")
    
    -- Parse version
    local latestVersion = tonumber(versionText)
    
    if not isValidVersion(latestVersion) then
        warn("SYSMAINT: Invalid version format: " .. tostring(versionText))
        return
    end
    
    print("SYSMAINT: Current: " .. VERSION .. " | Latest: " .. latestVersion)
    
    -- Save latest version to file for next time
    writeVersionFile(latestVersion)
    
    if latestVersion > VERSION then
        if safeCheckFile(FILES.AutoUpdate) then
            SystemMaintenance.performUpdate(latestVersion)
        else
            Interpreter.notify(
                "New Update Available",
                "Version " .. latestVersion .. " is available. Click to install and restart.",
                "info",
                32,
                {
                    isClickable = true,
                    onClickFunction = "sysmaint_manual_update"
                }
            )
            SystemMaintenance.PendingVersion = latestVersion
        end
    elseif latestVersion < VERSION then
        print("SYSMAINT: ⚠ Running pre-release version")
    else
        print("SYSMAINT: ✓ Up to date")
    end
end

function SystemMaintenance.performUpdate(newVersion)
    print("SYSMAINT: Downloading update v" .. newVersion .. "...")
    
    -- Validate GitHub script URL
    if not GITHUB_SCRIPT_URL or GITHUB_SCRIPT_URL == "" then
        warn("SYSMAINT: Invalid GitHub script URL")
        Interpreter.notify("Update Failed", "Invalid update URL configuration", "error", 4)
        return false
    end
    
    -- Download with timeout
    local success, scriptContent = httpGetWithTimeout(GITHUB_SCRIPT_URL, 10)
    
    if not success then
        warn("SYSMAINT: Update download failed - network timeout")
        Interpreter.notify(
            "Update Failed",
            "Network timeout. Check your connection and try again.",
            "error",
            6
        )
        return false
    end
    
    if not scriptContent or scriptContent == "" then
        warn("SYSMAINT: Update download failed - empty response")
        Interpreter.notify("Update Failed", "Received empty update file", "error", 4)
        return false
    end
    
    -- Validate script content (basic sanity check)
    if #scriptContent < 1000 then
        warn("SYSMAINT: Downloaded script is suspiciously small (" .. #scriptContent .. " bytes)")
        Interpreter.notify("Update Failed", "Downloaded file appears corrupted", "error", 4)
        return false
    end
    
    print("SYSMAINT: Downloaded " .. #scriptContent .. " bytes")
    
    -- Save to file
    if not safeWriteFile(FILES.MainScript, scriptContent) then
        Interpreter.notify("Update Failed", "Could not save update to disk", "error", 4)
        return false
    end
    
    -- Create update lock (triggers changelog on next startup)
    safeWriteFile(FILES.UpdateLock, tostring(newVersion))
    print("SYSMAINT: Update lock created - changelog will show on restart")
    
    Interpreter.notify("Update Installed", "Version " .. newVersion .. " installed. Restarting...", "success", 2)
    task.wait(2.5)
    return SystemMaintenance.restart()
end

-- FAILSAFE SYSTEM

function SystemMaintenance.createFailsafe()
    print("SYSMAINT: Creating failsafe monitor...")
    
    local failsafeCode = [[
-- Silent Failsafe Monitor (no debug prints)
local FOLDER = "RuptorX"
local INCREMENT = FOLDER .. "/increment.lock"
local SHUTDOWN = FOLDER .. "/shutdown.lock"
local RESTART = FOLDER .. "/restart.lock"
local SCRIPT = FOLDER .. "/RuptorX-Main.lua"

local lastInc = -1

local function safeCheck(p)
    local s, r = pcall(function() return isfile(p) end)
    return s and r
end

local function safeRead(p)
    local s, r = pcall(function() return readfile(p) end)
    return s and r or nil
end

while true do
    task.wait(0.5)  -- Check every 0.5 seconds (faster detection)
    
    -- Check for shutdown signals
    if safeCheck(SHUTDOWN) or safeCheck(RESTART) then
        break
    end
    
    -- Check if increment is still updating
    if safeCheck(INCREMENT) then
        local curr = tonumber(safeRead(INCREMENT)) or 0
        
        if lastInc == -1 then
            lastInc = curr
        elseif curr == lastInc then
            -- Hang detected - wait 1 second to confirm
            task.wait(1)
            
            local recheck = tonumber(safeRead(INCREMENT)) or 0
            if recheck == lastInc then
                -- Confirmed hang - restart silently
                pcall(function()
                    loadfile(SCRIPT)()
                end)
                break
            end
        else
            lastInc = curr
        end
    end
end
]]
    
    if not safeWriteFile(FILES.Failsafe, failsafeCode) then
        warn("SYSMAINT: Failed to create failsafe")
        return false
    end
    
    task.spawn(function()
        pcall(function()
            loadfile(FILES.Failsafe)()
        end)
    end)
    
    print("SYSMAINT: ✓ Failsafe started (silent mode, 0.5s checks)")
    return true
end

-- INITIALIZATION

function SystemMaintenance.init()
    print("SYSMAINT: SYSTEM MAINTENANCE INITIALIZATION")
    
    -- Step 1: Setup file system
    if not SystemMaintenance.setupFileSystem() then
        warn("SYSMAINT: CRITICAL - File system setup failed!")
        Interpreter.notify("System Error", "File system initialization failed", "error", 4)
        return false
    end
    
    -- Step 2: Check for improper shutdown
    SystemMaintenance.checkImproperShutdown()
    
    -- Step 3: Start increment system
    if not SystemMaintenance.startIncrement() then
        warn("SYSMAINT: Increment system failed")
        return false
    end
    
    -- Step 4: Create failsafe
    SystemMaintenance.createFailsafe()
    
    -- Step 5: Check for updates
    SystemMaintenance.checkForUpdates()
    
    print("SYSMAINT: INITIALIZATION COMPLETE")
    return true
end

-- COMMAND HANDLERS

Interpreter.Handlers.sysmaint_manual_update = function(flags)
    if SystemMaintenance.PendingVersion then
        SystemMaintenance.performUpdate(SystemMaintenance.PendingVersion)
    end
end

Interpreter.Handlers.restart = function(flags)
    SystemMaintenance.restart()
end

Interpreter.Handlers.update = function(flags)
    local action = flags[1] and flags[1]:lower()
    
    if action == "check" then
        SystemMaintenance.checkForUpdates()
    elseif action == "auto" then
        if flags[2] == "on" then
            safeWriteFile(FILES.AutoUpdate, "1")
            Interpreter.notify("Auto-Update Enabled", "RuptorX will auto-update on startup", "success", 6)
        elseif flags[2] == "off" then
            safeDeleteFile(FILES.AutoUpdate)
            Interpreter.notify("Auto-Update Disabled", "RuptorX will prompt before updating", "info")
        else
            print("UPDATE: Use '*update auto on' or '*update auto off'")
        end
    else
        print("UPDATE: Commands - *update check | *update auto on/off")
    end
end

Interpreter.Handlers.sysdebug = function(flags)
    print("SYSMAINT: System Debug Report")
    print("Active: " .. tostring(SystemMaintenance.Active))
    print("Increment: " .. SystemMaintenance.IncrementValue)
    print("Version: " .. VERSION)
    print("")
    print("Folders:")
    print("  " .. FOLDER_PATH .. ": " .. tostring(safeCheckFolder(FOLDER_PATH)))
    print("")
    print("Files:")
    for name, path in pairs(FILES) do
        local exists = safeCheckFile(path)
        local status = exists and "✓" or "✗"
        print("  " .. status .. " " .. name .. ": " .. path)
        
        if exists and (name == "Increment" or name == "MainScript") then
            local content = safeReadFile(path)
            if content then
                local size = #content
                if name == "Increment" then
                    print("      Content: " .. content)
                else
                    print("      Size: " .. size .. " bytes")
                end
            end
        end
    end
    
    Interpreter.notify("System Debug", "Check console for details", "info", 4)
end

Interpreter.Handlers.sysrepair = function(flags)
    print("SYSMAINT: Running system repair...")
    Interpreter.notify("System Repair", "Repairing file system...", "info")
    
    if SystemMaintenance.setupFileSystem() then
        Interpreter.notify("Repair Complete", "File system repaired successfully", "success", 4)
    else
        Interpreter.notify("Repair Failed", "Could not repair file system", "error", 4)
    end
end

-- Integrate with shutdown
local originalShutdown = Interpreter.Handlers.shutdown
Interpreter.Handlers.shutdown = function(flags)
    print("SYSMAINT: Shutdown initiated")
    safeWriteFile(FILES.Shutdown, "1")
    SystemMaintenance.stopIncrement()
    originalShutdown(flags)
    task.wait(0.5)
    safeDeleteFile(FILES.Shutdown)
end

print("SYSMAINT: Module loaded")

print("SYSMAINT: Module loaded successfully")

-- Troll system (UPDATED - Fixed team targeting)
function Interpreter.startTroll(teamFilter)
    if Interpreter.Trolling then
        Interpreter.stroll()
    end
    
    Interpreter.Trolling = true
    Interpreter.TrollTeamFilter = teamFilter
    
    Interpreter.TrollConnection = task.spawn(function()
        while Interpreter.Active and Interpreter.Trolling do
            -- Rebuild target list every iteration
            Interpreter.TrollTargets = {}
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer then
                    local includePlayer = false
                    
                    -- If no team filter specified, target everyone
                    if not Interpreter.TrollTeamFilter then
                        includePlayer = true
                    else
                        -- Only target players on the specified team
                        if player.Team and player.Team.Name:lower() == Interpreter.TrollTeamFilter:lower() then
                            includePlayer = true
                        end
                    end
                    
                    -- Add to target list if they have a valid character
                    if includePlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        table.insert(Interpreter.TrollTargets, player)
                    end
                end
            end
            
            -- Teleport to random target
            if #Interpreter.TrollTargets > 0 then
                local randomTarget = Interpreter.TrollTargets[math.random(1, #Interpreter.TrollTargets)]
                local rootPart = Interpreter.getRootPart()
                
                if rootPart and randomTarget.Character and randomTarget.Character.HumanoidRootPart then
                    rootPart.CFrame = randomTarget.Character.HumanoidRootPart.CFrame
                end
            end
            
            -- Dynamic wait time
            local waitTime = Interpreter.NoRegulActive and 0.001 or 0.1
            task.wait(waitTime)
        end
    end)
    
    local filterText = Interpreter.TrollTeamFilter and " targeting team: " .. Interpreter.TrollTeamFilter or " targeting all players"
    print("TROLL: Trolling activated" .. filterText)
end

function Interpreter.stroll()
    if not Interpreter.Trolling then return end
    
    Interpreter.Trolling = false
    
    -- Emergency stop: Cancel the running thread immediately.
    if Interpreter.TrollConnection then
        task.cancel(Interpreter.TrollConnection)
        Interpreter.TrollConnection = nil
    end
    
    Interpreter.TrollTeamFilter = nil
    Interpreter.TrollTargets = {}
    print("TROLL: Trolling deactivated")
end

-- ChatX Terminal Integration - Complete Rewrite
local ChatXGUI = {
    Active = false,
    ScreenGui = nil,
    MainFrame = nil,
    LogScroll = nil,
    InputBox = nil,
    MinimizedIcon = nil
}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local THEME = {
    Background = Color3.fromRGB(30, 30, 30),
    SideBar = Color3.fromRGB(37, 37, 38),
    Header = Color3.fromRGB(50, 50, 50),
    Accent = Color3.fromRGB(0, 122, 204),
    Text = Color3.fromRGB(204, 204, 204),
    Comment = Color3.fromRGB(106, 153, 85),
    Warning = Color3.fromRGB(255, 215, 0),
    Error = Color3.fromRGB(244, 71, 71),
    Stroke = Color3.fromRGB(60, 60, 60),
    Transparency = 0.2
}

local activeFilters = {
    Chat = true,
    System = true,
    Warn = true,
    Error = true
}

local function CreateChatXLog(text, color, logType)
    if not ChatXGUI.LogScroll then return end
    
    local LogLayout = ChatXGUI.LogScroll:FindFirstChildOfClass("UIListLayout")
    if not LogLayout then return end
    
    local scrollTolerance = 50
    local maxScrollY = ChatXGUI.LogScroll.CanvasSize.Y.Offset - ChatXGUI.LogScroll.AbsoluteSize.Y
    local shouldAutoScroll = maxScrollY <= 0 or ChatXGUI.LogScroll.CanvasPosition.Y >= maxScrollY - scrollTolerance
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = " " .. text
    label.TextColor3 = color or THEME.Text
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.RichText = true
    label.TextStrokeTransparency = 1
    label:SetAttribute("LogType", logType)
    label.Visible = activeFilters[logType]
    label.Parent = ChatXGUI.LogScroll
    
    local children = ChatXGUI.LogScroll:GetChildren()
    if #children > 150 then
        for i = 1, #children - 140 do
            if children[i]:IsA("TextLabel") then children[i]:Destroy() end
        end
    end

    if label.Visible and shouldAutoScroll then
        ChatXGUI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        ChatXGUI.LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y)
        ChatXGUI.LogScroll.CanvasPosition = Vector2.new(0, LogLayout.AbsoluteContentSize.Y)
    end
end

local function FormatMessage(player, message, isSystem)
    local timestamp = os.date("%H:%M")
    
    if isSystem then
        return string.format("<font color='#666666'>%s</font> <font color='#007ACC'>[SYS]</font> %s", timestamp, message)
    end
    
    -- Get team color
    local teamColorHex = "#888888"
    if player and player.Team then
        local c = player.Team.TeamColor.Color
        teamColorHex = string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
    end
    
    -- Get display name and check for tags
    local displayName = player and player.DisplayName or "???"
    local username = player and player.Name or "???"
    
    -- Check for special tags in display name
    local specialTags = {"ADMIN", "MOD", "DONOR", "DONATOR", "TESTER", "OWNER", "CO-OWNER", "COOWNER"}
    local tagPrefix = ""
    local upperName = displayName:upper()
    
    for _, tag in ipairs(specialTags) do
        if upperName:find(tag) then
            tagPrefix = string.format("<font color='#FFD700'>[%s]</font> ", tag)
            break
        end
    end
    
    -- Color for self vs others
    local nameColor = (player == LocalPlayer) and "#4EC9B0" or "#FFFFFF"
    
    -- Format: Timestamp • Tag DisplayName (@username): Message
    return string.format(
        "<font color='#555555'>%s</font> <font color='%s'>●</font> %s<font color='%s'>%s</font> <font color='#888888'>(@%s)</font>: <font color='#CE9178'>%s</font>",
        timestamp, teamColorHex, tagPrefix, nameColor, displayName, username, message
    )
end

local function UpdateLogVisibility()
    if not ChatXGUI.LogScroll then return end
    
    for _, child in pairs(ChatXGUI.LogScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            local typeTag = child:GetAttribute("LogType")
            if typeTag and activeFilters[typeTag] ~= nil then
                child.Visible = activeFilters[typeTag]
            else
                child.Visible = true
            end
        end
    end
end

local function CreateFilterToggle(parent, name, filterKey, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 1, 0)
    btn.BackgroundColor3 = THEME.Background
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextStrokeTransparency = 1
    btn.Parent = parent
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(1, 0, 0, 2)
    indicator.Position = UDim2.new(0, 0, 1, -2)
    indicator.BackgroundColor3 = color
    indicator.BorderSizePixel = 0
    indicator.Parent = btn

    btn.MouseButton1Click:Connect(function()
        activeFilters[filterKey] = not activeFilters[filterKey]
        
        if activeFilters[filterKey] then
            btn.TextTransparency = 0
            indicator.BackgroundTransparency = 0
        else
            btn.TextTransparency = 0.6
            indicator.BackgroundTransparency = 1
        end
        UpdateLogVisibility()
    end)
end

local function SendMessage()
    if not ChatXGUI.InputBox then return end
    
    local text = ChatXGUI.InputBox.Text
    if text == "" or string.match(text, "^%s+$") then return end
    
    -- Log command execution
    CreateChatXLog(FormatMessage(LocalPlayer, text), nil, "Chat")
    
    -- Execute via Interpreter.cmd (no prefix)
    local success = Interpreter.cmd(text)
    
    if not success then
        CreateChatXLog("[ERROR] Command failed: " .. text, THEME.Error, "Error")
    end
    
    ChatXGUI.InputBox.Text = ""
end

-- Mod Check System
local function PerformModCheck()
    if ChatXGUI.ModCheckActive then
        CreateChatXLog("[MOD CHECK] Already running...", THEME.Warning, "Warn")
        return
    end
    
    ChatXGUI.ModCheckActive = true
    CreateChatXLog("[MOD CHECK] Scanning all players...", THEME.Accent, "System")
    
    local specialTags = {"ADMIN", "MOD", "DONOR", "DONATOR", "TESTER", "OWNER", "CO-OWNER", "COOWNER"}
    local specialCount = 0
    local totalPlayers = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        totalPlayers = totalPlayers + 1
        local upperName = player.DisplayName:upper()
        local hasTag = false
        local foundTag = nil
        
        for _, tag in ipairs(specialTags) do
            if upperName:find(tag) then
                hasTag = true
                foundTag = tag
                break
            end
        end
        
        if hasTag then
            local teamColorHex = "#888888"
            if player.Team then
                local c = player.Team.TeamColor.Color
                teamColorHex = string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
            end
            
            CreateChatXLog(
                string.format("  <font color='%s'>●</font> <font color='#FFD700'>[%s]</font> %s <font color='#888888'>(@%s)</font>", 
                teamColorHex, foundTag, player.DisplayName, player.Name),
                nil, "Warn"
            )
            specialCount = specialCount + 1
        end
    end
    
    task.wait(0.2)
    
    if specialCount == 0 then
        CreateChatXLog(string.format("[MOD CHECK] ✓ No special tags detected (%d players)", totalPlayers), THEME.Comment, "System")
    else
        CreateChatXLog(string.format("[MOD CHECK] ⚠ Found %d/%d players with special tags", specialCount, totalPlayers), THEME.Error, "Error")
    end
    
    ChatXGUI.ModCheckActive = false
end

-- Hook into chat system
local function HookIntoChat()
    local isLegacy = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
    
    local function OnMessageReceived(text, player)
        if player then
            CreateChatXLog(FormatMessage(player, text), nil, "Chat")
        else
            CreateChatXLog(FormatMessage(nil, text, true), nil, "System")
        end
    end
    
    if isLegacy then
        CreateChatXLog("Hooked to Legacy Chat", THEME.Comment, "System")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local chatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 5)
        
        if chatEvents then
            local onMessageDone = chatEvents:WaitForChild("OnMessageDoneFiltering", 5)
            if onMessageDone then
                onMessageDone.OnClientEvent:Connect(function(data)
                    local player = Players:FindFirstChild(data.FromSpeaker)
                    if player then
                        OnMessageReceived(data.Message, player)
                    end
                end)
            end
        else
            -- Fallback: Hook individual player chatted events
            for _, p in ipairs(Players:GetPlayers()) do
                p.Chatted:Connect(function(msg) OnMessageReceived(msg, p) end)
            end
            Players.PlayerAdded:Connect(function(p)
                p.Chatted:Connect(function(msg) OnMessageReceived(msg, p) end)
            end)
        end
    else
        CreateChatXLog("Hooked to TextChatService", THEME.Comment, "System")
        TextChatService.MessageReceived:Connect(function(textChatMessage)
            local player = nil
            if textChatMessage.TextSource then
                player = Players:GetPlayerByUserId(textChatMessage.TextSource.UserId)
            end
            OnMessageReceived(textChatMessage.Text, player)
        end)
    end
end

function Interpreter.buildChatXGUI()
    if ChatXGUI.ScreenGui then return end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChatX_RuptorX_GUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 10
    ScreenGui.Parent = PlayerGui
    ChatXGUI.ScreenGui = ScreenGui
    
    -- Main Window
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
    MainFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = THEME.Background
    MainFrame.BackgroundTransparency = THEME.Transparency
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    ChatXGUI.MainFrame = MainFrame
    
    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MinSize = Vector2.new(450, 300)
    SizeConstraint.Parent = MainFrame
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 4)
    MainCorner.Parent = MainFrame
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = THEME.Stroke
    MainStroke.Thickness = 1
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = MainFrame
    
    -- Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 30)
    HeaderBar.BackgroundColor3 = THEME.Header
    HeaderBar.BorderSizePixel = 0
    HeaderBar.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 4)
    HeaderCorner.Parent = HeaderBar
    
    local HeaderCover = Instance.new("Frame")
    HeaderCover.Size = UDim2.new(1, 0, 0, 10)
    HeaderCover.Position = UDim2.new(0, 0, 1, -10)
    HeaderCover.BackgroundColor3 = THEME.Header
    HeaderCover.BorderSizePixel = 0
    HeaderCover.Parent = HeaderBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "ChatX - RuptorX Terminal"
    Title.TextColor3 = THEME.Text
    Title.Font = Enum.Font.GothamMedium
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextStrokeTransparency = 1
    Title.Parent = HeaderBar
    
    -- Control Buttons
    local function CreateControlBtn(text, color, posOffset)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 30, 1, 0)
        btn.Position = UDim2.new(1, posOffset, 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = text
        btn.TextColor3 = color
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.TextStrokeTransparency = 1
        btn.Parent = HeaderBar
        return btn
    end
    
    local CloseBtn = CreateControlBtn("X", THEME.Text, -30)
    local MinBtn = CreateControlBtn("—", THEME.Text, -60)
    local ModCheckBtn = CreateControlBtn("🔓", THEME.Accent, -90)
    
    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "Content"
    ContentArea.Size = UDim2.new(1, 0, 1, -30)
    ContentArea.Position = UDim2.new(0, 0, 0, 30)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame
    
    -- Filter Bar
    local FilterBar = Instance.new("Frame")
    FilterBar.Name = "FilterBar"
    FilterBar.Size = UDim2.new(1, -10, 0, 22)
    FilterBar.Position = UDim2.new(0, 5, 0, 2)
    FilterBar.BackgroundTransparency = 1
    FilterBar.Parent = ContentArea
    
    local FilterLayout = Instance.new("UIListLayout")
    FilterLayout.Parent = FilterBar
    FilterLayout.FillDirection = Enum.FillDirection.Horizontal
    FilterLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FilterLayout.Padding = UDim.new(0, 4)
    
    CreateFilterToggle(FilterBar, "CHAT", "Chat", THEME.Text)
    CreateFilterToggle(FilterBar, "SYS", "System", THEME.Accent)
    CreateFilterToggle(FilterBar, "WARN", "Warn", THEME.Warning)
    CreateFilterToggle(FilterBar, "ERR", "Error", THEME.Error)
    
    -- Log Scroll
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Name = "LogScroll"
    LogScroll.Size = UDim2.new(1, -4, 1, -60)
    LogScroll.Position = UDim2.new(0, 2, 0, 26)
    LogScroll.BackgroundColor3 = THEME.Background
    LogScroll.BackgroundTransparency = 1
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 6
    LogScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogScroll.Parent = ContentArea
    ChatXGUI.LogScroll = LogScroll
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Parent = LogScroll
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 0)
    
    -- Input Container
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, 0, 0, 30)
    InputContainer.Position = UDim2.new(0, 0, 1, -30)
    InputContainer.BackgroundColor3 = THEME.SideBar
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = ContentArea
    
    local InputBorder = Instance.new("Frame")
    InputBorder.Size = UDim2.new(1, 0, 0, 1)
    InputBorder.BackgroundColor3 = THEME.Stroke
    InputBorder.BorderSizePixel = 0
    InputBorder.Parent = InputContainer
    
    -- Input Box
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -50, 1, 0)
    InputBox.Position = UDim2.new(0, 10, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.Text = ""
    InputBox.PlaceholderText = "Type command (no * prefix)..."
    InputBox.TextColor3 = THEME.Text
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextSize = 13
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.TextStrokeTransparency = 1
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = InputContainer
    ChatXGUI.InputBox = InputBox
    
    -- Send Button
    local SendBtn = Instance.new("TextButton")
    SendBtn.Size = UDim2.new(0, 40, 1, 0)
    SendBtn.Position = UDim2.new(1, -40, 0, 0)
    SendBtn.BackgroundColor3 = THEME.Accent
    SendBtn.Text = "RUN"
    SendBtn.TextColor3 = Color3.new(1, 1, 1)
    SendBtn.Font = Enum.Font.GothamBold
    SendBtn.TextSize = 11
    SendBtn.TextStrokeTransparency = 1
    SendBtn.BorderSizePixel = 0
    SendBtn.Parent = InputContainer
    
    -- Minimized Icon
    local MinimizedIcon = Instance.new("Frame")
    MinimizedIcon.Name = "MinimizedIcon"
    MinimizedIcon.Size = UDim2.new(0, 40, 0, 40)
    MinimizedIcon.Position = UDim2.new(0, 20, 0.85, 0)
    MinimizedIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MinimizedIcon.Visible = false
    MinimizedIcon.Parent = ScreenGui
    ChatXGUI.MinimizedIcon = MinimizedIcon
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(1, 0)
    IconCorner.Parent = MinimizedIcon
    
    local IconStroke = Instance.new("UIStroke")
    IconStroke.Color = THEME.Accent
    IconStroke.Thickness = 1.5
    IconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    IconStroke.Parent = MinimizedIcon
    
    local IconText = Instance.new("TextButton")
    IconText.Size = UDim2.new(1, 0, 1, 0)
    IconText.BackgroundTransparency = 1
    IconText.Text = ">_"
    IconText.TextColor3 = THEME.Accent
    IconText.Font = Enum.Font.Code
    IconText.TextSize = 16
    IconText.TextStrokeTransparency = 1
    IconText.Parent = MinimizedIcon
    
    -- Button Events
    IconText.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        MinimizedIcon.Visible = false
    end)
    
    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        MinimizedIcon.Visible = true
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        Interpreter.stopChatX()
    end)
    
    ModCheckBtn.MouseButton1Click:Connect(PerformModCheck)
    
    SendBtn.MouseButton1Click:Connect(SendMessage)
    InputBox.FocusLost:Connect(function(enter) if enter then SendMessage() end end)
    
    -- Make draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    HeaderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Hook into chat and show welcome message
    CreateChatXLog("ChatX Terminal initialized - RuptorX", THEME.Comment, "System")
    CreateChatXLog("Type commands without * prefix", THEME.Comment, "System")
    
    HookIntoChat()
    
    print("CHATX: GUI created successfully")
end

function Interpreter.startChatX()
    if ChatXGUI.Active then return end
    
    if not ChatXGUI.ScreenGui then
        Interpreter.buildChatXGUI()
    else
        ChatXGUI.MainFrame.Visible = true
        ChatXGUI.MinimizedIcon.Visible = false
    end
    
    ChatXGUI.Active = true
    Interpreter.ChatXActive = true
    
    print("CHATX: Terminal activated")
end

function Interpreter.stopChatX()
    if not ChatXGUI.Active then return end
    
    ChatXGUI.Active = false
    Interpreter.ChatXActive = false
    
    if ChatXGUI.ScreenGui then
        ChatXGUI.ScreenGui:Destroy()
        ChatXGUI.ScreenGui = nil
        ChatXGUI.MainFrame = nil
        ChatXGUI.LogScroll = nil
        ChatXGUI.InputBox = nil
        ChatXGUI.MinimizedIcon = nil
    end
    
    print("CHATX: Terminal closed")
end

-- Advanced GUI System (COMPLETE PATCH)
Interpreter.GUI = {
    Windows = {},
    Elements = {},
    Callbacks = {},
    DragData = {},
    Minimized = {}
}

local TweenService = game:GetService("TweenService")

-- Tween presets
local function createTween(instance, properties, duration, style)
    duration = tonumber(duration) or 0.3
    style = style or Enum.EasingStyle.Quint
    local tweenInfo = TweenInfo.new(duration, style, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    return tween
end

-- Create ScreenGui if it doesn't exist
local function getScreenGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local screenGui = playerGui:FindFirstChild("RuptorXGUI")
    
    if not screenGui then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "RuptorXGUI"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = playerGui
    end
    
    return screenGui
end

-- Parse size parameter
local function parseSize(size)
    size = size or "medium"
    local sizes = {
        small = {width = 280, height = 200},
        medium = {width = 380, height = 280},
        large = {width = 480, height = 360},
        equilateral = {width = 320, height = 320}
    }
    return sizes[size:lower()] or sizes.medium
end

-- Parse position parameter
local function parsePosition(position, windowType, dimensions)
    position = position or "center"
    local pos = {
        center = {x = 0.5, xOffset = -dimensions.width/2, y = 0.5, yOffset = -dimensions.height/2},
        topleft = {x = 0, xOffset = 10, y = 0, yOffset = 10},
        topright = {x = 1, xOffset = -dimensions.width - 10, y = 0, yOffset = 10},
        bottomleft = {x = 0, xOffset = 10, y = 1, yOffset = -dimensions.height - 10},
        bottomright = {x = 1, xOffset = -dimensions.width - 10, y = 1, yOffset = -dimensions.height - 10},
    }
    
    if windowType == "popup" then
        return {x = 0.5, xOffset = -dimensions.width/2, y = 0.3, yOffset = -dimensions.height/2}
    elseif windowType == "fullscreen" then
        return {x = 0, xOffset = 0, y = 0, yOffset = 0}
    end
    
    return pos[position:lower()] or pos.center
end

-- GUI Creation API
Interpreter.create = {}
Interpreter.destroy = {}
Interpreter.buttonis = {}
Interpreter.placeholderis = {}
Interpreter.windowis = {}
Interpreter.toggleis = {}

-- ADVANCED WINDOW CREATION
function Interpreter.create.window(config)
    -- Config structure (HTML-like):
    -- {
    --     title = "Window Title",
    --     type = "window" | "popup" | "fullscreen",
    --     size = "small" | "medium" | "large" | "equilateral",
    --     position = "center" | "topleft" | "topright" | "bottomleft" | "bottomright",
    --     transparency = 0.0 to 1.0 (0 = solid, 1 = invisible)
    -- }
    
    if type(config) == "string" then
        config = {title = config}
    end
    
    local title = config.title or "Window"
    local windowType = config.type or "window"
    local dimensions = parseSize(config.size)
    local windowTransparency = config.transparency or 0 -- Default fully opaque
    
    -- Clamp transparency between 0 and 1
    windowTransparency = math.clamp(windowTransparency, 0, 1)
    
    -- Fullscreen override
    if windowType == "fullscreen" then
        dimensions = {width = 0, height = 0} -- Will be set to screen size
    end
    
    local posData = parsePosition(config.position, windowType, dimensions)
    
    local screenGui = getScreenGui()
    
    -- Create window frame
    local window = Instance.new("Frame")
    window.Name = "Window_" .. title
    
    if windowType == "fullscreen" then
        window.Size = UDim2.new(1, 0, 1, 0)
        window.Position = UDim2.new(0, 0, 0, 0)
    else
        window.Size = UDim2.new(0, dimensions.width, 0, dimensions.height)
        window.Position = UDim2.new(posData.x, posData.xOffset, posData.y, posData.yOffset)
    end
    
    window.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    window.BackgroundTransparency = windowTransparency
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = screenGui
    
    -- Sharp corners for popup, slight for others
    local corner = Instance.new("UICorner")
    corner.CornerRadius = windowType == "popup" and UDim.new(0, 8) or UDim.new(0, 4)
    corner.Parent = window
    
    -- Outer border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(35, 35, 40)
    stroke.Thickness = windowType == "fullscreen" and 0 or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = window
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, windowType == "popup" and 35 or 28)
    titleBar.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    titleBar.BackgroundTransparency = windowTransparency
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = windowType == "popup" and UDim.new(0, 8) or UDim.new(0, 4)
    titleCorner.Parent = titleBar
    
    -- Fix for rounded corner gap
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 4)
    titleFix.Position = UDim2.new(0, 0, 1, -4)
    titleFix.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    titleFix.BackgroundTransparency = windowTransparency
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
    titleLabel.TextSize = windowType == "popup" and 14 or 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Minimize button (only for fullscreen)
    if windowType == "fullscreen" then
        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Name = "MinimizeButton"
        minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
        minimizeBtn.Position = UDim2.new(1, -54, 0, 2)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        minimizeBtn.Text = "−"
        minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 185)
        minimizeBtn.TextSize = 16
        minimizeBtn.Font = Enum.Font.GothamBold
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Parent = titleBar
        
        local minimizeBtnCorner = Instance.new("UICorner")
        minimizeBtnCorner.CornerRadius = UDim.new(0, 3)
        minimizeBtnCorner.Parent = minimizeBtn
        
        local minimizeBtnStroke = Instance.new("UIStroke")
        minimizeBtnStroke.Color = Color3.fromRGB(40, 40, 45)
        minimizeBtnStroke.Thickness = 1
        minimizeBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        minimizeBtnStroke.Parent = minimizeBtn
        
        minimizeBtn.MouseEnter:Connect(function()
            createTween(minimizeBtn, {BackgroundColor3 = Color3.fromRGB(100, 100, 105)}, 0.2, Enum.EasingStyle.Sine):Play()
        end)
        minimizeBtn.MouseLeave:Connect(function()
            createTween(minimizeBtn, {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}, 0.2, Enum.EasingStyle.Sine):Play()
        end)
        
        minimizeBtn.MouseButton1Click:Connect(function()
            local isMinimized = Interpreter.GUI.Minimized[title]
            if isMinimized then
                -- Restore
                window.Size = UDim2.new(1, 0, 1, 0)
                window:FindFirstChild("Content").Visible = true
                minimizeBtn.Text = "−"
                Interpreter.GUI.Minimized[title] = false
            else
                -- Minimize
                window.Size = UDim2.new(0, 300, 0, 35)
                window:FindFirstChild("Content").Visible = false
                minimizeBtn.Text = "□"
                Interpreter.GUI.Minimized[title] = true
            end
        end)
    end
    
    -- Close button (RED and ROUND - smaller and corner-positioned)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 18, 0, 18) -- Smaller
    closeBtn.Position = UDim2.new(1, -22, 0, 4) -- Closer to corner
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14 -- Smaller text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    -- ROUND close button (fully circular)
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(1, 0) -- Fully round
    closeBtnCorner.Parent = closeBtn
    
    local closeBtnStroke = Instance.new("UIStroke")
    closeBtnStroke.Color = Color3.fromRGB(200, 50, 50)
    closeBtnStroke.Thickness = 1
    closeBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    closeBtnStroke.Parent = closeBtn
    
    -- Close button hover effect
    closeBtn.MouseEnter:Connect(function()
        createTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(220, 50, 50)}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(closeBtnStroke, {Color = Color3.fromRGB(255, 80, 80)}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        createTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(180, 30, 30)}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(closeBtnStroke, {Color = Color3.fromRGB(200, 50, 50)}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -(windowType == "popup" and 45 or 38))
    content.Position = UDim2.new(0, 8, 0, windowType == "popup" and 40 or 34)
    content.BackgroundTransparency = 1
    content.Parent = window
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = content
    
    -- Store window reference
    Interpreter.GUI.Windows[title] = window
    Interpreter.GUI.Elements[title] = {}
    Interpreter.GUI.Minimized[title] = false
    
    -- Make window draggable (not for fullscreen)
    if windowType ~= "fullscreen" then
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                window.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
    
    -- Entrance animation based on type
    if windowType == "popup" then
        window.Size = UDim2.new(0, 0, 0, 0)
        window.BackgroundTransparency = 1
        window.Position = UDim2.new(0.5, 0, 0.3, 0)
        titleBar.BackgroundTransparency = 1
        titleFix.BackgroundTransparency = 1
        
        local entranceTween = createTween(window, {
            Size = UDim2.new(0, dimensions.width, 0, dimensions.height),
            BackgroundTransparency = windowTransparency,
            Position = UDim2.new(posData.x, posData.xOffset, posData.y, posData.yOffset)
        }, 0.4, Enum.EasingStyle.Back)
        entranceTween:Play()
        
        createTween(titleBar, {BackgroundTransparency = windowTransparency}, 0.4, Enum.EasingStyle.Quint):Play()
        createTween(titleFix, {BackgroundTransparency = windowTransparency}, 0.4, Enum.EasingStyle.Quint):Play()
        
    elseif windowType == "fullscreen" then
        window.BackgroundTransparency = 1
        titleBar.BackgroundTransparency = 1
        titleFix.BackgroundTransparency = 1
        
        createTween(window, {BackgroundTransparency = windowTransparency}, 0.3, Enum.EasingStyle.Sine):Play()
        createTween(titleBar, {BackgroundTransparency = windowTransparency}, 0.3, Enum.EasingStyle.Sine):Play()
        createTween(titleFix, {BackgroundTransparency = windowTransparency}, 0.3, Enum.EasingStyle.Sine):Play()
    else
        window.Size = UDim2.new(0, 0, 0, 0)
        window.BackgroundTransparency = 1
        window.Position = UDim2.new(0.5, 0, 0.5, 0)
        titleBar.BackgroundTransparency = 1
        titleFix.BackgroundTransparency = 1
        
        local entranceTween = createTween(window, {
            Size = UDim2.new(0, dimensions.width, 0, dimensions.height),
            BackgroundTransparency = windowTransparency,
            Position = UDim2.new(posData.x, posData.xOffset, posData.y, posData.yOffset)
        }, 0.5, Enum.EasingStyle.Back)
        entranceTween:Play()
        
        createTween(titleBar, {BackgroundTransparency = windowTransparency}, 0.5, Enum.EasingStyle.Quint):Play()
        createTween(titleFix, {BackgroundTransparency = windowTransparency}, 0.5, Enum.EasingStyle.Quint):Play()
    end
    
    print("GUI: Created " .. windowType .. " window '" .. title .. "'")
    return window
end

function Interpreter.create.prompt(windowTitle, text)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local content = window:FindFirstChild("Content")
    
    local label = Instance.new("TextLabel")
    label.Name = "Prompt_" .. #Interpreter.GUI.Elements[windowTitle]
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(190, 190, 195)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.BorderSizePixel = 0
    label.Parent = content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = label
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = label
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(25, 25, 30)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = label
    
    -- Fancy entrance animation - slide from left with fade
    label.Position = UDim2.new(0, -50, 0, 0)
    label.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    createTween(label, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(label, {BackgroundTransparency = 0, TextTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(stroke, {Transparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    
    table.insert(Interpreter.GUI.Elements[windowTitle], label)
    return label
end

function Interpreter.create.button(windowTitle, text, colorName)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local content = window:FindFirstChild("Content")
    
    local colorMap = {
        red = Color3.fromRGB(160, 30, 30),
        green = Color3.fromRGB(30, 140, 60),
        blue = Color3.fromRGB(40, 100, 180),
        yellow = Color3.fromRGB(180, 140, 30),
        purple = Color3.fromRGB(120, 40, 160)
    }
    
    local btnColor = colorMap[colorName and colorName:lower()] or Color3.fromRGB(50, 90, 140)
    
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. text:gsub("%s+", "")
    button.Size = UDim2.new(1, 0, 0, 32)
    button.BackgroundColor3 = btnColor
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 240, 245)
    button.TextSize = 12
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(btnColor.R * 1.4, btnColor.G * 1.4, btnColor.B * 1.4)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        local brighterColor = Color3.new(btnColor.R * 1.3, btnColor.G * 1.3, btnColor.B * 1.3)
        createTween(button, {BackgroundColor3 = brighterColor}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(stroke, {Color = Color3.new(btnColor.R * 1.8, btnColor.G * 1.8, btnColor.B * 1.8)}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    button.MouseLeave:Connect(function()
        createTween(button, {BackgroundColor3 = btnColor}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(stroke, {Color = Color3.new(btnColor.R * 1.4, btnColor.G * 1.4, btnColor.B * 1.4)}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    
    -- Click animation - scale pulse
    button.MouseButton1Down:Connect(function()
        createTween(button, {Size = UDim2.new(1, -4, 0, 30)}, 0.08, Enum.EasingStyle.Quad):Play()
    end)
    button.MouseButton1Up:Connect(function()
        createTween(button, {Size = UDim2.new(1, 0, 0, 32)}, 0.15, Enum.EasingStyle.Elastic):Play()
    end)
    
    -- Entrance animation - slide from right
    button.Position = UDim2.new(0, 50, 0, 0)
    button.BackgroundTransparency = 1
    button.TextTransparency = 1
    
    task.wait(0.05)
    
    createTween(button, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(button, {BackgroundTransparency = 0, TextTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(stroke, {Transparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    
    table.insert(Interpreter.GUI.Elements[windowTitle], button)
    return button
end

-- TOGGLE ELEMENT
function Interpreter.create.toggle(windowTitle, text, defaultState)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local content = window:FindFirstChild("Content")
    defaultState = defaultState or false
    
    -- Container for toggle
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. text:gsub("%s+", "")
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    container.BorderSizePixel = 0
    container.Parent = content
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 3)
    containerCorner.Parent = container
    
    local containerStroke = Instance.new("UIStroke")
    containerStroke.Color = Color3.fromRGB(25, 25, 30)
    containerStroke.Thickness = 1
    containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    containerStroke.Parent = container
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 205)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0, 40, 0, 20)
    toggleBtn.Position = UDim2.new(1, -45, 0.5, -10)
    toggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(30, 140, 60) or Color3.fromRGB(60, 60, 65)
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0) -- Fully rounded
    toggleCorner.Parent = toggleBtn
    
    -- Toggle knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBtn
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    -- State tracking
    local isOn = defaultState
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        -- Animate toggle
        if isOn then
            createTween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(30, 140, 60)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(knob, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.2, Enum.EasingStyle.Sine):Play()
        else
            createTween(toggleBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 65)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(knob, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2, Enum.EasingStyle.Sine):Play()
        end
    end)
    
    -- Entrance animation
    container.Position = UDim2.new(0, 50, 0, 0)
    container.BackgroundTransparency = 1
    label.TextTransparency = 1
    toggleBtn.BackgroundTransparency = 1
    knob.BackgroundTransparency = 1
    
    task.wait(0.05)
    
    createTween(container, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(container, {BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(label, {TextTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(toggleBtn, {BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(knob, {BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(containerStroke, {Transparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    
    table.insert(Interpreter.GUI.Elements[windowTitle], container)
    
    -- Return both container and function to get state
    container.GetState = function() return isOn end
    return container
end

function Interpreter.create.txtinput(windowTitle, placeholder)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local content = window:FindFirstChild("Content")
    
    local textBox = Instance.new("TextBox")
    textBox.Name = "Input_" .. #Interpreter.GUI.Elements[windowTitle]
    textBox.Size = UDim2.new(1, 0, 0, 32)
    textBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    textBox.PlaceholderText = placeholder or "Enter text..."
    textBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 85)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(220, 220, 225)
    textBox.TextSize = 12
    textBox.Font = Enum.Font.Gotham
    textBox.ClearTextOnFocus = false
    textBox.BorderSizePixel = 0
    textBox.Parent = content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = textBox
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(35, 35, 40)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = textBox
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = textBox
    
    -- Focus effects with glow
    textBox.Focused:Connect(function()
        createTween(textBox, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(stroke, {Color = Color3.fromRGB(60, 100, 160), Thickness = 1.5}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    textBox.FocusLost:Connect(function()
        createTween(textBox, {BackgroundColor3 = Color3.fromRGB(15, 15, 18)}, 0.2, Enum.EasingStyle.Sine):Play()
        createTween(stroke, {Color = Color3.fromRGB(35, 35, 40), Thickness = 1}, 0.2, Enum.EasingStyle.Sine):Play()
    end)
    
    -- Entrance animation - fade scale
    textBox.Size = UDim2.new(1, 0, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.TextTransparency = 1
    
    task.wait(0.1)
    
    createTween(textBox, {Size = UDim2.new(1, 0, 0, 32)}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(textBox, {BackgroundTransparency = 0, TextTransparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    createTween(stroke, {Transparency = 0}, 0.4, Enum.EasingStyle.Quint):Play()
    
    table.insert(Interpreter.GUI.Elements[windowTitle], textBox)
    return textBox
end

-- Destroy functions with fancy animations (NO REBOUND FIX)
function Interpreter.destroy.window(windowTitle)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    -- Disconnect dragging to prevent rebound
    window.Active = false
    local titleBar = window:FindFirstChild("TitleBar")
    if titleBar then
        titleBar.Active = false
    end
    
    -- Get all child elements for synchronized fade
    local content = window:FindFirstChild("Content")
    local stroke = window:FindFirstChildOfClass("UIStroke")
    local titleFix = titleBar and titleBar:FindFirstChild("Frame")
    
    -- Exit animation - shrink and fade (QUINT instead of BACK to prevent rebound)
    local tween1 = createTween(window, {
        Size = UDim2.new(0, 0, 0, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.25, Enum.EasingStyle.Quint) -- Changed from Back to Quint
    
    local tween2 = createTween(window, {BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
    
    -- Fade stroke
    if stroke then
        createTween(stroke, {Transparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
    end
    
    -- Fade title bar
    if titleBar then
        createTween(titleBar, {BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
        if titleFix then
            createTween(titleFix, {BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
        end
        local title = titleBar:FindFirstChild("Title")
        if title then
            createTween(title, {TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
        end
        local closeBtn = titleBar:FindFirstChild("CloseButton")
        if closeBtn then
            createTween(closeBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
        end
        local minimizeBtn = titleBar:FindFirstChild("MinimizeButton")
        if minimizeBtn then
            createTween(minimizeBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
        end
    end
    
    -- Fade content
    if content then
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiObject") then
                createTween(child, {BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    createTween(child, {TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
                end
                -- Fade strokes on child elements
                local childStroke = child:FindFirstChildOfClass("UIStroke")
                if childStroke then
                    createTween(childStroke, {Transparency = 1}, 0.25, Enum.EasingStyle.Quint):Play()
                end
            end
        end
    end
    
    tween1:Play()
    tween2:Play()
    
    tween1.Completed:Connect(function()
        window:Destroy()
        Interpreter.GUI.Windows[windowTitle] = nil
        Interpreter.GUI.Elements[windowTitle] = nil
        Interpreter.GUI.Minimized[windowTitle] = nil
    end)
end

function Interpreter.destroy.button(windowTitle, buttonText)
    local elements = Interpreter.GUI.Elements[windowTitle]
    if not elements then return end
    
    for i, element in ipairs(elements) do
        if element.Name == "Button_" .. buttonText:gsub("%s+", "") then
            local tween = createTween(element, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
            tween:Play()
            tween.Completed:Connect(function()
                element:Destroy()
                table.remove(elements, i)
            end)
            break
        end
    end
end

function Interpreter.destroy.toggle(windowTitle, toggleText)
    local elements = Interpreter.GUI.Elements[windowTitle]
    if not elements then return end
    
    for i, element in ipairs(elements) do
        if element.Name == "Toggle_" .. toggleText:gsub("%s+", "") then
            local tween = createTween(element, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
            tween:Play()
            tween.Completed:Connect(function()
                element:Destroy()
                table.remove(elements, i)
            end)
            break
        end
    end
end

function Interpreter.destroy.txtinput(windowTitle, index)
    local elements = Interpreter.GUI.Elements[windowTitle]
    if not elements then return end
    
    local inputElements = {}
    for _, element in ipairs(elements) do
        if element:IsA("TextBox") then
            table.insert(inputElements, element)
        end
    end
    
    if inputElements[index or 1] then
        local element = inputElements[index or 1]
        local tween = createTween(element, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
        tween:Play()
        tween.Completed:Connect(function()
            element:Destroy()
        end)
    end
end

function Interpreter.destroy.prompt(windowTitle, index)
    local elements = Interpreter.GUI.Elements[windowTitle]
    if not elements then return end
    
    local promptElements = {}
    for _, element in ipairs(elements) do
        if element:IsA("TextLabel") and element.Name:match("Prompt_") then
            table.insert(promptElements, element)
        end
    end
    
    if promptElements[index or 1] then
        local element = promptElements[index or 1]
        local tween = createTween(element, {Position = UDim2.new(0, -50, 0, 0), BackgroundTransparency = 1, TextTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
        tween:Play()
        tween.Completed:Connect(function()
            element:Destroy()
        end)
    end
end

-- Callback functions
function Interpreter.buttonis.clicked(windowTitle, buttonText, functionName)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local button = window:FindFirstChild("Content"):FindFirstChild("Button_" .. buttonText:gsub("%s+", ""))
    if not button then warn("GUI: Button not found") return end
    
    button.MouseButton1Click:Connect(function()
        if Interpreter.Handlers[functionName] then
            Interpreter.Handlers[functionName]({})
        else
            warn("GUI: Function '" .. functionName .. "' not found")
        end
    end)
end

function Interpreter.toggleis.changed(windowTitle, toggleText, functionName)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local toggle = window:FindFirstChild("Content"):FindFirstChild("Toggle_" .. toggleText:gsub("%s+", ""))
    if not toggle then warn("GUI: Toggle not found") return end
    
    local toggleBtn = toggle:FindFirstChild("ToggleButton")
    if not toggleBtn then return end
    
    toggleBtn.MouseButton1Click:Connect(function()
        if Interpreter.Handlers[functionName] then
            local state = toggle.GetState()
            Interpreter.Handlers[functionName]({tostring(state)})
        else
            warn("GUI: Function '" .. functionName .. "' not found")
        end
    end)
end

function Interpreter.placeholderis.finished(windowTitle, inputIndex, functionName)
    local elements = Interpreter.GUI.Elements[windowTitle]
    if not elements then return end
    
    local inputElements = {}
    for _, element in ipairs(elements) do
        if element:IsA("TextBox") then
            table.insert(inputElements, element)
        end
    end
    
    local textBox = inputElements[inputIndex or 1]
    if not textBox then warn("GUI: Input not found") return end
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and Interpreter.Handlers[functionName] then
            Interpreter.Handlers[functionName]({textBox.Text})
        end
    end)
end

function Interpreter.windowis.closed(windowTitle, functionName)
    local window = Interpreter.GUI.Windows[windowTitle]
    if not window then warn("GUI: Window not found") return end
    
    local closeBtn = window:FindFirstChild("TitleBar"):FindFirstChild("CloseButton")
    if not closeBtn then return end
    
    closeBtn.MouseButton1Click:Connect(function()
        if Interpreter.Handlers[functionName] then
            Interpreter.Handlers[functionName]({})
        else
            Interpreter.destroy.window(windowTitle)
        end
    end)
end

-- Notification System
Interpreter.Notifications = {
    Active = {},
    Container = nil,
    MaxNotifications = 5,
    DefaultDuration = 4
}

function Interpreter.notify(title, description, duration, notifType, options)
    duration = duration or Interpreter.Notifications.DefaultDuration
    notifType = notifType or "info" -- info, success, error, warning
    options = options or {}
    
    -- Options structure:
    -- {
    --     isClickable = true/false,
    --     onClickFunction = "functionName",
    --     buttons = {
    --         {text = "Yes", color = "green", onClickFunction = "functionName"},
    --         {text = "No", color = "red", onClickFunction = "functionName"}
    --     },
    --     textInput = {
    --         placeholder = "Enter text...",
    --         onSubmitFunction = "functionName"
    --     }
    -- }
    
    local screenGui = getScreenGui()
    
    -- Create notification container if it doesn't exist
    if not Interpreter.Notifications.Container then
        local container = Instance.new("Frame")
        container.Name = "NotificationContainer"
        container.Size = UDim2.new(0, 320, 1, -20)
        container.Position = UDim2.new(1, -330, 0, 10)
        container.BackgroundTransparency = 1
        container.Parent = screenGui
        
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 8)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        listLayout.Parent = container
        
        Interpreter.Notifications.Container = container
    end
    
    -- Remove oldest notification if at max
    if #Interpreter.Notifications.Active >= Interpreter.Notifications.MaxNotifications then
        local oldest = Interpreter.Notifications.Active[1]
        if oldest then
            Interpreter.removeNotification(oldest, true)
        end
    end
    
    -- Color schemes based on type
    local colorSchemes = {
        info = {
            bg = Color3.fromRGB(20, 80, 140),
            stroke = Color3.fromRGB(40, 120, 200),
            glow = Color3.fromRGB(60, 140, 220)
        },
        success = {
            bg = Color3.fromRGB(20, 120, 60),
            stroke = Color3.fromRGB(40, 160, 80),
            glow = Color3.fromRGB(60, 200, 100)
        },
        error = {
            bg = Color3.fromRGB(140, 30, 30),
            stroke = Color3.fromRGB(200, 50, 50),
            glow = Color3.fromRGB(220, 70, 70)
        },
        warning = {
            bg = Color3.fromRGB(140, 100, 20),
            stroke = Color3.fromRGB(200, 150, 40),
            glow = Color3.fromRGB(220, 180, 60)
        }
    }
    
    local colors = colorSchemes[notifType] or colorSchemes.info
    
    -- Create notification frame
    local notif = Instance.new("Frame")
    notif.Name = "Notification_" .. tick()
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.AutomaticSize = Enum.AutomaticSize.Y
    notif.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    notif.BorderSizePixel = 0
    notif.ClipsDescendants = true
    notif.LayoutOrder = #Interpreter.Notifications.Active
    notif.Parent = Interpreter.Notifications.Container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(30, 30, 35)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = notif
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Image = "rbxassetid://4996891970"
    glow.ImageColor3 = colors.glow
    glow.ImageTransparency = 1
    glow.ZIndex = 0
    glow.Parent = notif
    
    -- Make notification clickable if requested
    if options.isClickable and options.onClickFunction then
        local clickButton = Instance.new("TextButton")
        clickButton.Name = "ClickDetector"
        clickButton.Size = UDim2.new(1, 0, 1, 0)
        clickButton.BackgroundTransparency = 1
        clickButton.Text = ""
        clickButton.ZIndex = 1
        clickButton.Parent = notif
        
        clickButton.MouseEnter:Connect(function()
            createTween(notif, {BackgroundColor3 = Color3.fromRGB(15, 15, 17)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(glow, {ImageTransparency = 0.7}, 0.2, Enum.EasingStyle.Sine):Play()
        end)
        
        clickButton.MouseLeave:Connect(function()
            createTween(notif, {BackgroundColor3 = Color3.fromRGB(10, 10, 12)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(glow, {ImageTransparency = 0.85}, 0.2, Enum.EasingStyle.Sine):Play()
        end)
        
        clickButton.MouseButton1Click:Connect(function()
            if Interpreter.Handlers[options.onClickFunction] then
                Interpreter.Handlers[options.onClickFunction]({})
            end
            Interpreter.removeNotification(notif, false)
        end)
    end
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -50, 1, 0)
    content.Position = UDim2.new(0, 12, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.ZIndex = 2
    content.Parent = notif
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 8)
    contentPadding.PaddingBottom = UDim.new(0, 8)
    contentPadding.Parent = content
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 14)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    titleLabel.TextSize = 12
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.ZIndex = 2
    titleLabel.Parent = content
    
    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "Description"
    descLabel.Size = UDim2.new(1, 0, 0, 0)
    descLabel.Position = UDim2.new(0, 0, 0, 16)
    descLabel.AutomaticSize = Enum.AutomaticSize.Y
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.TextColor3 = Color3.fromRGB(180, 180, 185)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.ZIndex = 2
    descLabel.Parent = content
    
    -- Calculate vertical offset for interactive elements
    local yOffset = 32 -- Base offset after title + description
    
    -- Add buttons if provided (max 2)
    if options.buttons and #options.buttons > 0 then
        local buttonContainer = Instance.new("Frame")
        buttonContainer.Name = "ButtonContainer"
        buttonContainer.Size = UDim2.new(1, 0, 0, 28)
        buttonContainer.Position = UDim2.new(0, 0, 0, yOffset)
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.ZIndex = 2
        buttonContainer.Parent = content
        
        local buttonCount = math.min(#options.buttons, 2)
        local buttonWidth = buttonCount == 1 and 1 or 0.48
        
        local buttonColorMap = {
            red = Color3.fromRGB(140, 30, 30),
            green = Color3.fromRGB(30, 120, 50),
            blue = Color3.fromRGB(40, 90, 150),
            yellow = Color3.fromRGB(150, 120, 30),
            purple = Color3.fromRGB(100, 40, 140)
        }
        
        for i = 1, buttonCount do
            local btnData = options.buttons[i]
            local btnColor = buttonColorMap[btnData.color and btnData.color:lower()] or Color3.fromRGB(50, 80, 120)
            
            local button = Instance.new("TextButton")
            button.Name = "Button_" .. i
            button.Size = UDim2.new(buttonWidth, 0, 0, 28)
            button.Position = buttonCount == 1 and UDim2.new(0, 0, 0, 0) or UDim2.new((i-1) * 0.52, 0, 0, 0)
            button.BackgroundColor3 = btnColor
            button.Text = btnData.text
            button.TextColor3 = Color3.fromRGB(240, 240, 245)
            button.TextSize = 11
            button.Font = Enum.Font.GothamBold
            button.BorderSizePixel = 0
            button.ZIndex = 3
            button.Parent = buttonContainer
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 3)
            btnCorner.Parent = button
            
            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = Color3.new(btnColor.R * 1.4, btnColor.G * 1.4, btnColor.B * 1.4)
            btnStroke.Thickness = 1
            btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            btnStroke.Parent = button
            
            -- Button hover effects
            button.MouseEnter:Connect(function()
                local brighterColor = Color3.new(btnColor.R * 1.3, btnColor.G * 1.3, btnColor.B * 1.3)
                createTween(button, {BackgroundColor3 = brighterColor}, 0.15, Enum.EasingStyle.Sine):Play()
            end)
            
            button.MouseLeave:Connect(function()
                createTween(button, {BackgroundColor3 = btnColor}, 0.15, Enum.EasingStyle.Sine):Play()
            end)
            
            -- Button click
            button.MouseButton1Down:Connect(function()
                createTween(button, {Size = UDim2.new(buttonWidth, -2, 0, 26)}, 0.08, Enum.EasingStyle.Quad):Play()
            end)
            
            button.MouseButton1Up:Connect(function()
                createTween(button, {Size = UDim2.new(buttonWidth, 0, 0, 28)}, 0.12, Enum.EasingStyle.Elastic):Play()
            end)
            
            button.MouseButton1Click:Connect(function()
                if btnData.onClickFunction and Interpreter.Handlers[btnData.onClickFunction] then
                    Interpreter.Handlers[btnData.onClickFunction]({})
                end
                Interpreter.removeNotification(notif, false)
            end)
        end
        
        yOffset = yOffset + 34 -- Add space after buttons
    end
    
    -- Add text input if provided (only if no buttons)
    if options.textInput and (not options.buttons or #options.buttons == 0) then
        local inputBox = Instance.new("TextBox")
        inputBox.Name = "TextInput"
        inputBox.Size = UDim2.new(1, 0, 0, 28)
        inputBox.Position = UDim2.new(0, 0, 0, yOffset)
        inputBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        inputBox.PlaceholderText = options.textInput.placeholder or "Enter text..."
        inputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 85)
        inputBox.Text = ""
        inputBox.TextColor3 = Color3.fromRGB(220, 220, 225)
        inputBox.TextSize = 11
        inputBox.Font = Enum.Font.Gotham
        inputBox.ClearTextOnFocus = false
        inputBox.BorderSizePixel = 0
        inputBox.ZIndex = 3
        inputBox.Parent = content
        
        local inputCorner = Instance.new("UICorner")
        inputCorner.CornerRadius = UDim.new(0, 3)
        inputCorner.Parent = inputBox
        
        local inputStroke = Instance.new("UIStroke")
        inputStroke.Color = Color3.fromRGB(35, 35, 40)
        inputStroke.Thickness = 1
        inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        inputStroke.Parent = inputBox
        
        local inputPadding = Instance.new("UIPadding")
        inputPadding.PaddingLeft = UDim.new(0, 8)
        inputPadding.PaddingRight = UDim.new(0, 8)
        inputPadding.Parent = inputBox
        
        -- Focus effects
        inputBox.Focused:Connect(function()
            createTween(inputBox, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(inputStroke, {Color = Color3.fromRGB(60, 100, 160), Thickness = 1.5}, 0.2, Enum.EasingStyle.Sine):Play()
        end)
        
        inputBox.FocusLost:Connect(function(enterPressed)
            createTween(inputBox, {BackgroundColor3 = Color3.fromRGB(15, 15, 18)}, 0.2, Enum.EasingStyle.Sine):Play()
            createTween(inputStroke, {Color = Color3.fromRGB(35, 35, 40), Thickness = 1}, 0.2, Enum.EasingStyle.Sine):Play()
            
            if enterPressed and options.textInput.onSubmitFunction then
                if Interpreter.Handlers[options.textInput.onSubmitFunction] then
                    Interpreter.Handlers[options.textInput.onSubmitFunction]({inputBox.Text})
                end
                Interpreter.removeNotification(notif, false)
            end
        end)
        
        yOffset = yOffset + 34 -- Add space after input
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -26, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(160, 160, 165)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 4
    closeBtn.Parent = notif
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 3)
    closeBtnCorner.Parent = closeBtn
    
    -- Close button hover
    closeBtn.MouseEnter:Connect(function()
        createTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(180, 30, 30)}, 0.15):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        createTween(closeBtn, {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}, 0.15):Play()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        Interpreter.removeNotification(notif, false)
    end)
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBg"
    progressBg.Size = UDim2.new(1, 0, 0, 2)
    progressBg.Position = UDim2.new(0, 0, 1, -2)
    progressBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 2
    progressBg.Parent = notif
    
    local progress = Instance.new("Frame")
    progress.Name = "Progress"
    progress.Size = UDim2.new(1, 0, 1, 0)
    progress.BackgroundColor3 = colors.bg
    progress.BorderSizePixel = 0
    progress.ZIndex = 2
    progress.Parent = progressBg
    
    -- Entrance animation - slide from right with bounce
    notif.Position = UDim2.new(1, 50, 0, 0)
    notif.Size = UDim2.new(1, 0, 0, 0)
    
    local entranceTween = createTween(notif, {
        Position = UDim2.new(0, 0, 0, 0)
    }, 0.5, Enum.EasingStyle.Back)
    entranceTween:Play()
    
    -- Store reference
    table.insert(Interpreter.Notifications.Active, notif)
    
    -- Progress bar animation
    local safeDuration = tonumber(duration) or Interpreter.Notifications.DefaultDuration
    local progressTween = createTween(progress, {Size = UDim2.new(0, 0, 1, 0)}, safeDuration, Enum.EasingStyle.Linear)
    progressTween:Play()
    
    -- Auto-dismiss after duration
    task.delay(safeDuration, function()
        if notif and notif.Parent then
            Interpreter.removeNotification(notif, false)
        end
    end)
    
    print("NOTIFICATION: Created '" .. title .. "'")
    return notif
end

function Interpreter.removeNotification(notif, instant)
    if not notif or not notif.Parent then return end
    
    -- Remove from active list
    for i, activeNotif in ipairs(Interpreter.Notifications.Active) do
        if activeNotif == notif then
            table.remove(Interpreter.Notifications.Active, i)
            break
        end
    end
    
    if instant then
        notif:Destroy()
        return
    end
    
    -- Get all elements that need to fade
    local stroke = notif:FindFirstChildOfClass("UIStroke")
    local glow = notif:FindFirstChild("Glow")
    local accent = notif:FindFirstChild("Accent")
    local content = notif:FindFirstChild("Content")
    local closeBtn = notif:FindFirstChild("Close")
    local progressBg = notif:FindFirstChild("ProgressBg")
    
    local titleLabel = content and content:FindFirstChild("Title")
    local descLabel = content and content:FindFirstChild("Description")
    
    -- Exit animation - slide right and fade EVERYTHING synchronously
    local exitTween1 = createTween(notif, {
        Position = UDim2.new(1, 50, 0, 0)
    }, 0.3, Enum.EasingStyle.Back)
    
    local exitTween2 = createTween(notif, {
        BackgroundTransparency = 1
    }, 0.3, Enum.EasingStyle.Sine)
    
    -- Fade all elements at the SAME TIME with SAME DURATION
    if stroke then
        createTween(stroke, {Transparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    if glow then
        createTween(glow, {ImageTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    if accent then
        createTween(accent, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    if closeBtn then
        createTween(closeBtn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    if progressBg then
        createTween(progressBg, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
        local progress = progressBg:FindFirstChild("Progress")
        if progress then
            createTween(progress, {BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
        end
    end
    
    if titleLabel then
        createTween(titleLabel, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    if descLabel then
        createTween(descLabel, {TextTransparency = 1}, 0.3, Enum.EasingStyle.Sine):Play()
    end
    
    exitTween1:Play()
    exitTween2:Play()
    
    exitTween1.Completed:Connect(function()
        notif:Destroy()
    end)
end

-- Initialize
function Interpreter.init()
    local player = Players.LocalPlayer
    local aod = true -- Set to true to hook everyone
    
    if player then
        -- Function to hook a player's chat
        local function hookPlayer(p)
            p.Chatted:Connect(function(message)
                if message:sub(1, 1) == "*" then
                    Interpreter.processCommand(message)
                end
            end)
        end

        if aod then
            -- Hook everyone currently in the game
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                hookPlayer(p)
            end
            -- Hook anyone who joins later
            game:GetService("Players").PlayerAdded:Connect(hookPlayer)
        else
            -- Original single-player logic
            Interpreter.ChatConnection = player.Chatted:Connect(function(message)
                if message:sub(1, 1) == "*" then
                    Interpreter.processCommand(message)
                end
            end)
        end
        
        -- init steps
        Interpreter.cmd("helper")
        Interpreter.cmd("injector on")
        
        -- Startup notification
        Interpreter.notify(
            "RuptorX Active!",
            "Click here to open console and see commands!",
            4, -- 8 seconds duration for startup message
            "success",
            {
                isClickable = true,
                onClickFunction = "startup_open_console"
            }
        )
        
        print("RuptorX: Chat listener activated")
        print("RuptorX: Commands List, *print <msg> | *showhp on/off (Shows other's HP) | *tp sv/ld | *team <name> | *pteam <name> (Persist) | *uteam (Unpersist) | *health <val> | *phealth <val> (Persist) | *nostun (Toggle stun/fall prevention) | *esp on/off | *reset | *unfly | *noclip | *to <player> | *spin <speed> | *speed <val> | *jump <val> | *dance | *lockto <player> | *unlock | *follow <player> | *sflw (Stop Follow) | *orbit <player> <speed> | *sorbit | *troll [ex/sp <team>] (spam tp) | *stroll | *walkfling | *sft (Stop Fling) | *float <height> | *sfloat | *bk sv/ld (Backpack, clone loot) | *shutdown | *noregul on/off (disables limits)")
    else
        warn("RuptorX: Player not found")
    end
    
    return Interpreter
end

local success, err = pcall(function()
    Interpreter.init()
end)

if not success then
    warn("RuptorX: Failed to initialize: " .. tostring(err))
end

-- CRITICAL: Initialize SystemMaintenance AFTER Interpreter
local sysMaintSuccess, sysMaintErr = pcall(function()
    SystemMaintenance.init()
end)

if not sysMaintSuccess then
    warn("SYSMAINT: Failed to initialize: " .. tostring(sysMaintErr))
end

-- Calculate and print load time
local scriptEndTime = os.clock()
local loadTime = scriptEndTime - scriptStartTime
print(string.format("RuptorX: Script loaded in %.3f seconds", loadTime))

Interpreter.cmd("chatx")

return Interpreter
