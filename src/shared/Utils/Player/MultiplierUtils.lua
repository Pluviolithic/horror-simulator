local RunService = game:GetService "RunService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local Count = require(ReplicatedStorage.Common.lib.Sift).Dictionary.count

local store
if RunService:IsServer() then
	store = require(game:GetService("ServerScriptService").Server.State.Store)
else
	store = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.State.Store)
end

return {
	getMultiplierAdjustedStat = function(player, statName, amount)
		local multiplierData = selectors.getMultiplierData(store:getState(), player.Name)
		local multiplier = multiplierData[statName .. "Multiplier"]
		local multiplierCount = multiplierData[statName .. "MultiplierCount"] or 0
		local boostData = selectors.getActiveBoosts(store:getState(), player.Name)[statName .. "Boost"]

		if statName == "Fear" then
			multiplier += 0.15 * Count(multiplierData.ActiveFriendsWhoJoined)
			multiplier += 0.1 * selectors.getStat(store:getState(), player.Name, "MissionAreasCompleted")
			multiplier += 0.1 * selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "MoreFear")
		end

		if statName == "Gems" then
			multiplier += 0.1 * selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "MoreGems")
		end

		if multiplierCount < 1 then
			return amount * (1 + multiplier) * (boostData and 2 or 1)
		else
			return amount * multiplier * (boostData and 2 or 1)
		end
	end,
}
