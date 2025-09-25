-- Client-Side Script: PlotBuyGuiScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local plotBuyGui = script.Parent
local plotButtonsFrame = plotBuyGui:WaitForChild("PlotButtons")

-- Remote Communication for the new robust system
local setPlotEvent = ReplicatedStorage:WaitForChild("SetPlotEvent")
local getOccupiedPlotsFunction = ReplicatedStorage:WaitForChild("GetOccupiedPlotsFunction")
local PlotStatusUpdateEvent = ReplicatedStorage:WaitForChild("PlotStatusUpdateEvent") -- For live updates
local restoreEvent = ReplicatedStorage:WaitForChild("restoreEvent", 5)

-- A dictionary to easily access plot buttons by their name (e.g., plotButtons["Plot1"])
local plotButtons = {}
for _, button in pairs(plotButtonsFrame:GetChildren()) do
	if button:IsA("TextButton") and button.Name ~= "Close" and button.Name ~= "RestoreButton" then
		plotButtons[button.Name] = button
	end
end

-- =================================================================
-- NEW: Functions to Update the UI based on plot status
-- =================================================================

-- This function visually styles a button based on whether it's owned or available
local function updateButtonStyle(button, isOwned)
	if isOwned then
		button.BackgroundColor3 = Color3.fromRGB(170, 0, 0) -- Dark Red for "Taken"
		button.Text = "Taken"
		button.Selectable = false -- IMPORTANT: This prevents the button from being clicked
	else
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 80) -- Green for "Available"
		button.Text = button.Name
		button.Selectable = true -- IMPORTANT: This allows the button to be clicked
	end
end

-- This function updates the entire GUI based on a table of owned plots
local function updateAllPlotButtons(occupiedPlots)
	-- First, assume all plots are available
	for plotName, button in pairs(plotButtons) do
		updateButtonStyle(button, false)
	end
	-- Then, loop through the occupied plots and mark them as taken
	for userId, plotName in pairs(occupiedPlots) do
		if plotButtons[plotName] then
			updateButtonStyle(plotButtons[plotName], true)
		end
	end
end


-- =================================================================
-- Existing Functions (with minor adjustments)
-- =================================================================

local selectedPlot = nil -- Variable to store the selected plot

local function closeNotification()
	local notification = plotBuyGui:WaitForChild("Notification")
	notification.Visible = false
end

local function showNotification(message)
	local notification = plotBuyGui:WaitForChild("Notification")
	local notificationText = notification:WaitForChild("TextLabel")
	notificationText.Text = message
	notification.Visible = true
end

-- This function is now only called when a selectable button is clicked
local function buyPlot(plotName)
	setPlotEvent:FireServer(plotName)
	selectedPlot = plotName -- Keep track of the player's own plot
	-- The server will fire the PlotStatusUpdateEvent, which will update the button's appearance
	showNotification("You now own " .. plotName)
end

local function restorePlot()
	if selectedPlot then
		restoreEvent:FireServer(selectedPlot)
	else
		showNotification("You do not own a plot to restore.")
	end
end


-- =================================================================
-- Initial Setup and Event Connections
-- =================================================================

-- 1. Get the initial state of all plots from the server when the GUI loads
print("Getting initial plot statuses from the server...")
local initialOccupiedPlots = getOccupiedPlotsFunction:InvokeServer()
updateAllPlotButtons(initialOccupiedPlots)


-- 2. Listen for LIVE updates from the server
-- This is the core of the system. The server tells us when any plot changes ownership.
PlotStatusUpdateEvent.OnClientEvent:Connect(function(plotName, ownerId)
	local button = plotButtons[plotName]
	if button then
		local isOwned = (ownerId ~= nil) -- If there's an ownerId, it's owned.
		updateButtonStyle(button, isOwned)
	end
end)


-- 3. Connect button clicks
for _, button in pairs(plotButtonsFrame:GetChildren()) do
	if button:IsA("TextButton") then
		if button.Name == "Close" then
			button.MouseButton1Click:Connect(function()
				plotButtonsFrame.Visible = false
			end)
		elseif button.Name == "RestoreButton" then
			button.MouseButton1Click:Connect(restorePlot)
		else -- This handles all the plot buttons (Plot1, Plot2, etc.)
			button.MouseButton1Click:Connect(function()
				-- NEW: Only fire the buy event if the button is selectable
				if button.Selectable then
					buyPlot(button.Name)
				else
					showNotification("This plot is already taken!")
				end
			end)
		end
	end
end

-- Your existing GUI toggle and notification close buttons
local plotOpenButton = plotBuyGui:WaitForChild("PlotOpen")
plotOpenButton.MouseButton1Click:Connect(function() plotButtonsFrame.Visible = true end)

local closeButton = plotButtonsFrame:WaitForChild("Close")
closeButton.MouseButton1Click:Connect(function() plotButtonsFrame.Visible = false end)

local closeNotificationButton = plotBuyGui:WaitForChild("Notification"):WaitForChild("CloseNotification")
closeNotificationButton.MouseButton1Click:Connect(closeNotification)

local closeRestorePopupButton = plotBuyGui:WaitForChild("RestorePopup"):WaitForChild("CloseRestorePopup")
closeRestorePopupButton.MouseButton1Click:Connect(function()
	local restorePopup = plotBuyGui:WaitForChild("RestorePopup")
	restorePopup.Visible = false
end)