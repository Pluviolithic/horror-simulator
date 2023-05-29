local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce, None = Immut.produce, Immut.None

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = Dict.mergeDeep(defaultStates.PurchaseData, action.profileData.PurchaseData)
        end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
            draft[action.playerName] = None
        end)
	end,
	resetPlayerData = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = defaultStates.PurchaseData
        end)
	end,
    awardGamepassToPlayer = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName].AwardedGamepasses[action.gamepassID] = true
        end)
    end,
})
