-- LocalScript: DeleteController
-- This script handles the client-side logic for deleting placed items, including a visual highlight, a tooltip, and a confirmation dialog with a delay.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Wait for the DeleteEvent to be created by the server
local deleteEvent = ReplicatedStorage:WaitForChild("DeleteEvent")

-- ====================================================================
-- GUI CREATION
-- ====================================================================

local itemPendingDeletion = nil
local lastUiInteractionTime = 0 -- For debouncing touch input

-- Function to create the confirmation GUI
local function createConfirmationGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeleteConfirmationGui"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Name = "ConfirmationFrame"
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(80, 80, 80)
	frame.Visible = false
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Text = "Are you sure?"
	title.Font = Enum.Font.SourceSansBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	title.Parent = frame

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Size = UDim2.new(1, -20, 0, 40)
	message.Position = UDim2.new(0, 10, 0, 55)
	message.Text = "Do you want to delete this item?"
	message.Font = Enum.Font.SourceSans
	message.TextColor3 = Color3.fromRGB(220, 220, 220)
	message.TextSize = 18
	message.TextWrapped = true
	message.BackgroundTransparency = 1
	message.Parent = frame

	local yesButton = Instance.new("TextButton")
	yesButton.Name = "YesButton"
	yesButton.Size = UDim2.new(0, 100, 0, 40)
	yesButton.Position = UDim2.new(0.5, -110, 1, -50)
	yesButton.Text = "Yes"
	yesButton.Font = Enum.Font.SourceSansBold
	yesButton.TextSize = 20
	yesButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	yesButton.Parent = frame

	local noButton = Instance.new("TextButton")
	noButton.Name = "NoButton"
	noButton.Size = UDim2.new(0, 100, 0, 40)
	noButton.Position = UDim2.new(0.5, 10, 1, -50)
	noButton.Text = "No"
	noButton.Font = Enum.Font.SourceSansBold
	noButton.TextSize = 20
	noButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	noButton.Parent = frame

	yesButton.MouseButton1Click:Connect(function()
		if not yesButton.Interactable then return end
		lastUiInteractionTime = tick() -- Record time of UI tap
		if itemPendingDeletion then
			deleteEvent:FireServer(itemPendingDeletion)
		end
		frame.Visible = false
		itemPendingDeletion = nil
	end)

	noButton.MouseButton1Click:Connect(function()
		lastUiInteractionTime = tick() -- Record time of UI tap
		frame.Visible = false
		itemPendingDeletion = nil
	end)

	screenGui.Parent = playerGui
	return frame, yesButton
end

-- Function to create the Tooltip GUI
local function createTooltipGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DeleteTooltipGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 1

	local label = Instance.new("TextLabel")
	label.Name = "TooltipLabel"
	label.Size = UDim2.new(0, 180, 0, 25)
	label.Text = "Press H / Tap to delete"
	label.Font = Enum.Font.SourceSans
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.4
	label.BorderSizePixel = 1
	label.BorderColor3 = Color3.fromRGB(120, 120, 120)
	label.Visible = false
	label.Parent = screenGui

	screenGui.Parent = playerGui
	return label
end

-- Create the GUIs
local confirmationFrame, yesButton = createConfirmationGui(player.PlayerGui)
local tooltipLabel = createTooltipGui(player.PlayerGui)

-- ====================================================================
-- HIGHLIGHTING & TOOLTIP LOGIC
-- ====================================================================

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 50, 50)
highlight.OutlineColor = Color3.fromRGB(255, 25, 25)
highlight.FillTransparency = 0.8
highlight.OutlineTransparency = 0.3

local currentHighlightedItem = nil

-- Correctly finds the item model from one of its descendant parts
local function getItemModelFromDescendant(descendant)
	if not descendant then return nil end
	local current = descendant
	while current and current.Parent do
		if current.Parent.Parent and current.Parent.Parent.Name == "Plots" and current:IsA("Model") then
			return current
		end
		current = current.Parent
	end
	return nil
end

-- This function runs every frame to update the highlight and tooltip
RunService.RenderStepped:Connect(function()
	if confirmationFrame.Visible then 
		if highlight.Parent then highlight.Parent = nil end
		tooltipLabel.Visible = false
		return 
	end

	local target = mouse.Target
	local itemModel = nil

	if target then
		itemModel = getItemModelFromDescendant(target)
	end

	if itemModel and itemModel ~= currentHighlightedItem then
		currentHighlightedItem = itemModel
		highlight.Adornee = currentHighlightedItem
		highlight.Parent = currentHighlightedItem
		tooltipLabel.Visible = true
	elseif not itemModel and currentHighlightedItem then
		currentHighlightedItem = nil
		highlight.Parent = nil
		highlight.Adornee = nil
		tooltipLabel.Visible = false
	end

	if tooltipLabel.Visible then
		tooltipLabel.Position = UDim2.new(0, mouse.X + 15, 0, mouse.Y + 15)
	end
end)

-- ====================================================================
-- INPUT HANDLING
-- ====================================================================

local function requestDeletion()
	if currentHighlightedItem then
		itemPendingDeletion = currentHighlightedItem
		confirmationFrame.Visible = true

		-- Disable the 'Yes' button and start the countdown
		yesButton.Interactable = false
		yesButton.Text = "Yes (2)"

		spawn(function()
			wait(1)
			if not confirmationFrame.Visible or not itemPendingDeletion then return end
			yesButton.Text = "Yes (1)"

			wait(1)
			if not confirmationFrame.Visible or not itemPendingDeletion then return end
			yesButton.Text = "Yes"
			yesButton.Interactable = true
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.H then
		requestDeletion()
	end
end)

UserInputService.TouchTap:Connect(function(touchPositions, gameProcessedEvent)
	if gameProcessedEvent then return end

	-- Ignore taps that happen immediately after closing the UI
	if tick() - lastUiInteractionTime < 0.2 then return end

	requestDeletion()
end)
