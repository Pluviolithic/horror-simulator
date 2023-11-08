local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.AudioData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.AudioData)
		end)
	end,
	addOccupiedSoundRegion = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].OccupiedSoundRegions[action.occupiedSoundRegion] = true
		end)
	end,
	removeOccupiedSoundRegion = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].OccupiedSoundRegions[action.deoccupiedSoundRegion] = nil
		end)
	end,
	setPrimarySoundRegion = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].PrimarySoundRegion = action.primarySoundRegion
		end)
	end,
})
