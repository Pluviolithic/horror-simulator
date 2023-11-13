local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value

return {
	require(script.ApplyMultipliersMiddleware),
	require(script.GiveMissionRewardsMiddleware),
	require(script.UpdateClientMiddleware),
	require(script.SavePlayerDataMiddleware),
	require(script.UpdateLeaderstatsMiddleware),
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
