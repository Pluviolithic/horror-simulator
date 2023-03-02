local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)

local displayServerLogs = ReplicatedStorage.Config.Output.DisplayServerLogs.Value

local function updateClientMiddleware(nextDispatch)
	return function(action)
		local replicationRule = replicationRules[action.type]
		if replicationRule == Enum.ReplicationRules.All then
			Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		elseif replicationRule ~= Enum.ReplicationRules.None then
			Remotes.Server:Get("SendRoduxAction"):SendToPlayer(Players[action.playerName], action)
		end
		return nextDispatch(action)
	end
end

return {
	updateClientMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
