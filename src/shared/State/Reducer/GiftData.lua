local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.GiftData, action.profileData.GiftData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.GiftData)
		end)
	end,
	claimGift = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].ClaimedGifts[action.giftName] = true
		end)
	end,
	resetGifts = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.GiftData)
		end)
	end,
	skipAllGiftTimers = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].SkippedAll = true
		end)
	end,
})
