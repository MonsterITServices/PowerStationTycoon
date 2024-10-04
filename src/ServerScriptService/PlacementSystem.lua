-- Server-Side Script: PlacementSystem
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local restoreEvent = Instance.new("RemoteEvent")
restoreEvent.Name = "restoreEvent"
restoreEvent.Parent = ReplicatedStorage

local placementEvent = Instance.new("RemoteEvent")
placementEvent.Name = "PlacementEvent"
placementEvent.Parent = ReplicatedStorage

local placeEvent = Instance.new("RemoteEvent")
placeEvent.Name = "PlaceEvent"
placeEvent.Parent = ReplicatedStorage

-- Table to store placed blocks and plot names for each player
local playerBlocks = {}
local playerPlots = {}

-- Function to load the player's plot using PlotManager's getPlotFunction
local function loadPlayerPlot(player)
	local getPlotFunction = game:GetService("ReplicatedStorage"):WaitForChild("GetPlotFunction")
	local plotName = getPlotFunction:InvokeServer(player)

	if plotName then
		print("Plot found for player:", player.Name, "Plot:", plotName)

		-- Store the plot name in playerPlots
		playerPlots[player.UserId] = plotName

		-- Check if the plot exists in the workspace
		local plot = game.Workspace.Plots:FindFirstChild(plotName)
		if plot then
			print("Plot exists in the workspace:", plot.Name)
			-- Optionally assign the plot to the player here (e.g., tag the plot as belonging to the player)
		else
			warn("Plot not found in workspace for player:", player.Name, "Plot:", plotName)
		end
	else
		warn("No plot found for player:", player.Name)
	end
end

-- Function to save the player's plot using PlotManager's setPlotEvent
local function savePlayerPlot(player)
	local plotName = playerPlots[player.UserId]
	if plotName then
		local setPlotEvent = game:GetService("ReplicatedStorage"):WaitForChild("SetPlotEvent")
		setPlotEvent:FireServer(player, plotName)
		print("Plot saved for player:", player.Name, "Plot:", plotName)
	else
		warn("No plot to save for player:", player.Name)
	end
end

-- Listen for when a player joins the game and load their plot
Players.PlayerAdded:Connect(loadPlayerPlot)

-- Listen for when a player leaves the game and save their plot
Players.PlayerRemoving:Connect(savePlayerPlot)

-- Function to clear a player's plot
local function clearPlayerPlot(userId)
	local oldPlotIdentifier = playerPlots[userId]
	if oldPlotIdentifier then
		local oldPlot = game.Workspace.Plots:FindFirstChild(oldPlotIdentifier)
		if oldPlot then
			for _, child in pairs(oldPlot:GetChildren()) do
				child:Destroy()
			end
		end
		playerPlots[userId] = nil -- Remove the plot from the playerPlots table
	end
end

-- Function to find a block in groups
local function findBlockInGroups(group, blockName)
	for _, category in pairs(group:GetChildren()) do
		if category:IsA("Folder") or category:IsA("Model") then  -- Checks if it's a folder or model
			for _, block in pairs(category:GetChildren()) do
				if block.Name == blockName and block:IsA("Model") then
					return block
				end
			end
		end
	end
	return nil
end
-- Event handler for block placement
local function onPlaceEvent(player, blockName, position, rotation)
	print("onPlaceEvent triggered", player.Name, blockName, position, rotation)

	-- Retrieve the player's plot
	local plotIdentifier = playerPlots[player.UserId]
	if not plotIdentifier then
		warn("Plot identifier not found for the player: " .. player.Name)
		return
	end

	local plot = game.Workspace.Plots:FindFirstChild(plotIdentifier)
	if not plot then
		warn("Plot not found: " .. plotIdentifier)
		return
	end

	local blockFound = findBlockInGroups(ReplicatedStorage.Builder, blockName)
	if blockFound then
		-- Proceed with placement logic
	else
		warn("Block not found: ", blockName)
	end

	-- Find the block model to place
	local blockToPlace = findBlockInGroups(ReplicatedStorage.Builder, blockName) -- Adjust path as necessary
	if not blockToPlace then
		warn("Block not found: " .. blockName)
		return
	end
	blockToPlace = blockToPlace:Clone()

	-- Calculate the correct placement position relative to the plot
	local worldPosition = position  -- Assuming position is already in world space
	local worldRotation = CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	local finalCFrame = CFrame.new(worldPosition) * worldRotation

	-- Set the block's position and parent
	blockToPlace:PivotTo(finalCFrame)
	blockToPlace.Parent = plot

	-- Ensure the block is anchored
	for _, part in pairs(blockToPlace:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Optionally update the player's blocks list and perform further checks
	print("Block placed successfully:", blockName, "at", worldPosition)
end

placeEvent.OnServerEvent:Connect(onPlaceEvent)

-- Function to save player blocks
local function savePlayerBlocks(player)
	if not player then

		return
	end
	local userId = player.UserId
	if not userId then

		return
	end
	local blocks = playerBlocks[userId]
	local plotIdentifier = playerPlots[userId]
	if not blocks and not plotIdentifier then
		-- You can use print instead of warn if you prefer.

		return
	elseif not blocks then

		return
	elseif not plotIdentifier then

		return
	end

	local plot = game.Workspace.Plots:FindFirstChild(plotIdentifier)
	if not plot then

		return
	end

	if blocks and plot then
		local plotPosition = plot.Position
		local blockData = {}

		for _, block in pairs(blocks) do
			local position
			if block:IsA("Part") then
				position = block.Position - plotPosition
			elseif block:IsA("Model") and block.PrimaryPart then
				position = block.PrimaryPart.Position - plotPosition
			else

				position = Vector3.new(0, 0, 0)
			end
			table.insert(blockData, {Name = block.Name, Position = {position.X, position.Y, position.Z}})
		end

		local jsonBlockData = HttpService:JSONEncode(blockData)

		local success, errorMessage = pcall(function()
			myDataStore:SetAsync(userId, jsonBlockData)
		end)

		if not success then

		else

		end
	end
end
--RESTORE blocks using json
local function findBlockInGroups(group, blockName)
	for _, child in pairs(group:GetChildren()) do
		if child.Name == blockName then
			return child
		elseif child:IsA("Folder") or child:IsA("Model") then
			local foundBlock = findBlockInGroups(child, blockName)
			if foundBlock then return foundBlock end
		end
	end
	return nil
end

-- Listen for when a player leaves to save their blocks
Players.PlayerRemoving:Connect(savePlayerBlocks)

-- Restore blocks using json
local function restoreBlocks(player, plotName)
	if not player then

		return
	end

	local userId = player.UserId
	clearPlayerPlot(userId)
	local plotIdentifier = plotName or playerPlots[userId]
	playerPlots[userId] = plotIdentifier
	local plot = game.Workspace.Plots:FindFirstChild(plotIdentifier)

	if plot then
		local plotPosition = plot.Position
		local success, jsonBlockData = pcall(function()
			return myDataStore:GetAsync(userId)
		end)

		if success and jsonBlockData then

			local blockData
			local decodeSuccess, errorMessage = pcall(function()
				blockData = HttpService:JSONDecode(jsonBlockData)
			end)

			if not decodeSuccess then

				return
			end



			for _, data in pairs(blockData) do
				local blockToPlace = findBlockInGroups(ReplicatedStorage.Builder, data.Name)
				if not blockToPlace then

					return
				end

				blockToPlace = blockToPlace:Clone()
				local relativePosition = Vector3.new(unpack(data.Position))
				if blockToPlace then
					if blockToPlace:IsA("Model") and blockToPlace.PrimaryPart then
						blockToPlace:SetPrimaryPartCFrame(CFrame.new(plotPosition + relativePosition))
					elseif blockToPlace:IsA("Part") then
						blockToPlace.Position = plotPosition + relativePosition
					end
					blockToPlace.Parent = plot

					-- Handle anchoring correctly for both Model and Part
					if blockToPlace:IsA("Model") then
						for _, part in pairs(blockToPlace:GetDescendants()) do
							if part:IsA("Part") then
								part.Anchored = true
							end
						end
					elseif blockToPlace:IsA("Part") then
						blockToPlace.Anchored = true
					else

					end

				else

				end
			end
		else

		end
	else

	end
end

-- Listen for the restore event
restoreEvent.OnServerEvent:Connect(restoreBlocks)