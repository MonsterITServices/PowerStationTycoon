-- Written by PrinceTybalt, 10/6/2023
-- With input from creators on the dev forum DragDetector beta program, 
-- especially @Deadwoodx, @Wertyhappy27, @kirbyFirer, @MonsterStepDad, and @MintSoapBar
-- Feel free to use, modify, and distribute.

-- If you do something cool, maybe tag PrinceTybalt on the Dev Forum, or  @PrinceTybaltRBX on twitter, 
-- so we can see what cool stuff you do with it?

-- To work, this script needs to live below a non-anchored part, with siblings that are
-- a DragDetector, LiftAndCarry_Physical_ServerScript and one RemoteEvents named RequestNetworkOwnershipEvent
-- Once installed, when you hit play and click the parent part, it will lift to be in front of your character and 
-- your character will carry it around, in physical style, meaning it is dragged around with constraint forces.
-- It will work whether you are using a first person camera or not.

-- These scripts are designed to a DragDetector set to runLocally = true, so we need to send RemoteEvents to the server 
-- and request network ownership or our part. Otherwise we aren't in control of the physics for it, and it won't move.

-- If you find this script out of context, you can start fresh by going to the Toolbox and searching for 
-- models created by PrinceTybalt; this one is called "Lift And Carry: Geometric"
-- If you find this script out of context, you can start fresh by going to the Toolbox and searching for 
-- models created by PrinceTybalt; this one is called "Lift And Carry: Physical"
-- Or you can download a copy of the game https://www.roblox.com/games/14988427132/Lift-And-Carry
wait(0.5)
local dragDetector = script.Parent.DragDetector

local CARRY_DISTANCE = 10

local lastViewFrame = CFrame.new()
local myMovingPart = script.Parent
local replicatedStorage = game:GetService("ReplicatedStorage")
local requestNetworkOwnershipEvent = replicatedStorage:WaitForChild("RequestNetworkOwnershipEvent")

local function fireRequestNetworkOwnershipEvent(clickedPart)
	requestNetworkOwnershipEvent:FireServer(clickedPart)
end

dragDetector.DragStart:Connect(function(player, ray, viewFrame, hitFrame, clickedPart)
	if (clickedPart ~= myMovingPart) then
		print("hmmm.  The clicked Part is not the expected part")
	end
	fireRequestNetworkOwnershipEvent(clickedPart)	
end)

dragDetector.DragContinue:Connect(function(player, ray, viewFrame)
	lastViewFrame = viewFrame
end)

-- Blockcast tells us how far a box the size of the part will travel before hitting something.
-- This is an approximation, but better than a raycast, which does not consider the size of the part
local function getBlockcastAvoidingCharacter(rayToShoot, characterToAvoid)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {dragDetector.Parent, characterToAvoid }
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist	
	local direction = rayToShoot.Direction
	local fromFrame = myMovingPart:GetPivot().Rotation + rayToShoot.Origin
	return workspace:Blockcast(fromFrame, myMovingPart.Size, direction, raycastParams)
end

local function isPhysicalDrag()
	return dragDetector and dragDetector.ResponseStyle == Enum.DragDetectorResponseStyle.Physical and myMovingPart.Anchored == false
end

local function getNewFrameGivenRayFromPlayer(rayFromPlayer)
	local rayToShoot = Ray.new(rayFromPlayer.Origin, rayFromPlayer.Direction.Unit * CARRY_DISTANCE)
	local player = game.Players.LocalPlayer
	local blockcastResult = getBlockcastAvoidingCharacter(rayToShoot, player.character)
	-- if we don't hit anything closer than CARRY_DISTANCE, we'll place it CARRY_DISTANCE ahead of us.
	local finalDistance = CARRY_DISTANCE
	if blockcastResult then
		finalDistance = blockcastResult.Distance
		if isPhysicalDrag() then
			-- this will attempt to place it slightly beyond the surface.
			-- in the physical case, this helps push/slide along walls. (We don't to this in the geometric case or we'd penetrate the other objects)
			finalDistance = finalDistance + 0.2
		end
	end	
	local finalPosition = rayFromPlayer.Origin + rayFromPlayer.Direction.Unit * finalDistance
	return myMovingPart:GetPivot().Rotation + finalPosition	
end

local EPSILON = 0.00001
local function intersectRayPlane(ray, planeOrigin, _planeNormal)
	local planeNormal = _planeNormal.Unit
	local planeDistance = -1 * planeNormal:Dot(planeOrigin)	
	local unitRayDir = ray.Direction.Unit
	local rate = unitRayDir:Dot(planeNormal)	
	if math.abs(rate) < EPSILON then
		-- ray is parellel to plane surface; cannot intersect
		return false, Vector3.new()
	end
	local t = -(planeDistance + ray.Origin:Dot(planeNormal)) / rate
	return true, ray.Origin + unitRayDir * t
end

local MAX_X_PLANE_OFFSET = 10
local MAX_Y_PLANE_OFFSET = 5
local MIN_X_PLANE_OFFSET = -10
local MIN_Y_PLANE_OFFSET = -5
local function intersectPlayerPlaneWithinBounds(ray, playerPlaneOrigin, playerForward)
	-- the playerPlane is a plane in front of the player a distance of CARRY_DISTANCE
	-- it should be parallel to the ground; remove the Y component just in case
	local levelPlayerForward = Vector3.new(playerForward.x, 0, playerForward.z)
	local success, intersection = intersectRayPlane(ray, playerPlaneOrigin, levelPlayerForward)
	if not success then
		return success, intersection
	end
	-- the plane intersection could be way off to the side, or too high or low.
	-- clamp it within bounds of the playerPlaneOrigin, which is a point in front of the player
	local offsetFromOrigin = intersection - playerPlaneOrigin
	local planeXDir = levelPlayerForward:Cross(Vector3.yAxis).Unit
	local planeYDir = Vector3.yAxis
	local xDist = offsetFromOrigin:Dot(planeXDir)
	local yDist = offsetFromOrigin:Dot(planeYDir)
	xDist = if xDist < MIN_X_PLANE_OFFSET then MIN_X_PLANE_OFFSET else xDist
	xDist = if xDist > MAX_X_PLANE_OFFSET then MAX_X_PLANE_OFFSET else xDist
	yDist = if yDist < MIN_Y_PLANE_OFFSET then MIN_Y_PLANE_OFFSET else yDist
	yDist = if yDist > MAX_Y_PLANE_OFFSET then MAX_Y_PLANE_OFFSET else yDist
	local newIntersection = playerPlaneOrigin + xDist * planeXDir + yDist * planeYDir
	return true, newIntersection	
end

local function getRayEmanatingFromPlayer(cursorRay)
	local player = game.Players.LocalPlayer
	local headPart = nil
	local rootPart = nil
	if player and player.Character then
		headPart = player.Character:FindFirstChild("Head")
		rootPart = player.Character:WaitForChild("HumanoidRootPart")
	end
	if not headPart or not rootPart then
		-- we can't get any ray based on the player, fall back to the cursorRay
		return cursorRay
	end
	local isFirstPerson = headPart.LocalTransparencyModifier > 0.6
	if isFirstPerson then
		-- when we are in first person, the cursorRay has an origin in the center of the view and a 
		-- direction forward in the view direction. So we are shooting a direction straight ahead from our POV
		return cursorRay
	end

	-- when we are not in first person, we intersect with a plane facing us, but in front of the player's root, part to find the 
	-- desired location.
	-- then we construct a ray from the player's character directed toward the intersection with that plane.
	local playerLocation = rootPart:GetPivot().Position
	local viewFrameLookAt = lastViewFrame.LookVector.Unit
	local playerPlaneOrigin = playerLocation + viewFrameLookAt * CARRY_DISTANCE
	local success, planeIntersection = intersectPlayerPlaneWithinBounds(cursorRay, playerPlaneOrigin, viewFrameLookAt)
	if not success then
		return cursorRay
	end
	-- a ray from the playerLocation to the intersection we just found
	return Ray.new(playerLocation, planeIntersection - playerLocation)
end

local function getDesiredNewWorldCFrame(cursorRay)
	local rayFromPlayer = getRayEmanatingFromPlayer(cursorRay)
	return getNewFrameGivenRayFromPlayer(rayFromPlayer)
end

dragDetector.DragStyle = Enum.DragDetectorDragStyle.Scriptable

dragDetector:SetDragStyleFunction(function(cursorRay)
	return getDesiredNewWorldCFrame(cursorRay)
end)