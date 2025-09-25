local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local InventoryDataStore = game:GetService("DataStoreService"):GetDataStore("PlayerInventory") -- Change this to your DataStore name

-- Define the "Products" folder in Workspace
local productsFolder = Workspace:FindFirstChild("Products")

-- Check if the "Products" folder exists
if not productsFolder then
	warn("Products folder not found in Workspace")
	return
else
	print("Products folder found in workspace")
end

-- Load the "CounterTop" part within the "shop" group
local regionPowerStation = Workspace:FindFirstChild("Region_PowerStation")
if not regionPowerStation then
	warn("Region_PowerStation not found in Workspace")
	return
end

local shopGroup = regionPowerStation:FindFirstChild("shop")
if not shopGroup then
	warn("shop group not found in Region_PowerStation")
	return
end

local counterGroup = shopGroup:FindFirstChild("Counter")
if not counterGroup then
	warn("Counter group not found in shop group")
	return
end

local Countertop = counterGroup:FindFirstChild("Countertop")
if not Countertop then
	warn("Countertop not found in counter group")
	return
end

-- Define a flag to track whether a product is on the counter
local productOnCounter = false

-- Define the functions to handle placement and removal
local function onPlaced()
	print("Product has been placed on CounterTop")
	productOnCounter = true
end

local function onRemoved()
	if productOnCounter then
		print("Product has been removed from CounterTop")
		productOnCounter = false
	end
end

-- Connect the functions to the Touched event
Countertop.Touched:Connect(function(otherPart)
	print("Touched")
	local character = otherPart.Parent
	local humanoid = character and character:FindFirstChild("Humanoid")

	if humanoid then
		onPlaced()
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Use the determineProduct function to find the product within the "Products" folder
			local product = determineProduct(otherPart, productsFolder) -- Pass the "Products" folder and the touched part

			if product then
				local cost = product.Worth -- Adjust this based on your item attributes
				if canAfford(player, cost) then
					deductMoney(player, cost)
					giveItem(player, product)
					print("Product purchased successfully.")
				else
					warn("Insufficient funds.")
				end

				local choice = promptPlayer(player, product)
				if choice == "Buy" then
					-- Rest of the code remains the same
				end
			end
		end
		onRemoved()
	end
end)


function determineProduct(touchedPart, productsFolder)
	if touchedPart and productsFolder then
		print("Checking for product in the Products folder...")
		print("Touched Part Name:", touchedPart.Name)

		-- Find the touched part within the "Products" folder
		local child = productsFolder:FindFirstChild(touchedPart.Name)

		if child then
			print("Found the product in the Products folder.")

			-- Check if the child has the expected attributes
			local displayName = child:FindFirstChild("Attributes"):FindFirstChild("DisplayName")
			local worth = child:FindFirstChild("Attributes"):FindFirstChild("Worth")
			local itemType = child:FindFirstChild("Attributes"):FindFirstChild("ItemType")
			local itemID = child:FindFirstChild("Attributes"):FindFirstChild("ItemID")

			-- Check if any attribute is missing
			if displayName and worth and itemType and itemID then
				-- Create a product info table based on the attributes
				local productInfo = {
					DisplayName = displayName.Value,
					Worth = worth.Value,
					ItemType = itemType.Value,
					ItemID = itemID.Value
				}

				return productInfo  -- Return the product info
			else
				warn("Missing attributes on the touched part")
			end
		else
			warn("Product not found in the Products folder")
		end
	else
		warn("Invalid input parameters for finding a product")
	end

	return nil
end


-- Rest of the script (canAfford, deductMoney, giveItem, promptPlayer) remains the same

-- Function to check if the player can afford the cost
function canAfford(player, cost)
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")

		if money and money:IsA("IntValue") and money.Value >= cost then
			return true  -- The player can afford it
		end
	end

	return false  -- The player can't afford it
end

-- Function to deduct money from the player
function deductMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")

		if money and money:IsA("IntValue") and money.Value >= amount then
			money.Value = money.Value - amount  -- Deduct the money
		end
	end
end

-- Function to give the item to the player
function giveItem(player, product)
	-- Clone the tool from ServerStorage
	local toolClone = game.ServerStorage.Tools:FindFirstChild(product.ItemID)

	if toolClone then
		toolClone = toolClone:Clone()

		-- Add the tool to the player's Backpack
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			toolClone.Parent = backpack
		else
			toolClone.Parent = player  -- If no Backpack, place it in the player's character

			-- Ensure that the tool is equipped
			local character = player.Character
			if character then
				local toolHandle = toolClone:FindFirstChild("Handle")
				if toolHandle then
					toolHandle:WaitForChild()  -- Wait for the tool handle to load
					toolClone.Parent = character  -- Move the tool to the character
				end
			end
		end

		-- Save the item to the player's inventory using DataStore
		local success, error = pcall(function()
			local key = "Inventory_" .. player.UserId
			local playerData = InventoryDataStore:GetAsync(key)

			if not playerData then
				playerData = {}
			end

			table.insert(playerData, product.ItemID)  -- Store the tool's ID in the inventory

			InventoryDataStore:SetAsync(key, playerData)
		end)

		if not success then
			warn("Failed to save item to inventory: " .. error)
		end
	else
		warn("Tool with ItemID '" .. product.ItemID .. "' not found in ServerStorage.Tools.")
	end
end

-- Function to display a prompt to the player and return their choice
function promptPlayer(player, product)
	local choice = ""

	-- Check if the player is still in the game
	if not player or not player:IsDescendantOf(game.Players) then
		return "Cancel"
	end

	-- Create a dialog box
	local dialog = Instance.new("Dialog")
	dialog.Parent = player.PlayerGui
	dialog.Name = "PurchaseDialog"

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 100)
	frame.Position = UDim2.new(0.5, -150, 0.5, -50)
	frame.Parent = dialog

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 0.6, 0)
	textLabel.Position = UDim2.new(0, 0, 0, 0)
	textLabel.Text = "Do you want to buy " .. product.DisplayName .. " for £" .. product.Worth .. "?"
	textLabel.Parent = frame

	local yesButton = Instance.new("TextButton")
	yesButton.Size = UDim2.new(0.45, 0, 0.3, 0)
	yesButton.Position = UDim2.new(0.05, 0, 0.7, 0)
	yesButton.Text = "Yes"
	yesButton.Parent = frame

	local noButton = Instance.new("TextButton")
	noButton.Size = UDim2.new(0.45, 0, 0.3, 0)
	noButton.Position = UDim2.new(0.5, 0, 0.7, 0)
	noButton.Text = "No"
	noButton.Parent = frame

	-- Function to handle button clicks
	local function onButtonClicked(button)
		if button == yesButton then
			choice = "Buy"
		elseif button == noButton then
			choice = "Cancel"
		end
		dialog:Remove()
	end

	yesButton.MouseButton1Click:Connect(function()
		onButtonClicked(yesButton)
	end)

	noButton.MouseButton1Click:Connect(function()
		onButtonClicked(noButton)
	end)

	while choice == "" do
		wait(0.1)
	end

	return choice
end
