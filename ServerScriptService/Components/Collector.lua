local Collector = {}
Collector.__index = Collector

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerManager = require(game.ServerScriptService:WaitForChild("PlayerManager"))  -- Assuming the script is in ServerScriptService
local TycoonRegister = require(game.ServerScriptService:WaitForChild("TycoonRegister"))

function Collector.new(tycoon, instance)
	local self = setmetatable({}, Collector)
	self.Tycoon = tycoon
	self.Instance = instance

	return self
end

function Collector:Init()
	self.Instance.Collider.Touched:Connect(function(...)
		self:OnTouched(...)	
	end)
end

function Collector:OnTouched(hitPart)
	
	local worthValue = hitPart:FindFirstChild("Worth")
	if worthValue and worthValue:IsA("NumberValue") then
		
		local worth = worthValue.Value

		if self.Tycoon then
			
			self.Tycoon:PublishTopic("WorthChange", worth)
			playerManager.SetMoney(self.Tycoon.Owner, playerManager.GetMoney(self.Tycoon.Owner) + worth)
		else
			
			local ownerObject = hitPart:FindFirstChild("Owner")
			if ownerObject and ownerObject:IsA("ObjectValue") then
				
				local ownerPlayer = ownerObject.Value
				if ownerPlayer and ownerPlayer:IsA("Player") then
					
					local tycoon = TycoonRegister.findTycoonForUserId(ownerPlayer.UserId)
					if tycoon then
						
						tycoon:PublishTopic("WorthChange", worth)
						playerManager.SetMoney(tycoon.Owner, playerManager.GetMoney(tycoon.Owner) + worth)
					else
						
					end
				else
					
				end
			else

			end
		end

		hitPart:Destroy()
	else
		
	end
end


return Collector