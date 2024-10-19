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

for i = 1, #rebirthMultipliers - 1 do
	rebirthMultipliers[i].PreComputedResult = (rebirthMultipliers[i + 1].RangeStart - rebirthMultipliers[i].RangeStart)
		* rebirthMultipliers[i].Multiplier
end

local function modifiedBinarySearch(array, value)
	local low = 1
	local high = #array
	local mid = math.floor((low + high) / 2)
	while low <= high do
		if array[mid].RangeStart <= value and (not array[mid + 1] or array[mid + 1].RangeStart > value) then
			return mid
		elseif array[mid].RangeStart > value then
			high = mid - 1
		else
			low = mid + 1
		end
		mid = math.floor((low + high) / 2)
	end
	return #array
end

local function getRebirthStrengthMultiplier(array, rebirths)
	local multiplier = 1
	local index = modifiedBinarySearch(array, rebirths)
	if index == 1 then
		return multiplier + rebirths * array[1].Multiplier
	end
	for i = 1, index - 1 do
		rebirths -= (array[i + 1].RangeStart - array[i].RangeStart)
		multiplier += array[i].PreComputedResult
	end
	return multiplier + rebirths * array[index].Multiplier
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
					local endMaxFearMeter = nil
					if action.playerName and selectors.isPlayerLoaded(store:getState(), action.playerName) then
						endMaxFearMeter = rankUtils.getMaxFearMeterFromRank(
							selectors.getStat(store:getState(), action.playerName, "Rank")
						)
					end
					if endMaxFearMeter and initialMaxFearMeter ~= endMaxFearMeter then
						local multiplier = selectors.getMultiplierData(store:getState(), action.playerName).MaxFearMeterMultiplier
							or 1
						store:dispatch(
							actions.setPlayerStat(action.playerName, "MaxFearMeter", endMaxFearMeter * multiplier)
						)
					end
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
					action.incrementAmount *= getRebirthStrengthMultiplier(
						rebirthMultipliers,
						selectors.getStat(store:getState(), action.playerName, "Rebirths")
					)
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
