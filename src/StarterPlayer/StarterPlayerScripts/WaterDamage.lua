local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 1. Create the Sound
local drowningSound = Instance.new("Sound")

-- 2. Configure the Sound
drowningSound.SoundId = "rbxassetid://134119264993756" -- ? Replace with your sound ID
drowningSound.Looped = true
drowningSound.Parent = script -- Store the sound inside the script

while wait(1.5) do
	-- Make sure the player's character exists
	if not player.Character or not player.Character:FindFirstChild("LowerTorso") then continue end

	local torso = player.Character.LowerTorso
	local humanoid = player.Character.Humanoid

	local headLoc = game.Workspace.Terrain:WorldToCell(torso.Position)
	local hasAnyWater = game.Workspace.Terrain:GetWaterCell(headLoc.x, headLoc.y, headLoc.z)

	if humanoid.Health > 0 then
		if hasAnyWater then
			-- Player is in the water
			humanoid:TakeDamage(8)
			-- Play the sound only if it's not already playing
			if not drowningSound.IsPlaying then
				drowningSound:Play()
			end
		else
			-- Player is out of the water, so stop the sound
			if drowningSound.IsPlaying then
				drowningSound:Stop()
			end
		end
	else
		-- Player is dead, so stop the sound
		if drowningSound.IsPlaying then
			drowningSound:Stop()
		end
	end
end