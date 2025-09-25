-- Client-Side Script: ControlHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placementEvent = ReplicatedStorage:WaitForChild("PlacementEvent")

local selectedBlock = nil -- This should be set by the PlacementGuiScript or some similar mechanism

-- Flags
local isMobile = UserInputService.TouchEnabled

-- Movement and Rotation variables
local moveStep = 0.1
local rotateStep = 10

local touchInitialPosition = nil -- To store the initial touch position

-- Dummy function to get the player's plot (replace with your actual function)
local function getPlayersPlot(player)
	return workspace:FindFirstChild(player.Name .. "_Plot")
end

-- Keep track of the position and rotation
local blockPosition = Vector3.new()
local blockRotation = Vector3.new() -- Rotation in degrees

local function placeBlock(blockName, plotIdentifier)
	local position = Vector3.new(1, 2, 3) -- Replace with actual position logic
	local rotation = Vector3.new(0, 90, 0) -- Replace with actual rotation logic

	-- Ensure position and rotation are valid
	if position and rotation then
		print("Sending position and rotation to server:", position, rotation) 
		placementEvent:FireServer("place", blockName, plotIdentifier, position, rotation)
	else
		warn("Invalid position or rotation.")
	end
end

-- Update the position and rotation of the block
local function updateBlockPlacement()
	if not selectedBlock then return end

	-- Here you can implement a more complex system to choose the block's position
	blockPosition = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or Vector3.new()
	blockRotation = Vector3.new(0, 0, 0) -- Default rotation, modify as needed

	selectedBlock.Position = blockPosition + Vector3.new(0, 5, 0) -- Offset by 5 studs above the player
end

-- Keyboard Controls
local function handleKeyboard(input)
	if not selectedBlock then return end

	if input.KeyCode == Enum.KeyCode.Space then
		-- Send position and rotation to the server
		local plot = getPlayersPlot(player)
		local plotIdentifier = plot and plot.Name or ""
		placementEvent:FireServer("place", selectedBlock, plotIdentifier, blockPosition, blockRotation)
		selectedBlock = nil
	else
		-- Handle rotation and other controls
	end
end

-- Touch Controls
local function handleTouchTap()
	if selectedBlock then
		-- Send position and rotation to the server
		local plot = getPlayersPlot(player)
		local plotIdentifier = plot and plot.Name or ""
		placementEvent:FireServer("place", selectedBlock, plotIdentifier, blockPosition, blockRotation)
		selectedBlock = nil
	end
end

local function handlePlayerMovement()
	updateBlockPlacement()
end

-- Main Input Handling
local function handleInput(input, gameProcessed)
	if gameProcessed then
		return
	end

	if isMobile then
		-- Touch controls are handled in their own functions
	else
		handleKeyboard(input)
	end
end

-- Setup
UserInputService.InputBegan:Connect(handleInput)
UserInputService.TouchTap:Connect(handleTouchTap)

-- Make the selected block follow the player
game:GetService("RunService").Heartbeat:Connect(handlePlayerMovement)
