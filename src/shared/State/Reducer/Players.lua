local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local Llama = require(ReplicatedStorage.Common.lib.Llama)

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = defaultStates.PlayerState,
		})
	end,
	removePlayer = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = Llama.None,
		})
	end,
	updatePlayerWithProfile = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = action.profileData,
		})
	end,
	incrementPlayerStat = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				[action.statName] = state[action.playerName][action.statName] + (action.incrementAmount or 1),
			},
		})
	end,
	switchPlayerEnemy = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentEnemy = action.enemy or Llama.None,
			},
		})
	end,
	resetPlayerData = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = defaultStates.PlayerState,
		})
	end,
	setCurrentPunchingBag = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentPunchingBag = action.currentPunchingBag or Llama.None,
			},
		})
	end,
	updateRequiredFear = function(state, action)
		return Llama.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				RequiredFear = state[action.playerName].RequiredFear + action.amount,
			},
		})
	end,
})
