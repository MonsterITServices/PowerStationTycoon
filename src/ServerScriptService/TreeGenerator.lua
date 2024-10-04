local ServerStorage = game:GetService("ServerStorage")

local function generateTreesInRegion(treeTypeCounts, regionParts, treeTypeToRegionMap)
	-- Create a folder named "Trees" in the workspace to store the trees
	local treesFolder = Instance.new("Folder")
	treesFolder.Name = "Trees"
	treesFolder.Parent = workspace

	for treeType, treeInfo in pairs(treeTypeCounts) do
		local regionPartName = treeTypeToRegionMap[treeType]
		local regionPart = regionParts:FindFirstChild(regionPartName)
		local treeModel = ServerStorage.Trees:FindFirstChild(treeType)

		if regionPart and treeModel then

			for i = 1, treeInfo.count do
				local randomPosition = regionPart.Position + Vector3.new(
					math.random(-regionPart.Size.X / 2, regionPart.Size.X / 2),
					0, -- Adjust the Y-coordinate as needed
					math.random(-regionPart.Size.Z / 2, regionPart.Size.Z / 2)
				)

				local newTree = treeModel:Clone()
				newTree:SetPrimaryPartCFrame(CFrame.new(randomPosition))
				newTree.Parent = treesFolder -- Put the tree inside the "Trees" folder

				-- Additional customization based on your tree structure and attributes
				local healthValue = Instance.new("IntValue")
				healthValue.Name = "Health"
				healthValue.Value = treeInfo.health
				healthValue.Parent = newTree
				newTree:SetAttribute("TreeType", treeType)

				-- Add more customization based on your tree structure and attributes
			end
		else
			warn("Cannot generate trees for", treeType, "- region:", regionPartName, "treeModel:", treeModel)
		end
	end
end

return generateTreesInRegion
