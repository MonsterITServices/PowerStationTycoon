-- Define the function that returns the maximum health for a given tree type
local function maxHealthForTreeType(treeType)
	if treeType == "IceLolliTree" then
		return 3
	elseif treeType == "CandyTree" then
		return 5
	elseif treeType == "DonutTree" then
		return 1
	elseif treeType == "PopcornTree" then
		return 7
	elseif treeType == "FudgeTree" then
		return 15
	elseif treeType == "ChipsTree" then
		return 2
	elseif treeType == "KababTree" then
		return 2
	elseif treeType == "SlusheeTree" then
		return 2
	else
		return 7
	end
end

-- Axeserver
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AxeRE = ReplicatedStorage:WaitForChild("AxeRE")

local CollectionService = game:GetService("CollectionService")

local cooldown = {}

-- Table to store tree data for regrowth
local treeData = {}

-- Function to destroy the log after 30 minutes
local function destroyLog(logPart)
	wait(1800)  -- Wait for 30 minutes
	if logPart and logPart.Parent then
		logPart:Destroy()
	end
end

-- Function to regrow a tree
local function regrowTree(treeType, position, originalTrunk)
	local growthTime = 20  -- Time in seconds for the tree to fully grow
	local growthStepInterval = 0.1  -- Interval between growth steps
	local growthSteps = growthTime / growthStepInterval

	local treeInfo = treeData[originalTrunk]

	if treeInfo then
		local basePosition = position - Vector3.new(0, treeInfo.originalTrunkSize.Y / 2, 0)
		local treeTrunk = Instance.new("Part")
		treeTrunk.Name = "Trunk"
		treeTrunk.Size = Vector3.new(treeInfo.originalTrunkSize.X, 1, treeInfo.originalTrunkSize.Z)
		treeTrunk.Position = basePosition  -- Set the bottom position of the trunk
		treeTrunk.Anchored = true
		treeTrunk.Parent = workspace

		-- Set tree attributes (e.g., health, type)
		local healthValue = Instance.new("IntValue")
		healthValue.Name = "Health"
		healthValue.Value = 1  -- Set a small initial health
		healthValue.Parent = treeTrunk

		local treeTypeValue = Instance.new("StringValue")
		treeTypeValue.Name = "treeType"
		treeTypeValue.Value = treeType
		treeTypeValue.Parent = treeTrunk

		CollectionService:AddTag(treeTrunk, "Tree")

		-- Gradually grow the tree upwards
		for step = 1, growthSteps do
			local growthPercentage = step / growthSteps
			local newSize = Vector3.new(treeInfo.originalTrunkSize.X, treeInfo.originalTrunkSize.Y * growthPercentage, treeInfo.originalTrunkSize.Z)
			treeTrunk.Size = newSize

			-- Keep the original color
			treeTrunk.BrickColor = treeInfo.trunkColor

			-- Keep the material constant as "Wood"
			treeTrunk.Material = Enum.Material.Wood

			local newPosition = basePosition + Vector3.new(0, treeInfo.originalTrunkSize.Y * growthPercentage / 2, 0)
			treeTrunk.Position = newPosition

			wait(growthStepInterval)
		end

		-- Set final attributes and size
		treeTrunk.Size = treeInfo.originalTrunkSize
		treeTrunk.BrickColor = treeInfo.trunkColor
		treeTrunk.Material = Enum.Material.Wood

		-- Recreate leaves if available in the stored data
		if treeInfo.leaves then
			local newLeaves = treeInfo.leaves:Clone()
			newLeaves.Parent = treeTrunk
			newLeaves.Size = treeInfo.originalLeavesSize  -- Set the original leaves size
		end

		-- Handle any other necessary actions for the new tree trunk
	end
end

AxeRE.OnServerEvent:Connect(function(player, target, mouseHit)
	if not cooldown[player] and player.Character and target and target.Name == "Trunk" and target:FindFirstChild("Health") and mouseHit then
		local hrp = player.Character.HumanoidRootPart
		local distance = (hrp.Position - target.Position).Magnitude
		if distance <= 6 then
			cooldown[player] = true

			local treeTypeValue = target:FindFirstChild("treeType")
			if treeTypeValue then
				local treeType = treeTypeValue.Value

				local healthValue
				if treeType == "IceLolliTree" then
					healthValue = 3  -- Set the health value for IceLolliTreeLog
				elseif treeType == "CandyTree" then
					healthValue = 5  -- Set the health value for CandyTreeLog
				elseif treeType == "DonutTree" then
					healthValue = 1  -- Set the health value for DonutTreeLog
				elseif treeType == "PopcornTree" then
					healthValue = 7
				elseif treeType == "ChipsTree" then
					healthValue = 2  -- Set the health value for CandyTreeLog
				elseif treeType == "FudgeTree" then
					healthValue = 15  -- Set the health value for DonutTreeLog
				elseif treeType == "KababTree" then
					healthValue = 15
				elseif treeType == "SlusheeTree" then
					healthValue = 15
				else
					healthValue = 7  -- Set a default value for unrecognized tree type
				end

				-- Store tree data before destroying
				local treeInfo = {
					trunkMaterial = target.Material,
					trunkColor = target.BrickColor,
					leaves = target:FindFirstChild("Leaves"),
					originalTrunkSize = target.Size,  -- Store the original trunk size
					originalLeavesSize = target:FindFirstChild("Leaves") and target.Leaves.Size or nil  -- Store the original leaves size
				}
				local originalWorthValue = target:FindFirstChild("Worth")
				local originalWorth = 1  -- Default to 1
				if originalWorthValue then
					originalWorth = originalWorthValue.Value
				else

				end
				treeData[target] = treeInfo

				-- Perform chopping logic here
				local trunkHealth = target.Health
				trunkHealth.Value = trunkHealth.Value - 1

				if trunkHealth.Value <= 0 then
					-- Destroy the trunk and leaves
					target:Destroy()
					local leaves = target:FindFirstChild("Leaves")
					if leaves then
						local fallingLeaves = leaves:Clone()
						fallingLeaves.Parent = workspace
						fallingLeaves.Anchored = false
						fallingLeaves.Position = leaves.Position  -- Position it same as the original leaves
						fallingLeaves.Velocity = Vector3.new(0, -10, 0)  -- Apply downward velocity

						-- Destroy the leaves after 300 seconds
						spawn(function()
							wait(300)
							if fallingLeaves and fallingLeaves.Parent then
								fallingLeaves:Destroy()
							end
						end)
					end
					-- Create a new log part based on the tree type
					local numberOfLogs = 4
					local LogSize = Vector3.new(1, 5, 1)
					local offset = 5
					for i = 1, numberOfLogs do
					local logPart = Instance.new("Part")
					logPart.Name = treeType .. "Log"  -- Example: CandyTreeLog
					logPart.Size = LogSize  -- Adjust size as needed
					logPart.Position = target.Position + Vector3.new(i * offset, 0, 0)
					logPart.Anchored = false
					-- Fetch the LocalScript from ReplicatedStorage
					local replicatedStorage = game:GetService("ReplicatedStorage")
					local existingLocalScript = replicatedStorage:FindFirstChild("LiftAndCarry_Physical_ClientScript")

					-- Check if the LocalScript exists
					if existingLocalScript then
						-- Clone the existing LocalScript
						local clonedLocalScript = existingLocalScript:Clone()

						-- Parent the cloned LocalScript to the new log part
						clonedLocalScript.Parent = logPart
					end
					-- Clone the DragDetector from ReplicatedStorage
					local existingDragDetector = replicatedStorage:FindFirstChild("DragDetector")  -- Replace with the actual name

					-- Check if the DragDetector exists
					if existingDragDetector then
						-- Clone the existing DragDetector
						local clonedDragDetector = existingDragDetector:Clone()

						-- Parent the cloned DragDetector to the new log part
						clonedDragDetector.Parent = logPart
					end
					logPart.Parent = workspace

					-- Add "Worth" attribute
					local worthValue = Instance.new("NumberValue")
					worthValue.Name = "Worth"
					worthValue.Value = originalWorth  -- Set the value from the original tree trunk
					worthValue.Parent = logPart
					
					--add owner tag
					local ownerValue = Instance.new("ObjectValue")
					ownerValue.Name = "Owner"
					ownerValue.Value = player
					ownerValue.Parent = logPart

					-- Add "Creator" attribute to mark ownership
					local creatorValue = Instance.new("ObjectValue")
					creatorValue.Name = "Creator"
					creatorValue.Value = player -- Set the value to the chopping player
					creatorValue.Parent = logPart

					-- Apply properties from the trunk to the log
					logPart.Material = treeInfo.trunkMaterial
					logPart.BrickColor = treeInfo.trunkColor
					-- Handle any other necessary actions for the log part, such as physics, appearance, etc.

					-- Start the function to destroy the log after 30 minutes
					spawn(function()
						destroyLog(logPart)
					end)

					-- Call the regrowTree function after a delay (e.g., 1800 seconds or 30 minutes)
					spawn(function()
						wait(30)  -- Adjust this delay as needed
						regrowTree(treeType, target.Position, target)
					end)
				end
			end

			wait(1)
			cooldown[player] = false
		end
		end
	end
	
end)
