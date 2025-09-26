-- This is TycoonRegister.lua
local TycoonRegister = {}

local tycoonMapping = {}

function TycoonRegister.registerTycoonForUserId(userId, tycoon)
	tycoonMapping[userId] = tycoon
end

function TycoonRegister.findTycoonForUserId(userId)
	return tycoonMapping[userId]
end

return TycoonRegister
