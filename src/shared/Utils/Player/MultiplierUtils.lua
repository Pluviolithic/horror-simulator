local RunService = game:GetService "RunService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)

local store
if RunService:IsServer() then
	store = require(game:GetService("ServerScriptService").Server.State.Store)
else
	store = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.State.Store)
end

return {
	getMultiplierAdjustedStat = function(player, statName, amount)
		local multiplier = selectors.getMultiplierData(store:getState(), player.Name)[statName .. "Multiplier"]
		local multiplierCount = selectors.getMultiplierData(store:getState(), player.Name)[statName .. "MultiplierCount"]
			or 0
		local boostData = selectors.getActiveBoosts(store:getState(), player.Name)[statName .. "Boost"]

		if multiplierCount < 1 then
			return amount * (1 + multiplier) * (boostData and 2 or 1)
		else
			return amount * multiplier * (boostData and 2 or 1)
		end
	end,
}
