local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local server = ServerScriptService.Server

local actions = require(server.State.Actions)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local Count = require(ReplicatedStorage.Common.lib.Sift).Dictionary.count

local rebirthMultipliers = {}
local applyMultiplierToNegativeWhitelist = {}

for _, multiplierValue in ReplicatedStorage.Config.Rebirth.StrengthMultipliers:GetChildren() do
	table.insert(rebirthMultipliers, {
		RangeStart = tonumber(multiplierValue.Name),
		Multiplier = multiplierValue.Value,
	})
end

table.sort(rebirthMultipliers, function(a, b)
	return a.RangeStart < b.RangeStart
end)

local function modifiedBinarySearch(array, value)
	local low = 1
	local high = #array
	local mid = math.floor((low + high) / 2)
	while low <= high do
		if array[mid].RangeStart <= value and array[mid + 1].RangeStart > value then
			return array[mid].Multiplier
		elseif array[mid].RangeStart > value then
			high = mid - 1
		else
			low = mid + 1
		end
		mid = math.floor((low + high) / 2)
	end
	return array[#array].Multiplier
end

return function(nextDispatch, store)
	return function(action)
		local initialMaxFearMeter = nil
		if action.playerName and selectors.isPlayerLoaded(store:getState(), action.playerName) then
			initialMaxFearMeter =
				rankUtils.getMaxFearMeterFromRank(selectors.getStat(store:getState(), action.playerName, "Rank"))
		end
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

				if action.statName == "Fear" then
					multiplier += 0.15 * Count(multiplierData.ActiveFriendsWhoJoined)
					multiplier += 0.1 * selectors.getStat(store:getState(), action.playerName, "MissionAreasCompleted")
				end

				if action.statName == "Strength" then
					multiplier += 0.1 * selectors.getRebirthUpgradeLevel(
						store:getState(),
						action.playerName,
						"MoreStrength"
					)
				elseif action.statName == "Fear" then
					multiplier += 0.1 * selectors.getRebirthUpgradeLevel(
						store:getState(),
						action.playerName,
						"MoreFear"
					)
				elseif action.statName == "Gems" then
					multiplier += 0.1 * selectors.getRebirthUpgradeLevel(
						store:getState(),
						action.playerName,
						"MoreGems"
					)
				end

				local boostData = action.statName ~= "Luck"
					and selectors.getActiveBoosts(store:getState(), action.playerName)[action.statName .. "Boost"]

				if multiplierCount < 1 then
					action.incrementAmount *= (1 + multiplier) * (boostData and 2 or 1)
				else
					action.incrementAmount *= multiplier * (boostData and 2 or 1)
				end

				if action.statName == "Strength" then
					local rebirths = selectors.getStat(store:getState(), action.playerName, "Rebirths")
					action.incrementAmount *= (1 + modifiedBinarySearch(rebirthMultipliers, rebirths) * rebirths)
				end
			end
		end
		nextDispatch(action)
		local endMaxFearMeter = nil
		if action.playerName and selectors.isPlayerLoaded(store:getState(), action.playerName) then
			endMaxFearMeter =
				rankUtils.getMaxFearMeterFromRank(selectors.getStat(store:getState(), action.playerName, "Rank"))
		end
		if endMaxFearMeter and initialMaxFearMeter ~= endMaxFearMeter then
			local multiplier = selectors.getMultiplierData(store:getState(), action.playerName).MaxFearMeterMultiplier
				or 1
			store:dispatch(actions.setPlayerStat(action.playerName, "MaxFearMeter", endMaxFearMeter * multiplier))
		end
	end
end
