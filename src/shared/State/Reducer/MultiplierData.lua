local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.MultiplierData, action.profileData.MultiplierData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = defaultStates.MultiplierData
		end)
	end,
	incrementPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			if state[action.playerName][action.multiplierName] < 2 then
				draft[action.playerName][action.multiplierName] += action.incrementAmount - 1
			else
				draft[action.playerName][action.multiplierName] += action.incrementAmount
			end
			if draft[action.playerName][action.multiplierName] < 1 then
				draft[action.playerName][action.multiplierName] += 1
			end
		end)
	end,
	setPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.multiplierName] = action.value
			if draft[action.playerName][action.multiplierName] < 1 then
				draft[action.playerName][action.multiplierName] += 1
			end
		end)
	end,
	equipPlayerPets = function(state, action)
		local addedFearMultiplier = 0
		for petName, quantity in action.petsToEquip do
			addedFearMultiplier += petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return produce(state, function(draft)
			if state[action.playerName].FearMultiplier < 2 then
				draft[action.playerName].FearMultiplier += addedFearMultiplier - 1
			else
				draft[action.playerName].FearMultiplier += addedFearMultiplier
			end
			if draft[action.playerName].FearMultiplier < 1 then
				draft[action.playerName].FearMultiplier += 1
			end
		end)
	end,
	unequipPlayerPets = function(state, action)
		local removedFearMultiplier = 0
		for petName, quantity in action.petsToUnequip do
			removedFearMultiplier -= petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].FearMultiplier += removedFearMultiplier
			if draft[action.playerName].FearMultiplier < 1 then
				draft[action.playerName].FearMultiplier += 1
			end
		end)
	end,
})
