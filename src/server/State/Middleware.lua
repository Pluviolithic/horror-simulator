local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)

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
			if action.type == "incrementPlayerLogInCount" then
				profiles[action.playerName].Data.LogInCount += 1
			end
		end
		return nextDispatch(action)
	end
end

return {
	savePlayerDataMiddleware,
	updateClientMiddleware,
	Rodux.loggerMiddleware,
}
