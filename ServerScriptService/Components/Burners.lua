-- Import your Collector module
local Collector = require(game:GetService("ServerScriptService"):WaitForChild("Components"):WaitForChild("Collector"))

-- Get ServerStorage and Workspace
local serverStorage = game:GetService("ServerStorage")
local workspace = game:GetService("Workspace")

-- Fetch Burners model from ServerStorage
local burners = serverStorage:WaitForChild("Burners")

-- Clone Burners into Workspace
local burnersClone = burners:Clone()
burnersClone.Parent = workspace

-- Initialize collectors from the cloned Burners
for _, furnacePart in pairs(burnersClone:GetChildren()) do
	if furnacePart.Name:match("FP%d+") then
		local colliderPart = furnacePart:FindFirstChild("Collider")
		if colliderPart then
			local collector = Collector.new(nil, {Collider = colliderPart})
			collector:Init()
		end
	end
end
