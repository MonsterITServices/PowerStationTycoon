local tweenSer = game:GetService('TweenService')

local function getButtons(gateContainer)
	local buttons = {}
	
	local parts = gateContainer:GetChildren()
	
	for i = 1, #parts do
		if parts[i].Name == 'GateButton' then
			table.insert(buttons, parts[i])
			
			if not parts[i]:FindFirstChild('ClickDetector') then
				local a = Instance.new('ClickDetector')
				a.Parent = parts[i]
			end
		end
	end
	
	return buttons
end

local function setupMoved(gateMoved)
	local boundCf, boundSize = gateMoved:GetBoundingBox()
	
	local primaryPart = Instance.new('Part')
	primaryPart.Name = 'GatePrimary'
	primaryPart.CFrame = boundCf
	primaryPart.Size = boundSize
	primaryPart.Transparency = 1
	primaryPart.CanCollide = false
	primaryPart.Anchored = true
	primaryPart.Parent = gateMoved
	
	gateMoved.PrimaryPart = primaryPart
end

local SlidingGate = {}
SlidingGate.__index = SlidingGate

function SlidingGate.new(gateContainer)
	local self = setmetatable({}, SlidingGate)
	
	self.Buttons = getButtons(gateContainer)
	
	self.Gate = gateContainer:FindFirstChild('GateMoved')
	self.OpenStopper = gateContainer:FindFirstChild('GateOpen')
	self.ClosedStopper = gateContainer:FindFirstChild('GateClose')
	self.Motor = gateContainer:FindFirstChild('MotorHinge',true)
	
	self.Open = false
	self.Signals = {}
	self.Value = Instance.new('CFrameValue')
	self.ValueBind = nil
	
	setupMoved(self.Gate)
	
	self.StopBlink = false
	
	return self
end

function SlidingGate:BlinkButtons(yield)
	
	spawn(function()
		while not self.StopBlink do
			for i = 1, #self.Buttons do
				self.Buttons[i].Transparency = .8
			end
			wait(yield)
			if self.StopBlink then 
				for i = 1, #self.Buttons do
					self.Buttons[i].Transparency = 0
				end
				
				break 
			end
			for i = 1, #self.Buttons do
				self.Buttons[i].Transparency = 0
			end
			wait(yield)
		end
		self.StopBlink = false
	end)
	
end

function SlidingGate:SetButtonColor(color)
	for i = 1, #self.Buttons do
		self.Buttons[i].Color = color
	end
end

function SlidingGate:BindButtons()
	self:SetButtonColor(Color3.new(0,1,0))
	
	for i = 1, #self.Buttons do
		local clickDetect = self.Buttons[i]:FindFirstChild('ClickDetector')
		table.insert(self.Signals, clickDetect.MouseClick:Connect(function()
			if self.Open then return end
			
			self.Open = true
			
			local targCf = self:GetOpenTarget()
			
			self:SetButtonColor(Color3.new(1,0,0))
			
			self:BlinkButtons(.3)
			
			self.Motor.AngularVelocity = 5
			
			self:PlayPrimaryPartTween(targCf)
			
			self.Motor.AngularVelocity = 0
			
			self.StopBlink = true
			wait(.31)

			self:SetButtonColor(Color3.new(1,1,0))
			
			self.StopBlink = false
			self:BlinkButtons(.6)
			wait(15)
			self.StopBlink = true
			wait(.61)
			
			self:BlinkButtons(.3)
			
			self:SetButtonColor(Color3.new(1,0,0))
			
			local closeCf = self:GetCloseTarget()
			self.Motor.AngularVelocity = -5
			
			self:PlayPrimaryPartTween(closeCf)
			
			self.Motor.AngularVelocity = 0 
			
			self:SetButtonColor(Color3.new(0,1,0))
			
			self.StopBlink = true
			wait(.31)
			self.StopBlink = false
			
			self.Open = false
		end))
	end
end

function SlidingGate:PlayPrimaryPartTween(targCf)
	
	self.Value.Value = self.Gate.PrimaryPart.CFrame
	
	local tinfo = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local targets = {
		Value = targCf	
	}
	
	local tween = tweenSer:Create(self.Value, tinfo, targets)
	
	self.ValueBind = self.Value.Changed:Connect(function(newcf)
		self.Gate:SetPrimaryPartCFrame(newcf)
	end)
	
	tween:Play()
	tween.Completed:Wait()
	
	self.ValueBind:Disconnect()
	
	return true
end

function SlidingGate:GetOpenTarget()
	local diff = self.OpenStopper.Position - self.ClosedStopper.Position
	local diffFixed = diff.Unit * (diff.Magnitude - (self.OpenStopper.Size.X * .5 + self.Gate.PrimaryPart.Size.X))
	local thisStopPos = self.ClosedStopper.Position
	
	
	local targPos = Vector3.new(thisStopPos.X, self.Gate.PrimaryPart.Position.Y, thisStopPos.Y) + diffFixed
			
	local targCf =  self.Gate.PrimaryPart.CFrame +diffFixed--* CFrame.new(targPos - self.Gate.PrimaryPart.Position)--self.Gate.PrimaryPart.Position - targPos)
	
	return targCf
end


function SlidingGate:GetCloseTarget()
	local diff = self.ClosedStopper.Position - self.OpenStopper.Position
	local diffFixed = diff.Unit * (diff.Magnitude - (self.ClosedStopper.Size.X * .5 + self.Gate.PrimaryPart.Size.X))
	local thisStopPos = self.OpenStopper.Position
	
	local targPos = Vector3.new(thisStopPos.X, self.Gate.PrimaryPart.Position.Y, thisStopPos.Y) + diffFixed
	local targCf = self.Gate.PrimaryPart.CFrame +diffFixed--* CFrame.new(targPos - self.Gate.PrimaryPart.Position)--self.Gate.PrimaryPart.Position - targPos)
	
	return targCf
end

return SlidingGate