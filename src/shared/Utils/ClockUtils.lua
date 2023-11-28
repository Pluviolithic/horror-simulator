local ReplicatedStorage = game:GetService "ReplicatedStorage"

local chestTimerLength = ReplicatedStorage.Config.DevProductData.Chests.ChestTimerLength.Value

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
	getFormattedChestTimer = function(startTime)
		local timeLeft = chestTimerLength - (os.time() - startTime)
		local hours = math.floor(timeLeft / 3600)
		local minutes = math.floor((timeLeft - (hours * 3600)) / 60)
		local seconds = timeLeft - (hours * 3600) - (minutes * 60)

		if timeLeft < 1 then
			return "READY!"
		end

		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end,
}
