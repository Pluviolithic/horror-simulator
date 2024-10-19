local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local teleportPlayer = require(StarterPlayer.StarterPlayerScripts.Client.Areas.TeleportPlayer)

local displayClientLogs = ReplicatedStorage.Config.Output.DisplayClientLogs.Value

local function teleportPlayerMiddleware(nextDispatch)
	return function(action)
		if action.type == "resetPlayerData" then
			teleportPlayer {}
		end
		nextDispatch(action)
	end
end

return {
	teleportPlayerMiddleware,
	if displayClientLogs then Rodux.loggerMiddleware else nil,
}
