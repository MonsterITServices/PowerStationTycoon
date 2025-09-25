-- Add this to the top of your PlotBuyGuiScript.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plotClaimedEvent = ReplicatedStorage:WaitForChild("PlotClaimedEvent")

-- =================================================================
-- This is the new part for showing the "Plot Taken" message
-- =================================================================
--[[
	You will need to create a simple Frame in your GUI to act as a popup.
	For example, create a TextLabel inside a Frame.
	Then, connect them to this script.
--]]
-- Example: local popupFrame = script.Parent.PopupFrame
-- Example: local popupMessage = popupFrame.MessageLabel


plotClaimedEvent.OnClientEvent:Connect(function(plotName)
	print("The plot " .. plotName .. " is already taken! Please choose another one.")

	-- To show a real popup message to the player, you would do something like this:
	-- popupMessage.Text = "This plot is already taken! Please choose another."
	-- popupFrame.Visible = true
	-- wait(3) -- Show the message for 3 seconds
	-- popupFrame.Visible = false
end)


-- The rest of your script that handles button clicks to buy plots would go here.
-- For example:
-- local buyButton = script.Parent.BuyButton
-- local setPlotEvent = ReplicatedStorage:WaitForChild("SetPlotEvent")
--
-- buyButton.MouseButton1Click:Connect(function()
--     local selectedPlot = -- get the plot the player selected
--     setPlotEvent:FireServer(selectedPlot.Name)
-- end)
-- Client-Side Script: PlotBuyGuiScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

local plotBuyGui = script.Parent
local plotButtons = plotBuyGui:WaitForChild("PlotButtons")

local setPlotEvent = ReplicatedStorage:WaitForChild("SetPlotEvent")
local getPlotFunction = ReplicatedStorage:WaitForChild("GetPlotFunction")

local restoreEvent = ReplicatedStorage:WaitForChild("restoreEvent", 5)

-- Variable to store the selected plot
local selectedPlot = nil

-- Function to close notification
local function closeNotification()
	local notification = plotBuyGui:WaitForChild("Notification")
	notification.Visible = false
end

-- Function to show the notification popup
local function showNotification(message)
	local notification = plotBuyGui:WaitForChild("Notification")
	local notificationText = notification:WaitForChild("TextLabel")
	notificationText.Text = message
	notification.Visible = true
end

-- Function to buy a plot
local function buyPlot(plotName)
	setPlotEvent:FireServer(plotName)
	selectedPlot = plotName
	showNotification("You now own " .. plotName)
end

-- Function to restore a plot
local function restorePlot()
	if selectedPlot then
		restoreEvent:FireServer(selectedPlot)  -- Remove player argument
	else
		
		showNotification("No selected plot to restore.")
	end
end

-- Button connection for buying plots
for _, button in pairs(plotButtons:GetChildren()) do
	if button:IsA("TextButton") then
		if button.Name == "Close" then
			button.MouseButton1Click:Connect(function()
				plotButtons.Visible = false
			end)
		elseif button.Name == "RestoreButton" then
			button.MouseButton1Click:Connect(restorePlot)
		else
			button.MouseButton1Click:Connect(function()
				buyPlot(button.Name)
			end)
		end
	end
end

-- Additional code to toggle the PlotButtons frame
local plotOpenButton = plotBuyGui:WaitForChild("PlotOpen")
local closeButton = plotButtons:WaitForChild("Close")

-- Function to show the PlotButtons frame
local function showPlotButtons()
	plotButtons.Visible = true
end

-- Function to hide the PlotButtons frame
local function hidePlotButtons()
	plotButtons.Visible = false
end

-- Connecting button functions
plotOpenButton.MouseButton1Click:Connect(showPlotButtons)
closeButton.MouseButton1Click:Connect(hidePlotButtons)

-- Connect the close notification button
local closeNotificationButton = plotBuyGui:WaitForChild("Notification"):WaitForChild("CloseNotification")
closeNotificationButton.MouseButton1Click:Connect(closeNotification)

-- Connect the close restore popup button
local closeRestorePopupButton = plotBuyGui:WaitForChild("RestorePopup"):WaitForChild("CloseRestorePopup")
closeRestorePopupButton.MouseButton1Click:Connect(function()
	local restorePopup = plotBuyGui:WaitForChild("RestorePopup")
	restorePopup.Visible = false
end)
-- Somewhere in your PlotBuyGuiScript.lua, add this:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local plotClaimedEvent = ReplicatedStorage:WaitForChild("PlotClaimedEvent")

plotClaimedEvent.OnClientEvent:Connect(function(plotName)
	-- This function will run when the server tells you that the plot is already taken.
	-- You should display a message to the player here.
	print("The plot " .. plotName .. " is already taken! Please choose another one.")
	-- For a better user experience, you could show this message in a GUI element.
end)