local ReplicatedStorage = game:GetService "ReplicatedStorage"

local monthlyTimestampOverride = nil
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
	getFormattedGiftTime = function(timeLeft)
		local hours = math.floor(timeLeft / 3600)
		local minutes = math.floor((timeLeft - (hours * 3600)) / 60)
		local seconds = timeLeft - (hours * 3600) - (minutes * 60)

		if hours > 0 then
			return string.format("%02d:%02d:%02d", hours, minutes, seconds)
		else
			return string.format("%02d:%02d", minutes, seconds)
		end
	end,
	setMonthlyTimestampOverride = function(overrideValue: string)
		monthlyTimestampOverride = overrideValue
	end,
	getMonthlyTimestamp = function()
		return monthlyTimestampOverride or os.date("*t").month .. os.date("*t").year
	end,
}
