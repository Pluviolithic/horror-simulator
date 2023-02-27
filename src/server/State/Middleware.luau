local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

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

local function updateLeaderboardMiddleware(nextDispatch)
	return function(action)
		if action.type == "incrementPlayerStat" then
			local player = Players:FindFirstChild(action.playerName)
			local stat: StringValue? = if player and player:FindFirstChild "leaderstats"
				then player.leaderstats:FindFirstChild(action.statName)
				else nil
			if stat then
				stat.Value = formatter.formatNumberWithSuffix(profiles[action.playerName].Data[action.statName])
			end
		end
		return nextDispatch(action)
	end
end

return {
	savePlayerDataMiddleware,
	updateLeaderboardMiddleware,
	updateClientMiddleware,
	if displayServerLogs then Rodux.loggerMiddleware else nil,
}
