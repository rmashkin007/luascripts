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

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

local PlaceId = game.PlaceId

local function getCurrentServerId()
    return game.JobId
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerHopperGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "StatusFrame"
frame.Size = UDim2.new(0, 300, 0, 50)
frame.Position = UDim2.new(0, 10, 1, -60)
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

local function updateStatus(text)
    label.Text = text
end

local function hasAvoidedUsername()
    for _, player in pairs(Players:GetPlayers()) do
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

local function findBestServer()
    local maxAttempts = 10
    local currentServerId = getCurrentServerId()
    
    for attempt = 1, maxAttempts do
        local success, result = pcall(function()
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", PlaceId)
            local response = HttpService:GetAsync(url)
            local data = HttpService:JSONDecode(response)
            
            if data and data.data then
                local bestServer = nil
                local maxPlayers = 0
                
                for _, server in pairs(data.data) do
                    local serverId = tostring(server.id)
                    local currentServerIdStr = tostring(currentServerId)
                    
                    if serverId ~= currentServerIdStr then
                        local currentPlayers = server.playing or 0
                        local maxServerPlayers = server.maxPlayers or 10
                        local availableSlots = maxServerPlayers - currentPlayers
                        
                        if availableSlots == 2 and currentPlayers > maxPlayers then
                            maxPlayers = currentPlayers
                            bestServer = server.id
                        end
                    end
                end
                
                if not bestServer then
                    maxPlayers = 0
                    for _, server in pairs(data.data) do
                        local serverId = tostring(server.id)
                        local currentServerIdStr = tostring(currentServerId)
                        
                        if serverId ~= currentServerIdStr then
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
        
        wait(0.5)
    end
    
    return nil
end

local function hopServer()
    updateStatus("Attempting to find a new server...")
    
    local serverId = findBestServer()
    local currentServerId = getCurrentServerId()
    
    if serverId then
        if tostring(serverId) == tostring(currentServerId) then
            updateStatus("Found server is current server, trying random teleport...")
            pcall(function()
                TeleportService:Teleport(PlaceId, localPlayer)
            end)
            return
        end
        
        updateStatus("Found server, teleporting...")
        local success, errorMsg = pcall(function()
            TeleportService:TeleportToPlaceInstance(PlaceId, serverId, localPlayer)
        end)
        
        if not success then
            updateStatus("Teleport failed, trying random server...")
            pcall(function()
                TeleportService:Teleport(PlaceId, localPlayer)
            end)
        end
    else
        updateStatus("No suitable server found, trying random teleport...")
        pcall(function()
            TeleportService:Teleport(PlaceId, localPlayer)
        end)
    end
end

local function getPlayerCount()
    return #Players:GetPlayers()
end

updateStatus("Initial check starting...")
if hasAvoidedUsername() then
    updateStatus("Found avoided username, hopping to new server...")
    hopServer()
else
    updateStatus("No avoided usernames found, staying on current server.")
end

spawn(function()
    while true do
        wait(30)
        
        local playerCount = getPlayerCount()
        updateStatus(string.format("Checking server... Players: %d", playerCount))
        
        if playerCount < 8 then
            updateStatus("Player count below 8, hopping to new server...")
            hopServer()
        else
            updateStatus(string.format("Server OK - %d players", playerCount))
        end
    end
end)

updateStatus("Script initialized. Monitoring every 30 seconds...")
