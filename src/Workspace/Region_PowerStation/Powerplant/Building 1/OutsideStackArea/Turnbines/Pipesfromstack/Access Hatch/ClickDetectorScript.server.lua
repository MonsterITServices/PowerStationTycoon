local isOn = true

function on()
	isOn = true
	script.Parent.Door1.CanCollide = true
	script.Parent.Door1.Transparency = 0
	script.Parent.Handle1.Transparency = 0
	script.Parent.Door2.CanCollide = false
	script.Parent.Door2.Transparency = 1
	script.Parent.Handle2.Transparency = 1
end

function off()
	isOn = false
	script.Parent.Door1.CanCollide = false
	script.Parent.Door1.Transparency = 1
	script.Parent.Handle1.Transparency = 1
	script.Parent.Door2.CanCollide = true
	script.Parent.Door2.Transparency = 0
	script.Parent.Handle2.Transparency = 0
end

function onClicked()
	
	if isOn == true then off() else on() end

end

script.Parent.Handle1.ClickDetector.MouseClick:connect(onClicked)
script.Parent.Handle2.ClickDetector.MouseClick:connect(onClicked)

on()