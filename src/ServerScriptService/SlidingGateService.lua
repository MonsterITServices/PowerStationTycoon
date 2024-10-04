local colSer = game:GetService('CollectionService')
local slidingGate = require(script.SlidingGate)

local gates = colSer:GetTagged('SlidingGate')

for i = 1, #gates do
	local thisGate = slidingGate.new(gates[i])
	thisGate:BindButtons()
end

local added = colSer:GetInstanceAddedSignal('SlidingGate')

added:Connect(function(gateContainer)
	local thisGate = slidingGate.new(gateContainer)
	thisGate:BindButtons()
end)