-- Client-Side Script: PlacementGuiScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local user = Players.LocalPlayer
local placementEvent = ReplicatedStorage:WaitForChild("PlacementEvent")
local getPlotFunction = ReplicatedStorage:WaitForChild("GetPlotFunction")  -- Add this line

local showGridEvent = ReplicatedStorage:FindFirstChild("ShowGridEvent")
if not showGridEvent then
	showGridEvent = Instance.new("BindableEvent")
	showGridEvent.Name = "ShowGridEvent"
	showGridEvent.Parent = ReplicatedStorage
end

local hideGridEvent = ReplicatedStorage:FindFirstChild("HideGridEvent")
if not hideGridEvent then
	hideGridEvent = Instance.new("BindableEvent")
	hideGridEvent.Name = "HideGridEvent"
	hideGridEvent.Parent = ReplicatedStorage
end

local leaderstats = user:WaitForChild("leaderstats")  -- Wait for leaderstats to be available
local moneyValue = leaderstats:WaitForChild("Money")  -- Wait for Money to be available

local getSetMoney = ReplicatedStorage:WaitForChild("GetSetMoney")

-- Function to handle leaderboard setup
local function handleLeaderboardSetup()

end

local leaderboardSetupEvent = ReplicatedStorage:WaitForChild("LeaderboardSetupEvent", 5)
if leaderboardSetupEvent then
	leaderboardSetupEvent.OnClientEvent:Connect(handleLeaderboardSetup)
else

end

local buildConfigs = script.Parent
local blocksShowcase = buildConfigs:WaitForChild("BlocksShowcase")
local scrollFrame = blocksShowcase:WaitForChild("ScrollFrame")
local openGuiButton = buildConfigs:WaitForChild("OpenGui")

local closeButton = blocksShowcase:FindFirstChild("Close")

local placeEvent = ReplicatedStorage:WaitForChild("PlaceEvent")

local selectedBlock = nil
local previewBlock = nil
local isPreviewing = false
local updatePreviewConnection = nil
local placeItemButton = buildConfigs:WaitForChild("PlaceItemButton")  -- Adjust according to its actual location
local cancelButton = buildConfigs:WaitForChild("CancelButton")  -- Assuming you have a CancelButton in your UI
local function updatePreview()
	if isPreviewing and previewBlock then
		local mousePosition = UserInputService:GetMouseLocation()
		local camera = workspace.CurrentCamera
		local ray = camera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {user.Character, previewBlock}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

		local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 500, raycastParams) -- Adjust the distance as needed
		if raycastResult then
			local plotName = getPlotFunction:InvokeServer()
			if previewBlock and plotName then
				local plot = game.Workspace.Plots:FindFirstChild(plotName)
				if plot then
					local plotPart = plot:FindFirstChild(plotName)
					if raycastResult.Instance == plotPart then
						for _, part in pairs(previewBlock:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Color = Color3.new(0, 1, 0) -- Green
							end
						end
						placeItemButton.Visible = true
					else
						for _, part in pairs(previewBlock:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Color = Color3.new(1, 0, 0) -- Red
							end
						end
						placeItemButton.Visible = false
					end
				end
				local hitPosition = raycastResult.Position
				local placementPosition = hitPosition + Vector3.new(0, previewBlock.PrimaryPart.Size.Y / 2, 0) -- Adjust the height offset as needed
				previewBlock:SetPrimaryPartCFrame(CFrame.new(placementPosition))
			end
		end
	end
end

local function startPreview(selectedBlockModel)
	if not selectedBlockModel then
		warn("No block selected for preview")
		return
	end

	if previewBlock then
		previewBlock:Destroy()  -- Remove any existing preview block
	end

	previewBlock = selectedBlockModel:Clone()
	previewBlock.Parent = workspace  -- Place it in the workspace
	for _, part in pairs(previewBlock:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 0.5  -- Making the block semi-transparent
			part.CanCollide = false  -- Ensure it doesn't collide with other objects
		end
	end

	isPreviewing = true  -- Set the previewing flag
	if cancelButton then
		cancelButton.Visible = true
	else
		warn("CancelButton not found")
	end
	if not updatePreviewConnection then
		updatePreviewConnection = game:GetService("RunService").Heartbeat:Connect(updatePreview)
	end
end




local cancelButton = buildConfigs:WaitForChild("CancelButton")  -- Assuming you have a CancelButton in your UI

local function handlePlaceItemButtonClick()
	print("PlaceItemButton clicked")  -- Debug message
	if selectedBlock then
		local plotName = getPlotFunction:InvokeServer()  -- Get the plot name associated with the player
		print("Plot Name:", plotName)  -- Debug message
		if plotName and previewBlock and previewBlock.PrimaryPart then
			local position = previewBlock.PrimaryPart.Position
			local rotation = previewBlock.PrimaryPart.Orientation
			print("Sending placement data to server:", selectedBlock.Name, position, rotation)  -- Debug message
			-- Fire the PlaceEvent with the necessary information
			placeEvent:FireServer(selectedBlock.Name, position, rotation)

			-- Clean up after placing the block
			previewBlock:Destroy()
			previewBlock = nil
			isPreviewing = false
			selectedBlock = nil
			placeItemButton.Visible = false
			cancelButton.Visible = false
			if updatePreviewConnection then
				updatePreviewConnection:Disconnect()
				updatePreviewConnection = nil
			end
			print("Placement data sent to server.")
		else
			warn("No plot found or preview block is invalid.")
		end
	else
		warn("No block selected for placement.")
	end
end


if placeItemButton then	
	placeItemButton.MouseButton1Click:Connect(handlePlaceItemButtonClick)
end
local function handleCancelButtonClick()
	if isPreviewing and previewBlock then
		previewBlock:Destroy()
		previewBlock = nil
		isPreviewing = false
		selectedBlock = nil
		placeItemButton.Visible = false
		cancelButton.Visible = false
		if updatePreviewConnection then
			updatePreviewConnection:Disconnect()
			updatePreviewConnection = nil
		end
		hideGridEvent:Fire()
	end
end

if cancelButton then
	cancelButton.MouseButton1Click:Connect(handleCancelButtonClick)
end
local function tryPlaceBlock()
	if selectedBlock and isPreviewing and previewBlock and previewBlock.PrimaryPart then
		local position = previewBlock.PrimaryPart.Position
		local rotation = previewBlock.PrimaryPart.Orientation
		placeEvent:FireServer(selectedBlock.Name, position, rotation)
		-- Clean up
		selectedBlock = nil
		previewBlock:Destroy()
		previewBlock = nil
		isPreviewing = false
		if placeItemButton then
			placeItemButton.Visible = false
		end
		if cancelButton then
			cancelButton.Visible = false
		end
	else
		warn("No block selected or no preview block available.")
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.E and selectedBlock and isPreviewing and previewBlock and previewBlock.PrimaryPart then
		local position = previewBlock.PrimaryPart.Position -- Corrected to use PrimaryPart
		local rotation = Vector3.new(0, 0, 0) -- Adjust if you have rotation logic
		placeEvent:FireServer(selectedBlock.Name, position, rotation)
	end
end)



local placeEvent = ReplicatedStorage:WaitForChild("PlaceEvent")
local function finalizePlacement()
	if isPreviewing and previewBlock and selectedBlock then
		if previewBlock.PrimaryPart then
			local position = previewBlock.PrimaryPart.Position
			local rotation = previewBlock.PrimaryPart.Orientation -- Ensure these are not nil

			-- Debug print
			print("Attempting to place - Position:", position, "Rotation:", rotation)

			if position and rotation then
				placeEvent:FireServer(selectedBlock.Name, position, rotation)
				print("Sent to server - Position:", position, "Rotation:", rotation)
			else
				warn("Position or Rotation is nil")
			end
		else
			warn("previewBlock does not have a PrimaryPart set")
		end

		-- Cleanup
		previewBlock:Destroy()
		previewBlock = nil
		isPreviewing = false
		selectedBlock = nil

		if placeItemButton then
			placeItemButton.Visible = false
		else
			warn("placeItemButton not found")
		end

		if cancelButton then
			cancelButton.Visible = false
		else
			warn("cancelButton not found")
		end
	end
end




-- Function to toggle BlocksShowcase GUI visibility
local function toggleGui()
	blocksShowcase.Visible = not blocksShowcase.Visible
	if blocksShowcase.Visible then
		showGridEvent:Fire()
	else
		hideGridEvent:Fire()
	end
end

-- Function to close BlocksShowcase GUI
local function closeGui()
	blocksShowcase.Visible = false
	hideGridEvent:Fire()
end

-- Create and configure UIGridLayout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.CellSize = UDim2.new(0, 128, 0, 128)
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

-- Populating blocks
for _, category in pairs({"Builds", "Decoration", "Interior"}) do
	local categoryFolder = ReplicatedStorage:FindFirstChild("Builder"):FindFirstChild(category)
	if categoryFolder then

		for _, block in pairs(categoryFolder:GetChildren()) do
			if block:IsA("Model") then
				local cost = block:FindFirstChild("Cost")
				if cost then

					local blockButton = Instance.new("TextButton")
					blockButton.Size = UDim2.new(0, 128, 0, 128)
					blockButton.BackgroundColor3 = Color3.fromRGB(236,236,236)  -- Background color of the button
					blockButton.Text = ""
					blockButton.TextColor3 = Color3.fromRGB(0, 0, 0)  -- Text color of the button (not applicable here since Text is empty)
					blockButton.Parent = scrollFrame

					local viewport = Instance.new("ViewportFrame")
					viewport.Size = UDim2.new(1, 0, 1, 0)  -- Fill the entire TextButton
					viewport.Parent = blockButton
					viewport.BackgroundColor3 = Color3.fromRGB(236,236,236)

					local camera = Instance.new("Camera")
					camera.Parent = viewport
					viewport.CurrentCamera = camera
					camera.CameraType = Enum.CameraType.Scriptable
					if block.PrimaryPart then
						camera.CFrame = CFrame.new(block.PrimaryPart.Position + Vector3.new(5, 5, 5), block.PrimaryPart.Position)
					end

					local rotationCFrame = CFrame.Angles(0, math.rad(10), 0)  -- Rotating 10 degrees around Y-axis

					if block.PrimaryPart then
						local targetPosition = block.PrimaryPart.Position
						local originalPosition = targetPosition + Vector3.new(5, 5, 5)
						local originalCFrame = CFrame.new(originalPosition, targetPosition)

						-- Apply rotation to the original CFrame and re-adjust the position
						local rotatedCFrame = originalCFrame * rotationCFrame
						local newPosition = rotatedCFrame.Position
						camera.CFrame = CFrame.new(newPosition, targetPosition)
					end

					local costLabel = Instance.new("TextLabel")
					costLabel.Size = UDim2.new(1, 0, 0, 20)
					costLabel.Position = UDim2.new(0, 0, 1, -20)
					costLabel.Text = " " .. block.Name .. " | " .. cost.Value
					costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Text color of the label
					costLabel.BackgroundColor3 = Color3.fromRGB(85, 85, 0)  -- Background color of the label
					costLabel.Parent = blockButton

					local displayBlock = block:Clone()
					displayBlock.Parent = viewport

					-- Add rotation here
					local rotationCFrame = CFrame.Angles(0, math.rad(210), 0)  -- Rotating 10 degrees around Y-axis
					displayBlock:SetPrimaryPartCFrame(displayBlock.PrimaryPart.CFrame * rotationCFrame)
					local currentlySelectedButton = nil
					blockButton.MouseButton1Click:Connect(function()
						selectedBlock = block
						startPreview(selectedBlock)  -- Start the preview (ensure this function is defined correctly)
						placeItemButton.Visible = true  -- Show the "Place Item" button
						blocksShowcase.Visible = false  -- Close the blocksShowcase GUI
						if currentlySelectedButton then
							-- Reset the appearance of the previously selected button
							currentlySelectedButton.BackgroundColor3 = Color3.fromRGB(236, 236, 236)
						end
						-- Change the appearance of the current button to indicate selection
						blockButton.BackgroundColor3 = Color3.fromRGB(210, 210, 210)
						currentlySelectedButton = blockButton
					end)
				else

				end
			else

			end
		end
	else

	end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		handleCancelButtonClick()
	end
end)


-- Connect the OpenGui button to toggle GUI
if openGuiButton then
	openGuiButton.MouseButton1Click:Connect(toggleGui)
end

-- Connect the Close button to close GUI
if closeButton then
	closeButton.MouseButton1Click:Connect(closeGui)
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local restoreEvent = ReplicatedStorage:WaitForChild("restoreEvent")

local restoreButton = script.Parent:FindFirstChild("RestoreButton")  -- Replace with the actual path to your Restore button

if restoreButton then
	restoreButton.MouseButton1Click:Connect(function()
		restoreEvent:FireServer()
	end)
end