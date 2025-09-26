local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

-- Load the "Products" group
local productsGroup = ServerStorage:FindFirstChild("Products")
if not productsGroup then
    warn("Products group not found in ServerStorage")
    return
end

-- Create a folder in Workspace for the cloned products
local productsFolder = Workspace:FindFirstChild("Products")
if not productsFolder then
    productsFolder = Instance.new("Folder")
    productsFolder.Name = "Products"
    productsFolder.Parent = Workspace
end

-- Define a list of different spawn positions
local productsInfo = {
    {
        name = "FireManAxeBox",
        positions = {
            Vector3.new(78.139, 7.402, 410.8),
            Vector3.new(78.139, 10.171, 414.8),
            Vector3.new(78.139, 10.171, 410.8),
            Vector3.new(78.139, 7.402, 414.8),
            Vector3.new(78.139, 12.741, 414.8),
            Vector3.new(78.139, 12.741, 410.8),
        },
        orientations = {
            Vector3.new(0, -90, 0),    -- Orientation 1 (degrees)
            Vector3.new(0, -90, 0),    -- Orientation 2 (degrees)
            Vector3.new(0, -90, 0),    -- Orientation 3 (degrees)
            Vector3.new(0, -90, 0),
            Vector3.new(0, -90, 0),
            Vector3.new(0, -90, 0),    -- Add more orientations for FireManAxeBox
        },
		attributes = {
			DisplayName = {Value = "FireAxe", Type = "StringValue"},
			ItemID = {Value = "FireAxe", Type = "StringValue"},
			ItemType = {Value = "Tool", Type = "StringValue"},
			Worth = {Value = 500, Type = "IntValue"},
		}
    },
    {
        name = "FireShovelBox",
        positions = {
            Vector3.new(78.139, 7.402, 424),   -- Position 1
            Vector3.new(78.139, 7.402, 420.3),  -- Position 2
            Vector3.new(78.139, 10.171, 424),
            Vector3.new(78.139, 10.171, 420.3),
            Vector3.new(78.139, 12.741, 424),
            Vector3.new(78.139, 12.741, 420.3),
            -- Add more positions for FireShovelBox
        },
        orientations = {
            Vector3.new(0, -90, 0),    -- Orientation 1 (degrees)
            Vector3.new(0, -90, 0),    -- Orientation 2 (degrees)
            Vector3.new(0, -90, 0),    -- Orientation 3 (degrees)
            Vector3.new(0, -90, 0),
            Vector3.new(0, -90, 0),
            Vector3.new(0, -90, 0),
            -- Add more orientations for FireShovelBox
        },
		attributes = {
			DisplayName = {Value = "FireShovel", Type = "StringValue"},
			ItemID = {Value = "FireShovel", Type = "StringValue"},
			ItemType = {Value = "Tool", Type = "StringValue"},
			Worth = {Value = 1000, Type = "IntValue"},
		}
    },
    -- Add more products with positions and orientations as needed
}

for _, productInfo in ipairs(productsInfo) do
	local productGroup = productsGroup:FindFirstChild(productInfo.name)
	if not productGroup then
		warn(productInfo.name .. " group not found in ServerStorage")
		continue
	end

	local productPart = productGroup:FindFirstChild(productInfo.name)
	if not productPart then
		warn(productInfo.name .. " part not found within " .. productInfo.name .. " group")
		continue
	end

	local positions = productInfo.positions
	local orientations = productInfo.orientations

	-- Loop through each position for the product
	for i, position in ipairs(positions) do
		local newPart = productPart:Clone()
		newPart.Parent = productsFolder  -- Place the cloned item in the "Products" folder
		newPart.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(orientations[i].X), math.rad(orientations[i].Y), math.rad(orientations[i].Z))

		-- Create an "Attributes" folder to store specific attributes
		local attributesFolder = Instance.new("Folder")
		attributesFolder.Name = "Attributes"
		attributesFolder.Parent = newPart

		local attributes = productInfo.attributes

		-- Add specific attributes to the "Attributes" folder
		for attrName, attrData in pairs(attributes) do
			local attrInstance = Instance.new(attrData.Type)
			attrInstance.Name = attrName
			attrInstance.Value = attrData.Value
			attrInstance.Parent = attributesFolder

		end

		-- Add properties directly under the part
		local configValue = Instance.new("StringValue")
		configValue.Name = "Configuration"
		configValue.Value = "Draggable"
		configValue.Parent = newPart

		CollectionService:AddTag(newPart, "Draggable")


		-- Add "Owner" attribute
		local ownerValue = Instance.new("IntValue")
		ownerValue.Name = "Owner"
		ownerValue.Value = 0  -- Initialize with a default value (no owner)
		ownerValue.Parent = newPart

		-- Add "Creator" attribute
		local creatorValue = Instance.new("ObjectValue")
		creatorValue.Name = "Creator"
		creatorValue.Value = nil  -- Initialize with no creator
		creatorValue.Parent = newPart

		newPart.Touched:Connect(function(otherPart)
			local character = otherPart.Parent
			local humanoid = character and character:FindFirstChild("Humanoid")

			if humanoid then
				local touchedPlayer = game.Players:GetPlayerFromCharacter(character)

				if touchedPlayer then
					-- Add code here to handle the player touching the box
					-- For example, you can change the box's ownership to the touchedPlayer
					newPart.Owner.Value = touchedPlayer.UserId

					-- Set a timer to remove the player ID after 30 seconds
					wait(30)
					newPart.Owner.Value = 0 -- Set it to 0 or another default value
				end
			end
		end)
	end
end