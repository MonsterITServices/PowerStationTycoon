-- PlayerManager script

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = DataStoreService:GetDataStore("PlayerDB")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local leaderboardSetupEvent = Instance.new("RemoteEvent")
leaderboardSetupEvent.Name = "LeaderboardSetupEvent"
leaderboardSetupEvent.Parent = ReplicatedStorage
local logCollectedEvent = Instance.new("RemoteEvent")
logCollectedEvent.Name = "LogCollectedEvent"
logCollectedEvent.Parent = ReplicatedStorage


-- New table to keep track of who owns a plot

local PlayerManager = {}

function PlayerManager.OnLogCollected(player, worthValue)
	local currentMoney = PlayerManager.GetMoney(player)
	PlayerManager.SetMoney(player, currentMoney + worthValue)
end


local function LeaderboardSetup(value)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = value
	money.Parent = leaderstats
	return leaderstats
end

local function LoadData(player)
	local success, result = pcall(function()
		return PlayerData:GetAsync(player.UserId)
	end)
	if not success then
		warn(result)
	else
		
	end
	return success, result
end

function SaveData(player, data)
	local success, result = pcall(function()
		PlayerData:SetAsync(player.UserId, {
			Money = data.Money,
			UnlockIds = data.UnlockIds
		})
	end)

	if not success then
		warn(result)
	else
		
	end
	return success
end

local sessionData = {}

local playerAdded = Instance.new("BindableEvent")
local playerRemoving = Instance.new("BindableEvent")


PlayerManager.PlayerAdded = playerAdded.Event
PlayerManager.PlayerRemoving = playerRemoving.Event

function PlayerManager.Start()
	for _, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(PlayerManager.OnPlayerAdded)(player)
	end
	logCollectedEvent.OnServerEvent:Connect(PlayerManager.OnLogCollected)
	Players.PlayerAdded:Connect(PlayerManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerManager.OnPlayerRemoving)
	game:BindToClose(PlayerManager.OnClose)
end

function PlayerManager.OnPlayerAdded(player)
	
	player.CharacterAdded:Connect(function(character)
		PlayerManager.OnCharacterAdded(player, character)
	end)

	local success, data = LoadData(player)

	if success and data then
		sessionData[player.UserId] = {
			Money = data.Money or 0,
			UnlockIds = data.UnlockIds or {}
		}
	else
		sessionData[player.UserId] = {
			Money = 0,
			UnlockIds = {}
		}
	end

	local leaderstats = LeaderboardSetup(PlayerManager.GetMoney(player))
	leaderstats.Parent = player

	leaderboardSetupEvent:FireClient(player)

	playerAdded:Fire(player)
end

function PlayerManager.OnCharacterAdded(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			wait(3)
			player:LoadCharacter()
		end)
	end
end

function PlayerManager.GetMoney(player)
	return sessionData[player.UserId].Money
end

function PlayerManager.SetMoney(player, value)
	if value then
		sessionData[player.UserId].Money = value

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local money = leaderstats:FindFirstChild("Money")
			if money then
				money.Value = value
			end
		end
	end
end

function PlayerManager.AddUnlockId(player, id)
	local data = sessionData[player.UserId]

	if not table.find(data.UnlockIds, id) then
		table.insert(data.UnlockIds, id)
	end
end

function PlayerManager.GetUnlockIds(player)
	return sessionData[player.UserId].UnlockIds
end

function PlayerManager.OnPlayerRemoving(player)
	
	SaveData(player, sessionData[player.UserId])
	-- Trigger any other necessary events
	playerRemoving:Fire(player)
end

function PlayerManager.OnClose()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerManager.OnPlayerRemoving(player)
	end
end

return PlayerManager