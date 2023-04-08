local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local Dict = Sift.Dictionary

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		local playerPetData = Dict.Filter(action.playerData, function(key)
			return Dict.has(defaultStates.PetData, key)
		end)
		return Dict.set(state, action.playerName, Dict.merge(defaultStates.PetData, playerPetData))
	end,
	removePlayer = function(state, action)
		return Dict.removeKey(state, action.playerName)
	end,
	resetPlayerData = function(state, action)
		return Dict.set(state, action.playerName, defaultStates.PetData)
	end,
	givePlayerPets = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = Dict.map(action.petsToGive, function(value, key)
					return value + (state[action.playerName].OwnedPets[key] or 0), key
				end),
				FoundPets = Dict.map(action.petsToGive, function(_, key)
					return true, key
				end),
			},
		})
	end,
	deletePlayerPets = function(state, action)
		local newOwnedPets = Dict.map(action.petsToDelete, function(value, key)
			local newOwnedAmount = (state[action.playerName].OwnedPets[key] or 0) - value
			if newOwnedAmount < 1 then
				newOwnedAmount = Sift.None
			end
			return newOwnedAmount, key
		end)
		return Dict.mergeDeep(state, {
			[action.playerName] = newOwnedPets,
		})
	end,
	equipPlayerPets = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				EquippedPets = Dict.map(action.petsToEquip, function(value, key)
					return value + (state[action.playerName].EquippedPets[key] or 0), key
				end),
				--[[
                    --player may have equipped an already locked pet
                    --need to account for this or simply make a separate
                    --action for locking the associated pets
				LockedPets = Dict.map(action.petsToEquip, function(value, key)
					return value + (state[action.playerName].LockedPets[key] or 0), key
				end),
                ]]
			},
		})
	end,
	unequipPlayerPets = function(state, action)
		local newEquippedPets = Dict.map(action.petsToUnequip, function(value, key)
			local newEquipAmount = (state[action.playerName].EquippedPets[key] or 0) - value
			if newEquipAmount < 1 then
				newEquipAmount = Sift.None
			end
			return newEquipAmount, key
		end)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				EquippedPets = newEquippedPets,
			},
		})
	end,
	lockPlayerPets = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = Dict.map(action.petsToLock, function(value, key)
					return value + (state[action.playerName].LockedPets[key] or 0), key
				end),
			},
		})
	end,
	unlockPlayerPets = function(state, action)
		local newLockedPets = Dict.map(action.petsToUnlock, function(value, key)
			local newLockAmount = (state[action.playerName].LockedPets[key] or 0) - value
			if newLockAmount < 1 then
				newLockAmount = Sift.None
			end
			return newLockAmount, key
		end)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = newLockedPets,
			},
		})
	end,
})
