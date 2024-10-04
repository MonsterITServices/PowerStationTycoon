local player = game:GetService("Players").LocalPlayer
while wait(1.5) do
	local headLoc = game.Workspace.Terrain:WorldToCell(player.Character.LowerTorso.Position) or game.Workspace.Terrain:WorldToCell(player.Character.Torso.Position)
	local hasAnyWater = game.Workspace.Terrain:GetWaterCell(headLoc.x, headLoc.y, headLoc.z)
	if player.Character.Humanoid.Health ~= 0 then
		if hasAnyWater then
			player.Character.Humanoid:TakeDamage(8)
		end
	end
end