-- This script launches it directly from fs, to prevent overhead from network
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

-- Alright, you caught me. it's the Failsafe.
