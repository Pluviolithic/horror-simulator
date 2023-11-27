return {
	hasTimeLeft = function(startTime, duration)
		return (os.time() - startTime) <= duration
	end,
	getFormattedRemainingTime = function(startTime, duration)
		local timeLeft = duration - (os.time() - startTime)
		local minutes = math.floor(timeLeft / 60)

		if minutes < 1 then
			return timeLeft .. "s"
		else
			return minutes .. "m"
		end
	end,
}
