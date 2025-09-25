local CollectionService = game:GetService("CollectionService")  


local Toliet = require(script.Toliet)


-- @FIXME: abstract out an agnostic tag list
local function makeToliet(tolietModel)
    local _toliet = Toliet.new(tolietModel)

    _toliet:_bind()
end

local _tolietList = CollectionService:GetTagged('Toliet')

for i = 1, #_tolietList do
    makeToliet(_tolietList[i])
end

CollectionService:GetInstanceAddedSignal('Toliet'):Connect(function(tolietModel)
    makeToliet(tolietModel)
end)