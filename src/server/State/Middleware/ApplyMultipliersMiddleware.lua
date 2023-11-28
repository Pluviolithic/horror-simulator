local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local actions = require(server.State.Actions)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local applyMultiplierToNegativeWhitelist = {}

return function(nextDispatch, store)
	return function(action)
		if action.statName and action.incrementAmount then
			if action.incrementAmount > 0 or applyMultiplierToNegativeWhitelist[action.statName] then
				local multiplierData = selectors.getMultiplierData(store:getState(), action.playerName)
				if not multiplierData or action.skipMultipliers then
					nextDispatch(action)
					return
				end
				local multiplier = multiplierData[action.statName .. "Multiplier"] or 0
				local multiplierCount = multiplierData[action.statName .. "MultiplierCount"] or 0

				if action.source then
					local sourceMultiplier = multiplierData[action.source .. action.statName .. "Multiplier"] or 0
					local sourceMultiplierCount = multiplierData[action.source .. action.statName .. "MultiplierCount"]
						or 0

					multiplier += sourceMultiplier
					multiplierCount += sourceMultiplierCount
				end

				local boostData =
					selectors.getActiveBoosts(store:getState(), action.playerName)[action.statName .. "Boost"]

				if multiplierCount < 1 then
					action.incrementAmount *= (1 + multiplier) * (boostData and 2 or 1)
				else
					action.incrementAmount *= multiplier * (boostData and 2 or 1)
				end
			end
		end
		nextDispatch(action)
		if action.statName == "Strength" then
			local multiplier = selectors.getMultiplierData(store:getState(), action.playerName).MaxFearMeterMultiplier
				or 1
			store:dispatch(
				actions.setPlayerStat(
					action.playerName,
					"MaxFearMeter",
					rankUtils.getMaxFearMeterFromRank(selectors.getStat(store:getState(), action.playerName, "Rank"))
						* multiplier
				)
			)
		end
	end
end
