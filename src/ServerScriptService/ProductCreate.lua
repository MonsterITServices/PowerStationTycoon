-- ... (Previous code)

-- Function to determine the product based on attributes on the touched part
function determineProduct(touchedPart)
	-- Retrieve the attributes you need directly from the touched part
	local attributesFolder = touchedPart:FindFirstChild("Attributes")

	if not attributesFolder then
		warn("Attributes folder not found in " .. touchedPart.Name)
		return nil  -- Attributes folder not found
	end

	local displayName = attributesFolder:FindFirstChild("DisplayName")
	local worth = attributesFolder:FindFirstChild("Worth")
	local itemType = attributesFolder:FindFirstChild("ItemType")
	local itemID = attributesFolder:FindFirstChild("ItemID")

	-- Check if any attribute is missing
	if not displayName or not worth or not itemType or not itemID then
		warn("Missing attributes in the Attributes folder of " .. touchedPart.Name)
		return nil  -- Missing attributes
	end

	-- Create a product info table based on the attributes
	local productInfo = {
		DisplayName = displayName.Value,
		Worth = worth.Value,
		ItemType = itemType.Value,
		ItemID = itemID.Value
	}

	return productInfo  -- Return the product info
end

-- ... (Remaining code)
