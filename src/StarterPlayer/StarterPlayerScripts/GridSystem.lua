-- GridSystem.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local getPlotFunction = ReplicatedStorage:WaitForChild("GetPlotFunction")

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

local gridLines = {}
local gridSize = 0.5

local function createGrid(plotPart)
	local plotSize = plotPart.Size
	local plotPosition = plotPart.Position

	-- Create lines along the X axis
	for z = -plotSize.Z / 2, plotSize.Z / 2, gridSize do
		local line = Instance.new("Part")
		line.Name = "GridLine"
		line.Size = Vector3.new(plotSize.X, 0.05, 0.05)
		line.Position = plotPosition + Vector3.new(0, 0.1, z)
		line.Anchored = true
		line.CanCollide = false
		line.Color = Color3.new(0.8, 0.8, 0.8)
		line.Transparency = 0.5
		line.Parent = workspace
		table.insert(gridLines, line)
	end

	-- Create lines along the Z axis
	for x = -plotSize.X / 2, plotSize.X / 2, gridSize do
		local line = Instance.new("Part")
		line.Name = "GridLine"
		line.Size = Vector3.new(0.05, 0.05, plotSize.Z)
		line.Position = plotPosition + Vector3.new(x, 0.1, 0)
		line.Anchored = true
		line.CanCollide = false
		line.Color = Color3.new(0.8, 0.8, 0.8)
		line.Transparency = 0.5
		line.Parent = workspace
		table.insert(gridLines, line)
	end
end

local function destroyGrid()
	for _, line in ipairs(gridLines) do
		line:Destroy()
	end
	gridLines = {}
end

local function onShowGrid()
	destroyGrid() -- Clear any existing grid
	local plotName = getPlotFunction:InvokeServer()
	if plotName then
		local plot = game.Workspace.Plots:FindFirstChild(plotName)
		if plot then
			local plotPart = plot:FindFirstChild(plotName)
			if plotPart then
				createGrid(plotPart)
			end
		end
	end
end

local function onHideGrid()
	destroyGrid()
end

showGridEvent.Event:Connect(onShowGrid)
hideGridEvent.Event:Connect(onHideGrid)
