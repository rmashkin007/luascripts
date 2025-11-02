-- Roblox Server Hopper Script

-- Configuration: List of usernames to avoid
local UsernamesToAvoid = {
    "rofls1212",
    "LaidBackAbstract66",
    "TopBaconPlayer21_xXx",
    "CreepySkyM8",
    "fe_few1",
    "xXDarkangelOF1",
    "S1apL3gendGG",
    "satoruhoj000",
}

-- Services
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

-- Get current place ID
local PlaceId = game.PlaceId

-- Track recently hopped servers to avoid rejoining
local recentServers = {}
local MAX_RECENT_SERVERS = 20 -- Keep track of last 20 servers (increased to prevent same-server rejoins)
local hopCooldown = false

-- Function to get current server job ID
local function getCurrentServerId()
    return game.JobId
end

-- Function to add server to recent list
local function addRecentServer(serverId)
    local serverIdStr = tostring(serverId)
    table.insert(recentServers, 1, serverIdStr) -- Add to beginning
    -- Keep only the most recent servers
    if #recentServers > MAX_RECENT_SERVERS then
        table.remove(recentServers, MAX_RECENT_SERVERS + 1)
    end
end

-- Function to check if server is in recent list
local function isRecentServer(serverId)
    local serverIdStr = tostring(serverId)
    for _, recentId in pairs(recentServers) do
        if recentId == serverIdStr then
            return true
        end
    end
    return false
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopperGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "StatusFrame"
frame.Size = UDim2.new(0, 300, 0, 50)
frame.Position = UDim2.new(0, 10, 1, -60) -- Left bottom corner with some padding
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.3
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = frame

local label = Instance.new("TextLabel")
label.Name = "StatusLabel"
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "Initializing..."
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 14
label.Font = Enum.Font.Gotham
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Center
label.TextWrapped = true
label.Parent = frame

-- Function to update status text
local function updateStatus(text)
    label.Text = text
end

-- Function to check if any player matches the username list (excluding local player)
local function hasAvoidedUsername()
    for _, player in pairs(Players:GetPlayers()) do
        -- Skip the local player
        if player ~= localPlayer then
            for _, username in pairs(UsernamesToAvoid) do
                if player.Name:lower() == username:lower() then
                    return true
                end
            end
        end
    end
    return false
end

-- Function to find a server with 2 available slots and max players
local function findBestServer()
    local maxAttempts = 10 -- Try up to 10 times to find a good server
    local currentServerId = getCurrentServerId()
    
    for attempt = 1, maxAttempts do
        -- Get server list (using HttpService to query Roblox API)
        local success, result = pcall(function()
            -- Query more servers and sort by player count descending
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100", PlaceId)
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            
            if data and data.data then
                -- Filter servers with exactly 2 available slots (excluding current server)
                local bestServer = nil
                local maxPlayers = 0
                
                for _, server in pairs(data.data) do
                    local serverId = tostring(server.id)
                    local currentServerIdStr = tostring(currentServerId)
                    
                    -- Skip if this is the current server or a recently hopped server
                    if serverId ~= currentServerIdStr and not isRecentServer(server.id) then
                        local currentPlayers = server.playing or 0
                        local maxServerPlayers = server.maxPlayers or 10
                        local availableSlots = maxServerPlayers - currentPlayers
                        
                        -- Look for server with 2 available slots and highest player count
                        if availableSlots == 2 and currentPlayers > maxPlayers then
                            maxPlayers = currentPlayers
                            bestServer = server.id
                        end
                    end
                end
                
                -- If no server with exactly 2 slots, find one with at least 2 slots and max players
                if not bestServer then
                    maxPlayers = 0
                    for _, server in pairs(data.data) do
                        local serverId = tostring(server.id)
                        local currentServerIdStr = tostring(currentServerId)
                        
                        -- Skip if this is the current server or a recently hopped server
                        if serverId ~= currentServerIdStr and not isRecentServer(server.id) then
                            local currentPlayers = server.playing or 0
                            local maxServerPlayers = server.maxPlayers or 10
                            local availableSlots = maxServerPlayers - currentPlayers
                            
                            if availableSlots >= 2 and currentPlayers > maxPlayers then
                                maxPlayers = currentPlayers
                                bestServer = server.id
                            end
                        end
                    end
                end
                
                return bestServer
            end
        end)
        
        if success and result then
            return result
        end
        
        wait(0.5) -- Wait before retry
    end
    
    return nil
end

-- Function to hop to a new server
local function hopServer()
    updateStatus("Attempting to find a new server...")
    
    local currentServerId = getCurrentServerId()
    
    -- Add current server to recent list before hopping (so we don't rejoin it)
    addRecentServer(currentServerId)
    
    -- Set cooldown to prevent immediate re-check after hopping
    hopCooldown = true
    spawn(function()
        wait(10) -- 10 second cooldown after hopping
        hopCooldown = false
    end)
    
    local serverId = findBestServer()
    local attempts = 0
    local maxTeleportAttempts = 3
    
    -- Try to find a server that isn't recent, up to 3 attempts
    while (serverId and (isRecentServer(serverId) or tostring(serverId) == tostring(currentServerId))) and attempts < maxTeleportAttempts do
        attempts = attempts + 1
        updateStatus(string.format("Server %d was recent, finding another...", attempts))
        wait(0.5)
        serverId = findBestServer()
    end
    
    if serverId then
        -- Final verification: make sure it's not the current server and not recent
        local serverIdStr = tostring(serverId)
        local currentServerIdStr = tostring(currentServerId)
        
        if serverIdStr == currentServerIdStr or isRecentServer(serverId) then
            updateStatus("All found servers were recent, using random teleport...")
            -- Add current to recent before random teleport
            pcall(function()
                TeleportService:Teleport(PlaceId, localPlayer)
            end)
            return
        end
        
        -- Add the target server to recent list before teleporting
        addRecentServer(serverId)
        
        updateStatus("Found server, teleporting...")
        local success, errorMsg = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, serverId, localPlayer)
        end)
        
        if not success then
            updateStatus("Teleport failed, finding new server...")
            -- Remove from recent since teleport failed, and try again
            for i, recentId in ipairs(recentServers) do
                if recentId == tostring(serverId) then
                    table.remove(recentServers, i)
                    break
                end
            end
            -- Try one more time
            wait(1)
            hopServer()
        end
    else
        updateStatus("No suitable server found, using random teleport...")
        -- Fallback: Teleport to a random server
        -- Verification function will catch if we join a recent server
        pcall(function()
            TeleportService:Teleport(PlaceId, localPlayer)
        end)
    end
end

-- Function to get current player count
local function getPlayerCount()
    return #Players:GetPlayers()
end

-- Track if we've verified this server already
local lastVerifiedServerId = nil

-- Function to verify we're not on a recent server after joining
local function verifyServerJoin()
    spawn(function()
        wait(5) -- Wait for server to fully load
        local currentId = getCurrentServerId()
        local currentIdStr = tostring(currentId)
        
        -- Only verify once per server
        if currentIdStr ~= lastVerifiedServerId then
            lastVerifiedServerId = currentIdStr
            
            if isRecentServer(currentId) then
                updateStatus("Joined recent server, hopping again...")
                wait(2)
                hopServer()
            end
        end
    end)
end

-- Monitor server changes (detects when we join a new server)
local lastServerCheck = getCurrentServerId()

local function monitorServerChange()
    spawn(function()
        while true do
            wait(2)
            local currentId = getCurrentServerId()
            if tostring(currentId) ~= tostring(lastServerCheck) then
                -- Server changed, verify it
                lastServerCheck = currentId
                verifyServerJoin()
            end
        end
    end)
end

-- Start monitoring for server changes
monitorServerChange()

-- Initial check on script execution
updateStatus("Initial check starting...")
-- Wait a moment for server to fully load before checking
wait(3)

-- Verify we didn't join a recent server
verifyServerJoin()

if not hopCooldown and hasAvoidedUsername() then
    updateStatus("Found avoided username, hopping to new server...")
    hopServer()
else
    updateStatus("No avoided usernames found, staying on current server.")
end

-- Periodic check every 30 seconds
spawn(function()
    while true do
        wait(30)
        
        -- Skip check if cooldown is active (just hopped)
        if hopCooldown then
            updateStatus("Cooldown active, skipping check...")
        else
            local playerCount = getPlayerCount()
            updateStatus(string.format("Checking server... Players: %d", playerCount))
            
            -- Check for avoided usernames first
            if hasAvoidedUsername() then
                updateStatus("Found avoided username, hopping to new server...")
                hopServer()
            elseif playerCount < 8 then
                updateStatus("Player count below 8, hopping to new server...")
                hopServer()
            else
                updateStatus(string.format("Server OK - %d players", playerCount))
            end
        end
    end
end)

updateStatus("Script initialized. Monitoring every 30 seconds...")

