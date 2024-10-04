-- Server Script

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Function to spawn vehicle
local function spawnVehicle(player, vehicleName)
	local vehicleFolder = ServerStorage:WaitForChild("Vehicles")
	local spawnFolder = Workspace:WaitForChild("VehicleSpawnPoints")

	local vehicleModel = vehicleFolder:FindFirstChild(vehicleName)
	local spawnPoint = spawnFolder:FindFirstChild(player.Name)

	if vehicleModel and spawnPoint then
		local newVehicle = vehicleModel:Clone()
		newVehicle.Parent = Workspace
		newVehicle:SetPrimaryPartCFrame(spawnPoint.CFrame)
	end
end

-- Function to check player's owned vehicles and spawn them
local function checkPlayerVehicles(player)
	-- Here, insert your own logic to check which vehicles the player owns
	-- For demonstration, I am assuming that the player owns a vehicle named 'Car'
	spawnVehicle(player, "Police Car")
end

-- Connect function for when a player joins
local function onPlayerJoin(player)
	checkPlayerVehicles(player)
end

-- Listen for player joining
Players.PlayerAdded:Connect(onPlayerJoin)
