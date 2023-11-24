local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)

local displayClientLogs = ReplicatedStorage.Config.Output.DisplayClientLogs.Value

return {
	if displayClientLogs then Rodux.loggerMiddleware else nil,
}
