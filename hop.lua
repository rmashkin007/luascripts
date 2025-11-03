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
	"kazikbeskazikbes",
	"1_BabelGaming",
	"TheDyerAnonym",
	"shiyenoWORKING",
	"ItzNivcent",
	"Sub5Sub3Ch4d",
	"antiabdulov_dayn",
	"wiwi_88172",
}

-- Services
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local localPlayer = Players.LocalPlayer

-- Get current place ID
local PlaceId = game.PlaceId


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


local function serverHop()
	local currentJobId = game.JobId
	local maxTotalTime = 10
	local startTime = tick()
	updateStatus("Finding a new server...")

	repeat
		local success, result = pcall(function()
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"):format(PlaceId)
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if success and result and result.data then
			local validServers = {}
			for _, server in pairs(result.data) do
				if server.playing < server.maxPlayers and server.id ~= currentJobId then
					table.insert(validServers, server)
				end
			end
			if #validServers > 0 then
				local chosen = validServers[math.random(1, #validServers)]
				updateStatus("Hopping...")
				TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, localPlayer)
				return
			end
		end
		task.wait(3)
	until tick() - startTime > maxTotalTime
	
    pcall(function()
        TeleportService:Teleport(PlaceId, localPlayer)
    end)
end


-- Function to get current player count
local function getPlayerCount()
    return #Players:GetPlayers()
end

-- Initial check on script execution
updateStatus("Initial check starting...")
-- Wait a moment for server to fully load before checking
wait(3)

if hasAvoidedUsername() then
    updateStatus("Found avoided username, hopping to new server...")
    serverHop()
else
    updateStatus("No avoided usernames found, staying on current server.")
end

-- Periodic check every 30 seconds
spawn(function()
    while true do
        wait(30)
        
        local playerCount = getPlayerCount()
        updateStatus(string.format("Checking server... Players: %d", playerCount))
            
        if playerCount < 8 then
            updateStatus("Player count below 8, hopping to new server...")
            serverHop()
        else
            updateStatus(string.format("Server OK - %d players", playerCount))
        end
    end
end)

updateStatus("Script initialized. Monitoring every 30 seconds...")
