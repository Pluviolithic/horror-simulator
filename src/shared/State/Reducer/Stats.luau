local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce, None = Immut.produce, Immut.None

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = Dict.mergeDeep(defaultStates.Stats, action.profileData.Stats)
        end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
            draft[action.playerName] = None
        end)
	end,
	resetPlayerData = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName] = defaultStates.Stats
        end)
	end,
	incrementPlayerStat = function(state, action)
        return produce(state, function(draft)
            draft[action.playerName][action.statName] += (action.incrementAmount or 1)
        end)
	end,
	givePlayerPets = function(state, action)
		local addedPetCount = 0
		for _, quantity in action.petsToGive do
			addedPetCount += quantity
		end
        return produce(state, function(draft)
            draft[action.playerName].PetCount += addedPetCount
        end)
	end,
	deletePlayerPets = function(state, action)
		local removedPetCount = 0
		for _, quantity in action.petsToDelete do
			removedPetCount -= quantity
		end
        return produce(state, function(draft)
            draft[action.playerName].PetCount += removedPetCount
        end)
	end,
	equipPlayerPets = function(state, action)
		local addedPetEquipCount = 0
		local addedPetFearMultiplier = 0
		for petName, quantity in action.petsToEquip do
			addedPetEquipCount += quantity
			addedPetFearMultiplier += petUtils.getPet(petName).Multiplier.Value * quantity
		end
        return produce(state, function(draft)
            draft[action.playerName].PetEquipCount += addedPetEquipCount
            draft[action.playerName].PetFearMultiplier += addedPetFearMultiplier
        end)
	end,
	unequipPlayerPets = function(state, action)
		local removedPetEquipCount = 0
		local removedPetFearMultiplier = 0
		for petName, quantity in action.petsToUnequip do
			removedPetEquipCount -= quantity
			removedPetFearMultiplier -= petUtils.getPet(petName).Multiplier.Value * quantity
		end
        return produce(state, function(draft)
            draft[action.playerName].PetEquipCount += removedPetEquipCount
            draft[action.playerName].PetFearMultiplier += removedPetFearMultiplier
        end)
	end,
})
