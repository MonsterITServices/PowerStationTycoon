local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerManager = require(game:GetService("ServerScriptService"):WaitForChild("PlayerManager"))

local getSetMoney = Instance.new("RemoteFunction")
getSetMoney.Name = "GetSetMoney"
getSetMoney.Parent = ReplicatedStorage

getSetMoney.OnServerInvoke = function(player, action, value)
	if action == "get" then
		return PlayerManager.GetMoney(player)
	elseif action == "set" then
		PlayerManager.SetMoney(player, value)
		return true
	end
	return false
end
