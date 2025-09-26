-- Admin Panel Server-Side Script (with PlayerManager Integration)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- IMPORTANT: Require your PlayerManager module script
local PlayerManager = require(ServerScriptService.PlayerManager)

-- Your list of admin Player IDs
local adminUserIDs = {
	522609764,
	4664735382,
	-- Add more user IDs here
}

-- Banned players (this is a simple in-memory ban list)
local bannedUserIDs = {}

-- Create the RemoteEvent for communication
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "AdminCommandEvent"
remoteEvent.Parent = ReplicatedStorage

-- Function to find a player by name (case-insensitive)
local function findPlayers(name)
	local foundPlayers = {}
	local lowerName = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():match("^" .. lowerName) then
			table.insert(foundPlayers, player)
		end
	end
	return foundPlayers
end


-- Listen for commands from clients
remoteEvent.OnServerEvent:Connect(function(player, command, targetPlayerName, argument)
	-- Check if the player is an admin
	if not table.find(adminUserIDs, player.UserId) then
		return
	end

	local targets = findPlayers(targetPlayerName)
	if #targets == 0 then
		-- Handle 'all' and 'others' keywords
		if targetPlayerName:lower() == "all" then
			targets = Players:GetPlayers()
		elseif targetPlayerName:lower() == "others" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					table.insert(targets, p)
				end
			end
		else
			print("Admin Panel: Player not found:", targetPlayerName)
			return
		end
	end


	for _, targetPlayer in ipairs(targets) do
		-- Execute the command
		if command == "kick" then
			targetPlayer:Kick("You have been kicked from the game by an admin.")
		elseif command == "ban" then
			table.insert(bannedUserIDs, targetPlayer.UserId)
			targetPlayer:Kick("You have been banned from the game.")
		elseif command == "givemoney" then
			local amount = tonumber(argument)
			if amount then
				-- ** THE FIX IS HERE **
				-- Use the PlayerManager to handle the money change
				local currentMoney = PlayerManager.GetMoney(targetPlayer)
				PlayerManager.SetMoney(targetPlayer, currentMoney + amount)
			end
		elseif command == "teleport" then
			local targetCharacter = targetPlayer.Character
			local playerCharacter = player.Character
			if targetCharacter and playerCharacter then
				playerCharacter:SetPrimaryPartCFrame(targetCharacter:GetPrimaryPartCFrame())
			end
		elseif command == "kill" then
			local character = targetPlayer.Character
			if character and character:FindFirstChild("Humanoid") then
				character.Humanoid.Health = 0
			end
		elseif command == "message" then
			-- For a more robust messaging system, you'd create a custom GUI
			-- This is a simple server message
			local message = argument or ""
			print("Admin Message to " .. targetPlayer.Name .. ": " .. message)
		end
	end
end)

-- Check for banned players when they join
Players.PlayerAdded:Connect(function(player)
	if table.find(bannedUserIDs, player.UserId) then
		player:Kick("You are banned from this game.")
	end
end)