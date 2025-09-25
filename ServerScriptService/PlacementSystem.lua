-- Server-Side Script: PlacementSystem
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")

local SharedData = require(game.ServerScriptService:WaitForChild("SharedData"))
local playerPlots = SharedData.playerPlots -- Use the shared playerPlots table from SharedData without redefining
local playerBlocks = {}
local myDataStore = DataStoreService:GetDataStore("PlayerBlocksDataStore")

-- Create or get necessary RemoteEvents
local restoreEvent = ReplicatedStorage:FindFirstChild("restoreEvent")
if not restoreEvent then
	restoreEvent = Instance.new("RemoteEvent")
	restoreEvent.Name = "restoreEvent"
	restoreEvent.Parent = ReplicatedStorage
end

local placementEvent = ReplicatedStorage:FindFirstChild("PlacementEvent")
if not placementEvent then
	placementEvent = Instance.new("RemoteEvent")
	placementEvent.Name = "PlacementEvent"
	placementEvent.Parent = ReplicatedStorage
end

local placeEvent = ReplicatedStorage:FindFirstChild("PlaceEvent")
if not placeEvent then
	placeEvent = Instance.new("RemoteEvent")
	placeEvent.Name = "PlaceEvent"
	placeEvent.Parent = ReplicatedStorage
end

local deleteEvent = ReplicatedStorage:FindFirstChild("DeleteEvent")
if not deleteEvent then
	deleteEvent = Instance.new("RemoteEvent")
	deleteEvent.Name = "DeleteEvent"
	deleteEvent.Parent = ReplicatedStorage
end

-- =================================================================
-- MODIFIED FUNCTION
-- =================================================================
-- This function now takes the plotIdentifier directly to avoid race conditions.
local function clearPlayerPlot(plotIdentifier)
	if plotIdentifier then
		local oldPlot = game.Workspace.Plots:FindFirstChild(plotIdentifier)
		if oldPlot then
			for _, child in pairs(oldPlot:GetChildren()) do
				if CollectionService:HasTag(child, "PlayerBlock") then
					child:Destroy()
				end
			end
		end
		-- The line that unassigned the plot is removed from here.
		-- PlotManager is now solely responsible for plot assignment.
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

local function isPositionInPlot(position, plotPart)
	local plotSize = plotPart.Size
	local plotCFrame = plotPart.CFrame
	local localPosition = plotCFrame:PointToObjectSpace(position)

	if math.abs(localPosition.X) <= plotSize.X / 2 and
		math.abs(localPosition.Z) <= plotSize.Z / 2 then
		return true
	end
	return false
end

-- Event handler for block placement
local function onPlaceEvent(player, blockName, position, rotation)
	print("onPlaceEvent triggered", player.Name, blockName, position, rotation)
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

	local plotPart = plot:FindFirstChild(plotIdentifier)
	if not plotPart then
		warn("Plot part not found: " .. plotIdentifier)
		return
	end

	if not isPositionInPlot(position, plotPart) then
		warn("Player " .. player.Name .. " tried to place an object outside their plot.")
		return
	end

	local blockToPlace = findBlockInGroups(ReplicatedStorage.Builder, blockName)
	if not blockToPlace then
		warn("Block not found: " .. blockName)
		return
	end
	blockToPlace = blockToPlace:Clone()

	local worldPosition = position
	local worldRotation = CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

	blockToPlace:SetPrimaryPartCFrame(CFrame.new(worldPosition) * worldRotation)
	blockToPlace.Parent = plot
	CollectionService:AddTag(blockToPlace, "PlayerBlock")

	for _, part in pairs(blockToPlace:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	if not playerBlocks[player.UserId] then
		playerBlocks[player.UserId] = {}
	end
	table.insert(playerBlocks[player.UserId], blockToPlace)

	print("Block placed successfully:", blockName, "at", worldPosition)
end

placeEvent.OnServerEvent:Connect(onPlaceEvent)

-- =================================================================
-- MODIFIED FUNCTION
-- =================================================================
-- This function now takes the plotIdentifier directly.
local function savePlayerBlocks(player, plotIdentifier)
	if not player then return end
	local userId = player.UserId
	if not userId then return end

	local blocks = playerBlocks[userId]
	if not plotIdentifier then
		warn("Plot identifier not found for userId: " .. tostring(userId))
		return
	end

	local plotGroup = game.Workspace.Plots:FindFirstChild(plotIdentifier)
	if not plotGroup then
		warn("Plot group not found for identifier: " .. tostring(plotIdentifier))
		return
	end

	local plot = plotGroup:FindFirstChildWhichIsA("BasePart")
	if not plot then
		warn("Primary part not found in plot group for identifier: " .. tostring(plotIdentifier))
		return
	end

	local plotPosition = plot.Position
	local blockData = {}

	if type(blocks) == "table" then
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
	else
		warn("Blocks for userId " .. tostring(userId) .. " are not in the expected format.")
		return
	end

	local jsonBlockData = HttpService:JSONEncode(blockData)
	local success, errorMessage = pcall(function()
		myDataStore:SetAsync(userId, jsonBlockData)
	end)

	if not success then
		warn("Failed to save player blocks: " .. tostring(errorMessage))
	end
end

-- Restore blocks using json
local function restoreBlocks(player, plotName)
	if not player then return end
	local userId = player.UserId

	-- We still clear the plot, but using the modified function
	local oldPlotIdentifier = playerPlots[userId]
	clearPlayerPlot(oldPlotIdentifier)

	local plotIdentifier = plotName or playerPlots[userId]
	playerPlots[userId] = plotIdentifier
	local plotGroup = game.Workspace.Plots:FindFirstChild(plotIdentifier)

	if plotGroup then
		local plotPart = plotGroup:FindFirstChild(plotIdentifier)
		if not plotPart or not plotPart:IsA("Part") then
			warn("Primary part not found in plot group for identifier: " .. tostring(plotIdentifier))
			return
		end
		local plotPosition = plotPart.Position
		local success, jsonBlockData = pcall(function()
			return myDataStore:GetAsync(userId)
		end)
		if success and jsonBlockData then
			local blockData
			local decodeSuccess, errorMessage = pcall(function()
				blockData = HttpService:JSONDecode(jsonBlockData)
			end)
			if decodeSuccess then
				playerBlocks[userId] = {}
				for _, data in pairs(blockData) do
					local blockToPlace = findBlockInGroups(ReplicatedStorage.Builder, data.Name)
					if blockToPlace then
						blockToPlace = blockToPlace:Clone()
						local relativePosition = Vector3.new(unpack(data.Position))
						if blockToPlace:IsA("Model") and blockToPlace.PrimaryPart then
							blockToPlace:SetPrimaryPartCFrame(CFrame.new(plotPosition + relativePosition))
						elseif blockToPlace:IsA("Part") then
							blockToPlace.Position = plotPosition + relativePosition
						end
						blockToPlace.Parent = plotGroup
						CollectionService:AddTag(blockToPlace, "PlayerBlock")
						table.insert(playerBlocks[userId], blockToPlace)
						if blockToPlace:IsA("Model") then
							for _, part in pairs(blockToPlace:GetDescendants()) do
								if part:IsA("BasePart") then
									part.Anchored = true
								end
							end
						elseif blockToPlace:IsA("BasePart") then
							blockToPlace.Anchored = true
						end
					end
				end
			else
				warn("Failed to decode block data for player: " .. player.Name)
			end
		else
			warn("Failed to retrieve block data for player: " .. player.Name)
		end
	else
		warn("Plot not found for restoration: " .. tostring(plotIdentifier))
	end
end

-- Function to handle the server-side deletion of an item
local function onDeleteEvent(player, itemToDelete)
	if not itemToDelete or not itemToDelete:IsA("Model") then
		warn("Delete request for an invalid item from player: " .. player.Name)
		return
	end
	local plotIdentifier = playerPlots[player.UserId]
	if not plotIdentifier then
		warn("Player " .. player.Name .. " does not have a plot.")
		return
	end
	local plot = game.Workspace.Plots:FindFirstChild(plotIdentifier)
	if not plot then
		warn("Plot not found for player: " .. player.Name)
		return
	end
	if itemToDelete.Parent ~= plot then
		warn("Player " .. player.Name .. " attempted to delete an item they do not own.")
		return
	end
	local userId = player.UserId
	if playerBlocks[userId] then
		for i, block in ipairs(playerBlocks[userId]) do
			if block == itemToDelete then
				table.remove(playerBlocks[userId], i)
				break
			end
		end
	end
	itemToDelete:Destroy()
	print("Item " .. itemToDelete.Name .. " deleted successfully by " .. player.Name)
end

-- Listen for the restore event
restoreEvent.OnServerEvent:Connect(restoreBlocks)

-- =================================================================
-- NEW AND IMPROVED PLAYER REMOVING LOGIC
-- =================================================================
local function onPlayerRemoving(player)
	-- IMPORTANT: Get the plot identifier ONCE, right at the start.
	local plotIdentifier = playerPlots[player.UserId]

	-- If the player had no plot, there's nothing to do.
	if not plotIdentifier then
		return
	end

	-- Now, pass the saved plotIdentifier to the functions.
	-- This will work even if PlotManager clears the assignment in the meantime.
	print("Saving blocks for leaving player: " .. player.Name .. " from plot " .. plotIdentifier)
	savePlayerBlocks(player, plotIdentifier)

	print("Clearing items from plot " .. plotIdentifier)
	clearPlayerPlot(plotIdentifier)
end

-- Listen for when a player leaves to save their blocks and clear their plot
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Connect the delete event to the handler function
deleteEvent.OnServerEvent:Connect(onDeleteEvent)