-- Timer module

local Timer = {}

function Timer.new(interval, repeatTimer, callback)
	local timer = {}
	timer.interval = interval or 60 -- Default interval of 60 seconds
	timer.repeatTimer = repeatTimer or false
	timer.callback = callback or function() end
	timer.enabled = false

	function timer:start()
		self.enabled = true
		coroutine.wrap(function()
			while self.enabled do
				wait(self.interval)
				self.callback()
				if not self.repeatTimer then
					self:stop()
				end
			end
		end)()
	end

	function timer:stop()
		self.enabled = false
	end

	return timer
end

return Timer
