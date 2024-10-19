local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.PurchaseData, action.profileData.PurchaseData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.PurchaseData)
		end)
	end,
	awardGamepassToPlayer = function(state, action)
		return produce(state, function(draft)
			if draft[action.playerName] then
				draft[action.playerName].AwardedGamepasses[tostring(action.gamepassID)] = true
			end
		end)
	end,
	givePlayerTeleporter = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].PurchasedTeleporters[action.areaName] = true
		end)
	end,
	incrementPlayerBoostCount = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].PurchasedBoosts[action.boostName] = (
				draft[action.playerName].PurchasedBoosts[action.boostName] or 0
			) + (action.incrementAmount or 1)
		end)
	end,
	applyBoostToPlayer = function(state, action)
		return produce(state, function(draft)
			local currentBoostData = draft[action.playerName].ActiveBoosts[action.boostName:match "%D+"]
			if currentBoostData then
				currentBoostData.Duration += tonumber(action.boostName:match "%d*%.?%d+") :: number * 60
			else
				draft[action.playerName].ActiveBoosts[action.boostName:match "%D+"] = {
					StartTime = os.time(),
					Duration = tonumber(action.boostName:match "(%d*%.?%d+)") :: number * 60,
				}
			end
		end)
	end,
	removeBoostFromPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].ActiveBoosts[action.boostName:match "%D+"] = nil
		end)
	end,
	redeemCode = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].RedeemedCodes[action.code] = true
		end)
	end,
	rebirthPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].PurchasedTeleporters = {}
		end)
	end,
	incrementRebirthUpgradeLevel = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].RebirthUpgrades[action.upgradeName] += 1
		end)
	end,
})
