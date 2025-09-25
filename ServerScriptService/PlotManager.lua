local Plots = workspace:WaitForChild("Plots")
local plotDataStore = game:GetService("DataStoreService"):GetDataStore("PlotData")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local SharedData = require(game.ServerScriptService:WaitForChild("SharedData"))
local playerPlots = SharedData.playerPlots -- Use the shared playerPlots table

-- Create or get the RemoteEvent for setting plots
local setPlotEvent = ReplicatedStorage:FindFirstChild("SetPlotEvent")
if not setPlotEvent then
	setPlotEvent = Instance.new("RemoteEvent")
	setPlotEvent.Name = "SetPlotEvent"
	setPlotEvent.Parent = ReplicatedStorage
end

-- Create or get the RemoteFunction for getting plots
local getPlotFunction = ReplicatedStorage:FindFirstChild("GetPlotFunction")
if not getPlotFunction then
	getPlotFunction = Instance.new("RemoteFunction")
	getPlotFunction.Name = "GetPlotFunction"
	getPlotFunction.Parent = ReplicatedStorage
end

local getOccupiedPlotsFunction = ReplicatedStorage:FindFirstChild("GetOccupiedPlotsFunction")
if not getOccupiedPlotsFunction then
	getOccupiedPlotsFunction = Instance.new("RemoteFunction")
	getOccupiedPlotsFunction.Name = "GetOccupiedPlotsFunction"
	getOccupiedPlotsFunction.Parent = ReplicatedStorage
end

-- This new event will be used to tell the client that a plot is already claimed.
local plotClaimedEvent = ReplicatedStorage:FindFirstChild("PlotClaimedEvent")
if not plotClaimedEvent then
	plotClaimedEvent = Instance.new("RemoteEvent")
	plotClaimedEvent.Name = "PlotClaimedEvent"
	plotClaimedEvent.Parent = ReplicatedStorage
end


getOccupiedPlotsFunction.OnServerInvoke = function()
	return playerPlots
end

-- Function to teleport a player to their plot's spawn
local function teleportToPlot(player, plot)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Extract the plot number from the plot name (e.g., "Plot1" -> "1")
	local plotNumber = string.gsub(plot.Name, "Plot", "")
	local spawnName = "Spawn" .. plotNumber

	-- Find the corresponding spawn location inside the plot model
	local plotSpawn = plot:FindFirstChild(spawnName)

	if humanoidRootPart and plotSpawn then
		humanoidRootPart.CFrame = plotSpawn.CFrame + Vector3.new(0, 3, 0)
	else
		warn("Plot spawn not found: " .. spawnName .. " in plot " .. plot.Name)
	end
end

-- Function to set a user's plot
local function setPlot(player, userId, plotName)
	-- Check if the plot is already owned by someone else
	for ownerId, ownedPlotName in pairs(playerPlots) do
		if ownedPlotName == plotName and ownerId ~= userId then
			warn("Player " .. player.Name .. " tried to claim plot " .. plotName .. " which is already owned by " .. ownerId)
			plotClaimedEvent:FireClient(player, plotName) -- Fire event to the client
			return -- Stop the function
		end
	end

	-- Clear the old plot
	local oldPlotIdentifier = playerPlots[userId]
	if oldPlotIdentifier then
		local oldPlot = workspace.Plots:FindFirstChild(oldPlotIdentifier)
		if oldPlot then
			for _, child in pairs(oldPlot:GetChildren()) do
				if CollectionService:HasTag(child, "PlayerBlock") then
					child:Destroy()
				end
			end
		end
	end

	local plot = workspace.Plots:FindFirstChild(plotName)
	if plot then
		-- Save to data store
		plotDataStore:SetAsync(userId, plotName)

		-- Create or update owner tag on plot
		local ownerTag = plot:FindFirstChild("Owner")
		if not ownerTag then
			ownerTag = Instance.new("StringValue")
			ownerTag.Name = "Owner"
			ownerTag.Parent = plot
		end
		ownerTag.Value = tostring(userId)

		-- Directly update the playerPlots table in PlacementSystem
		playerPlots[userId] = plotName
		print("Plot assigned to player:", userId, "Plot Name:", plotName)

		-- Teleport the player to the plot
		teleportToPlot(player, plot)
	else
		warn("Plot not found: " .. plotName)
	end
end

-- Function to get a user's plot
local function getPlot(userId)
	local plotName, err = plotDataStore:GetAsync(userId)
	if plotName then
		playerPlots[userId] = plotName -- Make sure playerPlots is synchronized from the datastore
		return Plots:FindFirstChild(plotName)
	end
	return nil
end

-- Handle GetPlot requests
getPlotFunction.OnServerInvoke = function(player)
	local plot = getPlot(player.UserId)
	if plot then
		playerPlots[player.UserId] = plot.Name -- Update the playerPlots table
		return plot.Name
	else
		return nil
	end
end

-- Handle setPlot requests
setPlotEvent.OnServerEvent:Connect(function(player, plotName)
	setPlot(player, player.UserId, plotName)
end)

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	local plot = getPlot(player.UserId)
	if plot then
		-- Player has a plot, teleport them to it
		teleportToPlot(player, plot)
	end
end)

-- Handle player leaving to free up the plot
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local plotName = playerPlots[userId]
	if plotName then
		local plot = Plots:FindFirstChild(plotName)
		if plot then
			local ownerTag = plot:FindFirstChild("Owner")
			if ownerTag then
				ownerTag:Destroy()
			end
		end
		playerPlots[userId] = nil
		print("Plot " .. plotName .. " is now available.")
	end
end)