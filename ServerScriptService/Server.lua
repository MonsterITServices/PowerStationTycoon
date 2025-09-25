-- Server Script

-- Required Modules
local Tycoon = require(script.Parent.Tycoon)
local PlayerManager = require(script.Parent.PlayerManager)
local TreeGenerator = require(game.ServerScriptService.TreeGenerator) -- Include TreeGenerator script

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Function to find an unoccupied spawn point
local function FindSpawn()
	for _, spawnPoint in ipairs(workspace.Spawns:GetChildren()) do
		if not spawnPoint:GetAttribute("Occupied") then
			return spawnPoint
		end
	end
end

-- Initialize Player Manager
PlayerManager.Start()

-- Event: Player Added
PlayerManager.PlayerAdded:Connect(function(player)
	local tycoon = Tycoon.new(player, FindSpawn())
	tycoon:Init()
	tycoon:GenerateTrees()
end)