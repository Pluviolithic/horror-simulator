local ReplicatedStorage = game:GetService "ReplicatedStorage"

local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)

return function(_, timestamp: string)
	return clockUtils.setMonthlyTimestampOverride(timestamp)
end
