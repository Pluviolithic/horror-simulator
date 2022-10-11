local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)

local function updateClientMiddleware(nextDispatch)
	return function(action)
		Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		return nextDispatch(action)
	end
end

-- will want to come up with a more generalized function to
-- simplify this middleware and allow for expansion to other
-- save values
local function savePlayerDataMiddleware(nextDispatch)
	return function(action)
		if profiles[action.playerName] then
			if action.type == "incrementPlayerStat" then
				profiles[action.playerName].Data[action.statName] += (action.incrementAmount or 1)
			end
		end
		return nextDispatch(action)
	end
end

local function updateLeaderboardMiddleware(nextDispatch)
	return function(action)
		if action.type == "incrementPlayerStat" then
			local player = Players:FindFirstChild(action.playerName)
			local stat = player and player.leaderstats:FindFirstChild(action.statName)
			if stat then
				stat.Value = formatter.formatNumberWithSuffix(
					profiles[action.playerName].Data[action.statName] + (action.incrementAmount or 1)
				)
			end
		end
		return nextDispatch(action)
	end
end

return {
	savePlayerDataMiddleware,
	updateLeaderboardMiddleware,
	updateClientMiddleware,
	Rodux.loggerMiddleware,
}
