local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Dict = require(ReplicatedStorage.Common.lib.Sift).Dict
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local petUtils = require(ReplicatedStorage.Common.Utils.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		local playerStatData = Dict.Filter(action.playerData, function(key)
			return Dict.has(defaultStates.Stats, key)
		end)
		return Dict.set(state, action.playerName, Dict.merge(defaultStates.Stats, playerStatData))
	end,
	removePlayer = function(state, action)
		return Dict.removeKey(state, action.playerName)
	end,
	resetPlayerData = function(state, action)
		return Dict.set(state, action.playerName, defaultStates.Stats)
	end,
	incrementPlayerStat = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				[action.statName] = state[action.playerName][action.statName] + (action.incrementAmount or 1),
			},
		})
	end,
	givePlayerPets = function(state, action)
		local newPetCount = 0
		for _, quantity in action.petsToGive do
			newPetCount += quantity
		end
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				PetCount = state[action.playerName].PetCount + newPetCount,
			},
		})
	end,
	deletePlayerPets = function(state, action)
		local removePetCount = 0
		for _, quantity in action.petsToDelete do
			removePetCount -= quantity
		end
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				PetCount = state[action.playerName].PetCount + removePetCount,
			},
		})
	end,
	equipPlayerPets = function(state, action)
		local newPetEquipCount = 0
		local newPetFearMultiplier = 0
		for petName, quantity in action.petsToEquip do
			newPetEquipCount += quantity
			newPetFearMultiplier += petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				PetEquipCount = state[action.playerName].PetEquipCount + newPetEquipCount,
				PetFearMultiplier = state[action.playerName].PetFearMultiplier + newPetFearMultiplier,
			},
		})
	end,
	unequipPlayerPets = function(state, action)
		local removePetEquipCount = 0
		local removePetFearMultiplier = 0
		for petName, quantity in action.petsToUnequip do
			removePetEquipCount -= quantity
			removePetFearMultiplier -= petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				PetEquipCount = state[action.playerName].PetEquipCount + removePetEquipCount,
				PetFearMultiplier = state[action.playerName].PetFearMultiplier + removePetFearMultiplier,
			},
		})
	end,
})
