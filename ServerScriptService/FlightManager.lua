-- Located in: ServerScriptService
-- VERSION 3: Handles multiple coal balls

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Objects
local coalBallsFolder = workspace:WaitForChild("CoalBalls")
local enableFlightEvent = ReplicatedStorage:WaitForChild("EnableFlightEvent")

local COOLDOWN_DURATION = 1800 -- 30 minutes
local ballsOnCooldown = {} -- A table to track cooldowns for each ball individually

-- This function runs when ANY coal ball is clicked
-- It now accepts the specific ball that was clicked as an argument
local function onCoalBallClicked(player, ballClicked)
	-- If this specific ball is on cooldown, do nothing
	if ballsOnCooldown[ballClicked] then return end

	-- Put this specific ball on cooldown
	ballsOnCooldown[ballClicked] = true

	-- Fire the remote event to tell this specific player's client to enable flight
	-- We only give the flight ability ONCE per player for the session.
	-- (This part of the logic is now handled on the client script to keep it simple)
	enableFlightEvent:FireClient(player)

	-- Make the specific ball that was clicked disappear
	print(ballClicked.Name .. " has been collected. Cooldown started.")
	ballClicked.Transparency = 1
	ballClicked.CanCollide = false
	ballClicked.ClickDetector.MaxActivationDistance = 0

	task.wait(COOLDOWN_DURATION)

	-- Make that specific ball reappear
	print(ballClicked.Name .. " has respawned.")
	ballClicked.Transparency = 0
	ballClicked.CanCollide = true
	ballClicked.ClickDetector.MaxActivationDistance = 32

	-- Remove the ball from the cooldown table so it can be clicked again
	ballsOnCooldown[ballClicked] = nil
end

-- This function loops through all the balls and sets up their click event
local function setupCoalBalls()
	for _, ball in ipairs(coalBallsFolder:GetChildren()) do
		-- Make sure the part has a ClickDetector
		local clickDetector = ball:FindFirstChildOfClass("ClickDetector")
		if clickDetector then
			-- Connect the click event, passing the player AND the specific ball clicked
			clickDetector.MouseClick:Connect(function(player)
				onCoalBallClicked(player, ball)
			end)
		end
	end
end

-- Run the setup function to activate all the coal balls
setupCoalBalls()