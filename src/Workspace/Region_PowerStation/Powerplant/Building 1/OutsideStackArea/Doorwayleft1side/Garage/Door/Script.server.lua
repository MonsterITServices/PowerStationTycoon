door = script.Parent



 function clickit()

door.Transparency = 1

door.CanCollide = false
wait(5)
door.Transparency = 0
door.CanCollide = true

end

door.ClickDetector.MouseClick:connect(clickit)