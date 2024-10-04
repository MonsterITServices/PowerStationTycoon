local CollectionService = game:GetService("CollectionService")
local template = game:GetService("ServerStorage").Template
local componentFolder = script.Parent.Components
local tycoonStorage = game:GetService("ServerStorage").TycoonStorage
local playerManager = require(script.Parent.PlayerManager)
local TreeGenerator = require(game.ServerScriptService.TreeGenerator)
local Collector = require(game:GetService("ServerScriptService").Components:WaitForChild("Collector"))
local TycoonRegister = require(game.ServerScriptService:WaitForChild("TycoonRegister"))

local function NewModel(model, cframe)
	local newModel = model:Clone()
	newModel:SetPrimaryPartCFrame(cframe)
	newModel.Parent = workspace
	return newModel
end

local Tycoon = {}
Tycoon.__index = Tycoon

function Tycoon.new(player, spawnPoint)
	local self = setmetatable({}, Tycoon)
	self.Owner = player

	self._topicEvent = Instance.new("BindableEvent")    
	self._spawn = spawnPoint
	self._spawnArea = workspace.Treeregions
	self.treeTypeToRegionMap = {
		CandyTree = "CandyTree",
		ChipsTree = "ChipsTree",
		DonutTree = "DonutTree",
		FudgeTree = "FudgeTree",
		IceLolliTree = "IceLolliTree",
		KababTree = "KababTree",
		PopcornTree = "PopcornTree",
		SlusheeTree = "SlusheeTree",
		-- Map more tree types to regions as needed
	}

	-- Register the tycoon with the new user ID.
	TycoonRegister.registerTycoonForUserId(player.UserId, self)

	return self
end

function Tycoon:Init()
	self.Model = NewModel(template, self._spawn.CFrame)
	self._spawn:SetAttribute("Occupied", true)
	self.Owner.RespawnLocation = self.Model.Spawn
	self.Owner:LoadCharacter()

	self:LockAll()
	self:LoadUnlocks()
	self:WaitForExit()
	self:GenerateTrees()-- Generate trees during initialization
	-- Add Collector for each burner here
	for _, burner in pairs(self.Model:GetDescendants()) do
		if burner:IsA("Part") and burner.Name == "Burner" then  -- Replace "Burner" with whatever name you have for the burners
			local collector = Collector.new(self, burner)
			collector:Init()
		end
	end
end

function Tycoon:LoadUnlocks()
	for _, id in ipairs(playerManager.GetUnlockIds(self.Owner)) do
		self:PublishTopic("Button", id)
	end
end

function Tycoon:LockAll()
	for _, instance in ipairs(self.Model:GetDescendants()) do
		if CollectionService:HasTag(instance, "Unlockable") then
			self:Lock(instance)
		else
			self:AddComponents(instance)
		end
	end
end

function Tycoon:Lock(instance)
	instance.Parent = tycoonStorage
	self:CreateComponent(instance, componentFolder.Unlockable)
end

function Tycoon:Unlock(instance, id)
	playerManager.AddUnlockId(self.Owner, id)

	CollectionService:RemoveTag(instance, "Unlockable")
	self:AddComponents(instance)
	instance.Parent = self.Model
end

function Tycoon:AddComponents(instance)
	for _, tag in ipairs(CollectionService:GetTags(instance)) do
		local component = componentFolder:FindFirstChild(tag)
		if component then 
			self:CreateComponent(instance, component)
		end
	end
end

function Tycoon:CreateComponent(instance, componentScript)
	local compModule = require(componentScript)
	local newComp = compModule.new(self, instance)
	newComp:Init()
end

function Tycoon:PublishTopic(topicName, ...)
	self._topicEvent:Fire(topicName, ...)
end

function Tycoon:SubscribeTopic(topicName, callback)
	local connection = self._topicEvent.Event:Connect(function(name, ...)
		if name == topicName then
			callback(...)
		end
	end)
	return connection
end

function Tycoon:OnCharacterAdded(character)
	-- Generate trees after the player's character has loaded
	self:GenerateTrees()
end

function Tycoon:GenerateTrees()
	-- Generate trees using the logic from the TreeGenerator script
	local treeTypeCounts = {
		CandyTree = { count = 5, health = 10 },
		ChipsTree = { count = 10, health = 15 },
		DonutTree = { count = 10, health = 15 },
		FudgeTree = { count = 10, health = 15 },
		IceLolliTree = { count = 10, health = 15 },
		KababTree = { count = 10, health = 15 },
		PopcornTree = { count = 10, health = 15 },
		SlusheeTree = { count = 10, health = 15 },
		-- Add more tree types and counts as needed
	}

	local generateTreesInRegions = require(game.ServerScriptService.TreeGenerator)
	generateTreesInRegions(treeTypeCounts, self._spawnArea, self.treeTypeToRegionMap)
end

function Tycoon:WaitForExit()
	playerManager.PlayerRemoving:Connect(function(player)
		if self.Owner == player then
			self:Destroy()
		end
	end)
end

function Tycoon:Destroy()
	self.Model:Destroy()
	self._spawn:SetAttribute("Occupied", false)
	self._topicEvent:Destroy()
end

return Tycoon
