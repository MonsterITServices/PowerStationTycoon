local replicatedStorage = game:GetService("ReplicatedStorage")
local requestNetworkOwnershipEvent = replicatedStorage:WaitForChild("RequestNetworkOwnershipEvent")

local function onRequestNetworkOwnership(player, part)
	part:SetNetworkOwner(player)
end

requestNetworkOwnershipEvent.OnServerEvent:Connect(onRequestNetworkOwnership)