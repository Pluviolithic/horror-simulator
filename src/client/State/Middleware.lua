local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)

return {
	Rodux.loggerMiddleware,
}
