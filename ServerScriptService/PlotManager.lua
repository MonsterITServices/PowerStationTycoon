-- ServerScriptService/PlotManager.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local SharedData = require(game.ServerScriptService:WaitForChild("SharedData"))
local playerPlots = SharedData.playerPlots -- This table holds the current state: { [userId] = "PlotName" }

-- DataStore for saving plot ownership (we still save, but won't auto-load)
local plotDataStore = DataStoreService:GetDataStore("PlotData")

-- Ensure Workspace folders exist
local PlotsFolder = Workspace:WaitForChild("Plots")

-- RemoteEvents and Functions for communication with clients
local setPlotEvent = ReplicatedStorage:FindFirstChild("SetPlotEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
setPlotEvent.Name = "SetPlotEvent"

local getOccupiedPlotsFunction = ReplicatedStorage:FindFirstChild("GetOccupiedPlotsFunction") or Instance.new("RemoteFunction", ReplicatedStorage)
getOccupiedPlotsFunction.Name = "GetOccupiedPlotsFunction"

local PlotStatusUpdateEvent = ReplicatedStorage:FindFirstChild("PlotStatusUpdateEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
PlotStatusUpdateEvent.Name = "PlotStatusUpdateEvent"


-- Function to teleport a player to their plot's spawn point
local function teleportToPlot(player, plot)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local plotNumber = string.gsub(plot.Name, "Plot", "")
	local spawnName = "Spawn" .. plotNumber
	local plotSpawn = plot:FindFirstChild(spawnName)

	if humanoidRootPart and plotSpawn then
		humanoidRootPart.CFrame = plotSpawn.CFrame + Vector3.new(0, 3, 0)
	else
		warn("Plot spawn not found: " .. spawnName .. " in plot " .. plot.Name)
	end
end

-- Function to handle a player's request to claim a plot
local function onSetPlotRequest(player, plotName)
	local userId = player.UserId
	local plotToClaim = PlotsFolder:FindFirstChild(plotName)

	if not plotToClaim then
		warn("Player " .. player.Name .. " tried to claim a non-existent plot: " .. plotName)
		return
	end

	-- Final server-side check: Is the plot already owned by someone else?
	for ownerId, ownedPlotName in pairs(playerPlots) do
		if ownedPlotName == plotName and ownerId ~= userId then
			warn("SERVER REJECTED: Player " .. player.Name .. " attempted to claim owned plot " .. plotName)
			return
		end
	end

	-- --- Plot Claim is Successful ---

	-- 1. Clear the player's old plot if they are moving to a new one
	local oldPlotName = playerPlots[userId]
	if oldPlotName and oldPlotName ~= plotName then
		local oldPlot = PlotsFolder:FindFirstChild(oldPlotName)
		if oldPlot then
			for _, child in pairs(oldPlot:GetChildren()) do
				if CollectionService:HasTag(child, "PlayerBlock") then
					child:Destroy()
				end
			end
		end
		-- Announce that the old plot is now free
		PlotStatusUpdateEvent:FireAllClients(oldPlotName, nil)
	end

	-- 2. Assign the new plot
	playerPlots[userId] = plotName
	plotDataStore:SetAsync(tostring(userId), plotName) -- Save to DataStore for next time

	-- 3. Teleport player and announce the plot is now taken
	teleportToPlot(player, plotToClaim)
	PlotStatusUpdateEvent:FireAllClients(plotName, userId)

	print("Plot '" .. plotName .. "' successfully claimed by " .. player.Name)
end


-- =================================================================
-- MODIFIED SECTION
-- =================================================================
-- When a player joins, we will no longer automatically assign them a plot.
-- They must choose one from the GUI. This prevents the "ghost" taken plots.
Players.PlayerAdded:Connect(function(player)
	print("Player " .. player.Name .. " has joined. They must select a plot.")
	-- The server will now wait for the player to fire the 'setPlotEvent'.
	-- The client GUI will handle showing them the available plots.
end)


-- When a player leaves, free up their plot so others can claim it.
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local plotName = playerPlots[userId]

	if plotName then
		playerPlots[userId] = nil -- Remove from the active server list
		print("Player " .. player.Name .. " left. Plot '" .. plotName .. "' is now available.")
		-- Announce to all remaining players that this plot is now free
		PlotStatusUpdateEvent:FireAllClients(plotName, nil)
	end
end)


-- === Remote Connections ===

-- The client calls this function once when its GUI loads to get the initial state
getOccupiedPlotsFunction.OnServerInvoke = function(player)
	-- This now returns a list of plots taken ONLY by players in the current session.
	return playerPlots
end

-- Connect the client's request to claim a plot to the server function
setPlotEvent.OnServerEvent:Connect(onSetPlotRequest)