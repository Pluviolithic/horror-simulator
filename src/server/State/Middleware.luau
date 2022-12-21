local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
--local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

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
			elseif action.type == "givePlayerWeapon" then
				profiles[action.playerName].Data.OwnedWeapons[action.weaponName] = true
			elseif action.type == "equipWeapon" then
				profiles[action.playerName].Data.EquippedWeapon = action.weaponName
			elseif action.type == "resetPlayerData" then
				profiles[action.playerName].Data = table.clone(profileTemplate)
			end
		end
		return nextDispatch(action)
	end
end

local function updateLeaderboardMiddleware(nextDispatch)
	return function(action)
		if action.type == "incrementPlayerStat" then
			local player: Player? = Players:FindFirstChild(action.playerName)
			local leaderstats: Folder? = if player then player:FindFirstChild("leaderstats") :: Folder? else nil
			local stat: StringValue? = if leaderstats then leaderstats:FindFirstChild(action.statName) :: StringValue? else nil
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
	--Rodux.loggerMiddleware,
}
