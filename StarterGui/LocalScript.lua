-- Admin Panel Client-Side Script (with CUSTOM Dropdown)

-- Services
local Players = game:GetService("Players")

-- GUI Elements
local gui = script.Parent
local mainFrame = gui.MainFrame
local toggleButton = gui.ToggleButton

-- Admin User ID Check (MUST match the server script)
local adminUserIDs = { 522609764, 4664735382 }
local localPlayer = Players.LocalPlayer
if not table.find(adminUserIDs, localPlayer.UserId) then
	gui:Destroy()
	return
end

-- Custom Dropdown Elements
local selectedPlayerButton = mainFrame.SelectedPlayerButton
local playerListFrame = mainFrame.PlayerListFrame

-- Other GUI Elements
local argumentInput = mainFrame.ArgumentInput
local kickButton = mainFrame.KickButton
local banButton = mainFrame.BanButton
local giveMoneyButton = mainFrame.GiveMoneyButton
local teleportButton = mainFrame.TeleportButton
local killButton = mainFrame.KillButton
local messageButton = mainFrame.MessageButton

-- RemoteEvent
local remoteEvent = game.ReplicatedStorage:WaitForChild("AdminCommandEvent")

-- Function to create a new button for the player list
local function createPlayerButton(playerName)
	local button = Instance.new("TextButton")
	button.Text = playerName
	button.TextSize = 14
	button.Size = UDim2.new(1, 0, 0, 30) -- Full width, 30 pixels high
	button.Parent = playerListFrame

	-- When this button is clicked, update the main display and hide the list
	button.MouseButton1Click:Connect(function()
		selectedPlayerButton.Text = playerName
		playerListFrame.Visible = false
	end)
end

-- Function to refresh the list of players
local function updatePlayerList()
	-- Clear all old buttons
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Create buttons for special targets
	createPlayerButton("All")
	createPlayerButton("Others")

	-- Create a button for every player in the game
	for _, player in ipairs(Players:GetPlayers()) do
		createPlayerButton(player.Name)
	end
end

-- --- Main Logic ---

-- Toggle visibility of the main admin panel
toggleButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
end)

-- Toggle visibility of the player list dropdown
selectedPlayerButton.MouseButton1Click:Connect(function()
	playerListFrame.Visible = not playerListFrame.Visible
end)

-- Function to send a command to the server
local function sendCommand(command, argument)
	local targetPlayerName = selectedPlayerButton.Text

	if targetPlayerName and targetPlayerName ~= "- Select a Player -" then
		remoteEvent:FireServer(command, targetPlayerName, argument)
	else
		print("Admin Panel: No player selected.")
	end
end

-- Button connections
kickButton.MouseButton1Click:Connect(function() sendCommand("kick") end)
banButton.MouseButton1Click:Connect(function() sendCommand("ban") end)
giveMoneyButton.MouseButton1Click:Connect(function() sendCommand("givemoney", argumentInput.Text) end)
teleportButton.MouseButton1Click:Connect(function() sendCommand("teleport") end)
killButton.MouseButton1Click:Connect(function() sendCommand("kill") end)
messageButton.MouseButton1Click:Connect(function() sendCommand("message", argumentInput.Text) end)

-- Initial setup and dynamic updates
print("Admin Panel client script loaded for admin.")
updatePlayerList()

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)