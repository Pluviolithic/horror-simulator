local clock = {}

function clock.hasTimeLeft(startTime, duration)
	return (os.time() - startTime) < duration
end

task.spawn(function()
	while true do
		task.wait(1)
	end
end)

return clock
