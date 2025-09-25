-- Services we need to use
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--// ----------------- DEBUG MODE ----------------- \\--
--// Set to 'true' to see a red box showing the zone.
--// Set to 'false' when you are done debugging.
local DEBUG_MODE = false
--// ---------------------------------------------- \\--

-- Get the LocalPlayer
local player = Players.LocalPlayer

-- Wait for the folder containing our zone sounds
local zoneSounds = SoundService:WaitForChild("ZoneSounds")

--// CONFIGURATION \\--
-- We use WaitForChild here to make sure the sounds have loaded before the script tries to use them.
-- This is the main fix!
local zoneConfig = {
	["BeachZone"] = zoneSounds:WaitForChild("BeachZone"),
	["Building1"] = zoneSounds:WaitForChild("Factory"),
	["JunkForest"] = zoneSounds:WaitForChild("Junkfood"),
}
--------------------------------

-- Variable to track what sound is currently playing
local currentZoneSound = nil
local debugPart = nil

-- Create the debug part if in debug mode
if DEBUG_MODE then
	debugPart = Instance.new("Part")
	debugPart.Name = "ZoneDebugVisualizer"
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Size = Vector3.new(100, 100, 100)
	debugPart.Color = Color3.new(1, 0, 0)
	debugPart.Transparency = 0.7
	debugPart.Parent = Workspace
end

-- This function runs on every single frame
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local playerPosition = humanoidRootPart.Position
	local foundZoneSound = nil
	local inAnyZone = false

	for zoneName, zoneSound in pairs(zoneConfig) do
		local zoneModel = Workspace:FindFirstChild(zoneName)
		if zoneModel and zoneModel:IsA("Model") and #zoneModel:GetChildren() > 0 then
			local cframe, size = zoneModel:GetBoundingBox()

			local objectSpacePos = cframe:PointToObjectSpace(playerPosition)
			if (math.abs(objectSpacePos.X) <= size.X / 2) and
				(math.abs(objectSpacePos.Y) <= size.Y / 2) and
				(math.abs(objectSpacePos.Z) <= size.Z / 2) then

				foundZoneSound = zoneSound
				inAnyZone = true

				if DEBUG_MODE then
					debugPart.CFrame = cframe
					debugPart.Size = size
				end

				break
			end
		end
	end

	if DEBUG_MODE and not inAnyZone then
		debugPart.Size = Vector3.new(220,220, 220)
	end

	if foundZoneSound ~= currentZoneSound then
		if currentZoneSound then currentZoneSound:Stop() end
		if foundZoneSound then foundZoneSound:Play() end
		currentZoneSound = foundZoneSound
	end
end)