
-- Configuration for all toliets 
local GLOBAL_CONFIG = {

    CleanWaterColor = Color3.fromRGB(199, 212, 228),
    DirtyWaterColor = Color3.fromRGB(253, 234, 141),
    FecalColor      = Color3.fromRGB(124, 92, 70),
    
    FecalExtents = {
        Min = Vector3.new(.1, .1, .2),
        Max = Vector3.new(.2, .2, .6)
    },

    RotationPerStepDrain = math.rad(-8), --per step applied to X axis of handle
    RotationPerStepFill  = math.rad(8),
    HandleRotationSteps  =  5, -- ~ .2 seconds per step
    HandleDownDuration   = .4, -- originally 1
}
GLOBAL_CONFIG.__index = GLOBAL_CONFIG


---------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService('RunService')

local ran = Random.new()

-- @FIX-ME: abstract to utlity
local function getNamedChildren(parent, name)
    local p = parent:GetChildren()
    local ret = {}

    for i = 1, #p do
        if p[i].Name == name then
            table.insert(ret, p[i])
        end
    end

    return ret
end

-- @FIX-ME: abstract to utlity
local function setList(list, key, value)
    for i = 1, #list do
        if list[key] then
            list[key] = value
        end
    end
end


-- @FIX-ME: abstract to utlity
local function getRanVector3(minVec, maxVec)
    local x = ran:NextNumber(minVec.X, maxVec.X)
    local y = ran:NextNumber(minVec.Y, maxVec.Y)
    local z = ran:NextNumber(minVec.Z, maxVec.Z)

    return Vector3.new(x,y,z)
end



local function animateHandle(handle, config)

    spawn(function()
        for i = 1, config.HandleRotationSteps do
            local cf = handle.PrimaryPart.CFrame * CFrame.Angles(config.RotationPerStepDrain,0,0)
            handle:SetPrimaryPartCFrame(cf)
            wait()
        end
    
        wait(config.HandleDownDuration)
    
        for i = config.HandleRotationSteps, 1, -1 do
            local cf = handle.PrimaryPart.CFrame * CFrame.Angles(config.RotationPerStepFill,0,0)
            handle:SetPrimaryPartCFrame(cf)
            wait()
        end
    end)
    
end



local function updateSwirls(swirls, rate)
	for i = 1, #swirls do
		swirls[i].ParticleEmitter.Rate = rate
	end
end


---------------------------------------------------------------




local Toliet = {}
Toliet.__index = Toliet

function Toliet.new(model, instancedConfig)
    local self = setmetatable({},Toliet)

    -- offset global config with local config 
    self.Config = setmetatable(instancedConfig or {}, GLOBAL_CONFIG)


    -- state
    self.Used     = false
    self.Flushing = false

    
    -- references
    self.Seat         = model:FindFirstChild('Seat')
    self.Handle       = model:FindFirstChild('Handle')
    self.FlushSound   = model:FindFirstChild('ToiletBowl'):FindFirstChild('Sound')
    self.Water        = model:FindFirstChild('Water')
    self.WaterSwirls  = getNamedChildren(model, 'WaterSwirl')
    self.Interactives = getNamedChildren(model.Handle, 'Interactive')

    -- turd cache
    self.FecalMatter = {}

    -- signal chache
    self.Binds = {}
   
    return self
end



---------------------------------------------------------------



function Toliet:Flush()
    if self.Flushing then return end

    local startCF = self.Water.CFrame

    self.Flushing = true

    self.FlushSound:Play()
    animateHandle(self.Handle, self.Config)

    -- @TODO: animate flushing
        --animate standing water surge then drain
        -- animate water particles to fade out
        -- if water was dirty then return it to clean
        -- animate standing water to refill

	updateSwirls(self.WaterSwirls, 40)
    
    wait()

    -- surge
	for _ = 1, 4 do
        self.Water.CFrame = self.Water.CFrame * CFrame.new(0, 0.01, 0)
        
        for i = 1, #self.FecalMatter do
            self.FecalMatter[i].CFrame = self.FecalMatter[i].CFrame * CFrame.new(0, 0.01, 0)
        end
		wait()
    end
    
    
    -- drain
    for _ = 1, 22 do
        self.Water.Mesh.Scale = self.Water.Mesh.Scale + Vector3.new(-0.02, 0, -0.02)
        self.Water.CFrame = self.Water.CFrame * CFrame.new(0, -0.015, 0)

        for i = 1, #self.FecalMatter do
			local fecalShrinkStep = Vector3.new(
		        -self.FecalMatter[i].Size.X/22, 
		        -self.FecalMatter[i].Size.Y/22, 
		        -self.FecalMatter[i].Size.Z/22
			    )
			
            self.FecalMatter[i].CFrame = self.FecalMatter[i].CFrame * CFrame.new(0, -0.015, 0)
            
            self.FecalMatter[i].Size = self.FecalMatter[i].Size + fecalShrinkStep
        end

        wait()
    end

    for i = 1, #self.FecalMatter do
        self.FecalMatter[i]:Destroy()
    end

    wait(1)
    updateSwirls(self.WaterSwirls, 0)
    if self.Used then
        self.Water.Color = self.Config.CleanWaterColor
        self.Used = false
    end

    -- refill

    for i = 1, 66 do
        self.Water.Mesh.Scale =  self.Water.Mesh.Scale + Vector3.new(0.0066, 0, 0.0066)
        self.Water.CFrame =  self.Water.CFrame * CFrame.new(0, 0.00409, 0)
        wait()
    end

    self.Water.CFrame = startCF

    wait()

    self.Flushing = false
end




---------------------------------------------------------------


function Toliet:_bind()

    -- seat 
    table.insert(self.Binds, self.Seat.ChildAdded:Connect(function(child)

        if self.Used then return end

        if not child.Name == 'SeatWeld' then return end
    
        local player = Players:GetPlayerFromCharacter(child.Part1.Parent)
        
        if player then
          
            self.Water.Color = self.Config.DirtyWaterColor

            local turd = Instance.new("Part")
            turd.Size = getRanVector3(self.Config.FecalExtents.Min, self.Config.FecalExtents.Max)
            turd.Color = self.Config.FecalColor
            turd.Anchored = true

            local ranY = ran:NextNumber(0, math.pi * 2)

            turd.CFrame = self.Water.CFrame * CFrame.Angles(0, ranY, 0)
            turd.Parent = self.Water.Parent

            table.insert(self.FecalMatter, turd)
            self.Used = true
        end
    end))


    -- flusher
    for i = 1, #self.Interactives do
        local clickDetect = self.Interactives[i]:FindFirstChildOfClass('ClickDetector')

        
        if clickDetect then
            table.insert(self.Binds, clickDetect.MouseClick:Connect(function()
                self:Flush()
            end))
        end
    end
end



-- cleanup
function Toliet:_unbind()
    for i = 1, #self.Binds do
        self.Binds[i]:Disconnect()
        self.Binds[i] = nil
    end
end


---------------------------------------------------------------


return Toliet