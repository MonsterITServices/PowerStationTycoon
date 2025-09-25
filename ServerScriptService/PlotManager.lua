local Plots = workspace:WaitForChild("Plots")
local plotDataStore = game:GetService("DataStoreService"):GetDataStore("PlotData")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local SharedData = require(game.ServerScriptService:WaitForChild("SharedData"))
local playerPlots = SharedData.playerPlots -- Use the shared playerPlots table

-- RemoteEvents and RemoteFunctions setup
local setPlotEvent = ReplicatedStorage:FindFirstChild("SetPlotEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
setPlotEvent.Name = "SetPlotEvent"

local getPlotFunction = ReplicatedStorage:FindFirstChild("GetPlotFunction") or Instance.new("RemoteFunction", ReplicatedStorage)
getPlotFunction.Name = "GetPlotFunction"

local getOccupiedPlotsFunction = ReplicatedStorage:FindFirstChild("GetOccupiedPlotsFunction") or Instance.new("RemoteFunction", ReplicatedStorage)
getOccupiedPlotsFunction.Name = "GetOccupiedPlotsFunction"

local plotClaimedEvent = ReplicatedStorage:FindFirstChild("PlotClaimedEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
plotClaimedEvent.Name = "PlotClaimedEvent"

getOccupiedPlotsFunction.OnServerInvoke = function()
	return playerPlots
end

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

-- =================================================================
-- MODIFIED FUNCTION
-- =================================================================
-- Function to set a user's plot
local function setPlot(player, userId, plotName)
	local plot = workspace.Plots:FindFirstChild(plotName)
	if not plot then
		warn("Plot not found: " .. plotName)
		return
	end

	-- NEW: Directly check the plot model for an "Owner" tag. This is more reliable.
	local ownerTag = plot:FindFirstChild("Owner")
	if ownerTag and ownerTag.Value ~= tostring(userId) then
		warn("Player " .. player.Name .. " tried to claim plot " .. plotName .. " which is already owned by " .. ownerTag.Value)
		plotClaimedEvent:FireClient(player, plotName) -- Fire event to the client to show the popup
		return -- IMPORTANT: Stop the function here
	end

	-- Clear the player's old plot if they have one
	local oldPlotIdentifier = playerPlots[userId]
	if oldPlotIdentifier and oldPlotIdentifier ~= plotName then
		local oldPlot = workspace.Plots:FindFirstChild(oldPlotIdentifier)
		if oldPlot then
			-- Remove the owner tag from the old plot
			local oldOwnerTag = oldPlot:FindFirstChild("Owner")
			if oldOwnerTag then
				oldOwnerTag:Destroy()
			end
			-- Destroy the blocks on the old plot
			for _, child in pairs(oldPlot:GetChildren()) do
				if CollectionService:HasTag(child, "PlayerBlock") then
					child:Destroy()
				end
			end
		end
	end

	-- Assign the new plot
	plotDataStore:SetAsync(userId, plotName)
	playerPlots[userId] = plotName

	-- Create or update the owner tag on the new plot
	if not ownerTag then
		ownerTag = Instance.new("StringValue")
		ownerTag.Name = "Owner"
		ownerTag.Parent = plot
	end
	ownerTag.Value = tostring(userId)

	print("Plot assigned to player:", userId, "Plot Name:", plotName)
	teleportToPlot(player, plot)
end

local function getPlot(userId)
	local plotName, err = plotDataStore:GetAsync(userId)
	if plotName then
		playerPlots[userId] = plotName
		return Plots:FindFirstChild(plotName)
	end
	return nil
end

getPlotFunction.OnServerInvoke = function(player)
	local plot = getPlot(player.UserId)
	if plot then
		playerPlots[player.UserId] = plot.Name
		return plot.Name
	else
		return nil
	end
end

setPlotEvent.OnServerEvent:Connect(function(player, plotName)
	setPlot(player, player.UserId, plotName)
end)

Players.PlayerAdded:Connect(function(player)
    -- Small delay to ensure everything loads
    wait(2)
	local plot = getPlot(player.UserId)
	if plot then
		-- When the player joins, re-apply the owner tag to their plot
		local ownerTag = plot:FindFirstChild("Owner")
		if not ownerTag then
			ownerTag = Instance.new("StringValue")
			ownerTag.Name = "Owner"
			ownerTag.Parent = plot
		end
		ownerTag.Value = tostring(player.UserId)
		playerPlots[player.UserId] = plot.Name
		teleportToPlot(player, plot)
	end
end)


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