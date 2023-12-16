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
			draft[action.playerName] = Dict.mergeDeep(defaultStates.PetData, action.profileData.PetData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.PetData)
		end)
	end,
	givePlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToGive do
				draft[action.playerName].OwnedPets[petName] = (state[action.playerName].OwnedPets[petName] or 0)
					+ quantity
				draft[action.playerName].FoundPets[petName] = true
			end
		end)
	end,
	deletePlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToDelete do
				draft[action.playerName].OwnedPets[petName] -= quantity
				if draft[action.playerName].OwnedPets[petName] < 1 then
					draft[action.playerName].OwnedPets[petName] = nil
				end
			end
		end)
	end,
	equipPlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToEquip do
				draft[action.playerName].EquippedPets[petName] = (draft[action.playerName].EquippedPets[petName] or 0)
					+ quantity
			end
		end)
	end,
	unequipPlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToUnequip do
				draft[action.playerName].EquippedPets[petName] -= quantity
				if draft[action.playerName].EquippedPets[petName] < 1 then
					draft[action.playerName].EquippedPets[petName] = nil
				end
			end
		end)
	end,
	lockPlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToLock do
				if petUtils.getPet(petName):FindFirstChild "PermaLock" and action.fromEquip then
					continue
				end
				draft[action.playerName].LockedPets[petName] = (draft[action.playerName].LockedPets[petName] or 0)
					+ quantity
			end
		end)
	end,
	unlockPlayerPets = function(state, action)
		return produce(state, function(draft)
			for petName, quantity in action.petsToUnlock do
				if petUtils.getPet(petName):FindFirstChild "PermaLock" and not action.force then
					continue
				end
				if not draft[action.playerName].LockedPets[petName] then
					continue
				end
				draft[action.playerName].LockedPets[petName] -= quantity
				if draft[action.playerName].LockedPets[petName] < 1 then
					draft[action.playerName].LockedPets[petName] = nil
				end
			end
		end)
	end,
})
