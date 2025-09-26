-- Located in: StarterPlayer > StarterPlayerScripts

-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Player and Camera
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Remote Event
local enableFlightEvent = ReplicatedStorage:WaitForChild("EnableFlightEvent")

-- Flight Configuration
local FLIGHT_SPEED = 80

-- State Variables
local canFly = false
local isFlying = false
local keysDown = {}
local flightMovers = {}

-- This function creates the physics objects for flight
local function createFlightMovers(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or flightMovers.BodyVelocity then return end

	-- BodyVelocity handles all movement and inherently resists gravity
	local bv = Instance.new("BodyVelocity")
	bv.Name = "FlightVelocity"
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = rootPart
	flightMovers.BodyVelocity = bv

	-- BodyGyro makes the character face the direction of the camera
	local bg = Instance.new("BodyGyro")
	bg.Name = "FlightGyro"
	bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bg.CFrame = camera.CFrame
	bg.Parent = rootPart
	flightMovers.BodyGyro = bg
end

-- This function destroys the physics objects
local function destroyFlightMovers()
	for _, mover in pairs(flightMovers) do
		mover:Destroy()
	end
	table.clear(flightMovers)
end

-- This function toggles flight on and off when F is pressed
local function toggleFlight()
	if not canFly then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

	isFlying = not isFlying

	if isFlying then
		createFlightMovers(character)
		humanoid.PlatformStand = true -- Disables default physics and animations
	else
		destroyFlightMovers()
		humanoid.PlatformStand = false
	end
end

-- This runs every frame to update the character's orientation and velocity
local function updateFlight()
	if not isFlying or not flightMovers.BodyVelocity then return end

	-- Make character face the same direction as the camera
	flightMovers.BodyGyro.CFrame = camera.CFrame

	-- Calculate movement direction based on camera orientation
	local lookVector = camera.CFrame.LookVector
	local rightVector = camera.CFrame.RightVector

	local moveDirection = Vector3.new(0, 0, 0)
	if keysDown[Enum.KeyCode.W] then moveDirection = moveDirection + lookVector end
	if keysDown[Enum.KeyCode.S] then moveDirection = moveDirection - lookVector end
	if keysDown[Enum.KeyCode.A] then moveDirection = moveDirection - rightVector end
	if keysDown[Enum.KeyCode.D] then moveDirection = moveDirection + rightVector end

	-- Calculate vertical movement
	local verticalDirection = 0
	if keysDown[Enum.KeyCode.Space] then verticalDirection = 1 end
	if keysDown[Enum.KeyCode.LeftShift] then verticalDirection = -1 end

	-- Combine horizontal and vertical movement and apply speed
	local finalVelocity = (moveDirection.Unit * FLIGHT_SPEED)
	if moveDirection.Magnitude == 0 then
		finalVelocity = Vector3.new(0, 0, 0) -- Stop if no WASD keys are pressed
	end

	flightMovers.BodyVelocity.Velocity = finalVelocity + Vector3.new(0, verticalDirection * FLIGHT_SPEED, 0)
end

-- This function runs once the server gives us permission to fly
local function onFlightPermissionGranted()
	if canFly then return end -- Run only once
	canFly = true

	-- Connect key press listeners
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F then
			toggleFlight()
		else
			keysDown[input.KeyCode] = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		keysDown[input.KeyCode] = nil
	end)

	-- Connect the main update loop
	RunService.Heartbeat:Connect(updateFlight)

	-- Handle character death/respawn
	player.CharacterAdded:Connect(function()
		isFlying = false
		destroyFlightMovers()
	end)
end

-- Listen for the server's signal
enableFlightEvent.OnClientEvent:Connect(onFlightPermissionGranted)