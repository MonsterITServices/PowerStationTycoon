-- Server-Side Script: PlotManager
local Plots = workspace:WaitForChild("Plots")
local plotDataStore = game:GetService("DataStoreService"):GetDataStore("PlotData")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create or get the RemoteEvent for setting plots
local setPlotEvent = ReplicatedStorage:FindFirstChild("SetPlotEvent")
if not setPlotEvent then
	setPlotEvent = Instance.new("RemoteEvent")
	setPlotEvent.Name = "SetPlotEvent"
	setPlotEvent.Parent = ReplicatedStorage
end

-- Function to set a user's plot
local function setPlot(userId, plotName)
	local plot = Plots:FindFirstChild(plotName)
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
	end
end

-- Function to get a user's plot
local function getPlot(userId)
	local plotName, err = plotDataStore:GetAsync(userId)
	if plotName then
		return Plots:FindFirstChild(plotName)
	end
	return nil
end

-- Create or get the RemoteFunction for getting plots
local getPlotFunction = ReplicatedStorage:FindFirstChild("GetPlotFunction")
if not getPlotFunction then
	getPlotFunction = Instance.new("RemoteFunction")
	getPlotFunction.Name = "GetPlotFunction"
	getPlotFunction.Parent = ReplicatedStorage
end

-- Handle getPlot requests
getPlotFunction.OnServerInvoke = function(player)
	local plot = getPlot(player.UserId)
	if plot then
		return plot.Name
	else
		return nil
	end
end

-- Handle setPlot requests
setPlotEvent.OnServerEvent:Connect(function(player, plotName)
	setPlot(player.UserId, plotName)
end)
