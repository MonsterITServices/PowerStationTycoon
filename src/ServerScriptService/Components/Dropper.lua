local dropsFolder = game:GetService("ServerStorage").Drops
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Dropper = {}
Dropper.__index = Dropper

-- Maximum drops allowed per player
local MAX_DROPS_PER_PLAYER = 10

function Dropper.new(tycoon, instance, ownerPlayer)
	local self = setmetatable({}, Dropper)
	self.Tycoon = tycoon
	self.Instance = instance
	self.Rate = instance:GetAttribute("Rate")
	self.DropTemplate = dropsFolder[instance:GetAttribute("Drop")]
	self.DropSpawn = instance.Spout.Spawn
	self.OwnerPlayer = ownerPlayer  -- This assumes you're passing the player who owns the dropper
	self.DebrisTime = 1800
	self.DropCount = 0  -- Initialize the drop count

	return self
end

function Dropper:Init()
	coroutine.wrap(function()
		while true do
			if self.DropCount < MAX_DROPS_PER_PLAYER then
				self:Drop()
			end
			wait(self.Rate)
		end
	end)()
end

function Dropper:Drop()
	local replicatedStorage = game:GetService("ReplicatedStorage")

	local drop = self.DropTemplate:Clone()
	drop.Position = self.DropSpawn.WorldPosition
	drop.Parent = workspace  -- Parent the drop to workspace or a specific folder within workspace

	if drop:IsA("BasePart") then
		drop:SetNetworkOwner(self.OwnerPlayer)  -- Set the network owner to the owner player
	end

	-- Add the LiftAndCarry_Physical_ClientScript to the drop
	local existingLocalScript = replicatedStorage:FindFirstChild("LiftAndCarry_Physical_ClientScript")
	if existingLocalScript then
		local clonedLocalScript = existingLocalScript:Clone()
		clonedLocalScript.Parent = drop
	end

	-- Add the DragDetector to the drop
	local existingDragDetector = replicatedStorage:FindFirstChild("DragDetector")
	if existingDragDetector then
		local clonedDragDetector = existingDragDetector:Clone()
		clonedDragDetector.Parent = drop
	end

	-- Increment the drop count when a drop is spawned
	self.DropCount = self.DropCount + 1

	-- Use a custom function or the Debris service to decrement the drop count when it's destroyed or times out
	local function onDropRemoved()
		self.DropCount = math.max(self.DropCount - 1, 0)
	end

	drop.AncestryChanged:Connect(function(child, parent)
		if not parent then
			onDropRemoved()
		end
	end)

	Debris:AddItem(drop, self.DebrisTime)
	-- Ensure the drop count is decremented after the DebrisTime has passed in case the AncestryChanged event doesn't fire
	delay(self.DebrisTime, onDropRemoved)
end

return Dropper
