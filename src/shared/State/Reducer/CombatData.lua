local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.CombatData, action.profileData.CombatData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.CombatData)
		end)
	end,
	switchPlayerEnemy = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].CurrentEnemy = action.enemy or nil
		end)
	end,
	setCurrentPunchingBag = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].CurrentPunchingBag = action.currentPunchingBag
		end)
	end,
})
