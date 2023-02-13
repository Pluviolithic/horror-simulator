local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local Sift = require(ReplicatedStorage.Common.lib.Sift)

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {},
		})
	end,
	removePlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = Sift.None,
		})
	end,
	updatePlayerWithProfile = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = Sift.Dictionary.mergeDeep(table.clone(defaultStates.PlayerState), action.profileData),
		})
	end,
	incrementPlayerStat = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				[action.statName] = state[action.playerName][action.statName] + (action.incrementAmount or 1),
			},
		})
	end,
	switchPlayerEnemy = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentEnemy = action.enemy or Sift.None,
			},
		})
	end,
	resetPlayerData = function(state, action)
		local newState = Sift.Dictionary.merge(state, {
			[action.playerName] = table.clone(defaultStates.PlayerState),
		})
		return newState
	end,
	setCurrentPunchingBag = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentPunchingBag = action.currentPunchingBag or Sift.None,
			},
		})
	end,
	givePlayerWeapon = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedWeapons = Sift.Dictionary.mergeDeep(state[action.playerName].OwnedWeapons, {
					[action.weaponName] = true,
				}),
			},
		})
	end,
	equipWeapon = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				EquippedWeapon = action.weaponName,
			},
		})
	end,
	givePlayerPets = function(state, action)
		local newOwnedPets = table.clone(state[action.playerName].OwnedPets)
		local newFoundPets = table.clone(state[action.playerName].FoundPets)
		for _, petName in ipairs(action.petNames) do
			newFoundPets[petName] = true
			newOwnedPets[petName] = if newOwnedPets[petName] then newOwnedPets[petName] + 1 else 1
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = newOwnedPets,
				FoundPets = newFoundPets,
				CurrentPetCount = state[action.playerName].CurrentPetCount + #action.petNames,
			},
		})
	end,
	awardGamepassToPlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				AwardedGamepasses = Sift.Dictionary.mergeDeep(state[action.playerName].AwardedGamepasses, {
					[action.gamepassID] = true,
				}),
			},
		})
	end,
	increaseMaxPetCount = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				MaxPetCount = state[action.playerName].MaxPetCount + action.amount,
			},
		})
	end,
	increasePlayerLuck = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				Luck = state[action.playerName].Luck + action.amount,
			},
		})
	end,
	equipPet = function(state, action)
		local petEquipCount = state[action.playerName].EquippedPets[action.petName] or 0
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				EquippedPets = Sift.Dictionary.mergeDeep(state[action.playerName].EquippedPets, {
					[action.petName] = petEquipCount + 1,
				}),
				PetFearMultiplier = state[action.playerName].PetFearMultiplier
					+ ReplicatedStorage.Pets:FindFirstChild(action.petName, true).Multiplier.Value,
				CurrentPetEquipCount = state[action.playerName].CurrentPetEquipCount + 1,
			},
		})
	end,
	unequipPet = function(state, action)
		local petEquipCount = state[action.playerName].EquippedPets[action.petName] or 0
		local newEquippedPets = Sift.Dictionary.mergeDeep(state[action.playerName].EquippedPets, {
			[action.petName] = if petEquipCount > 1 then petEquipCount - 1 else Sift.None,
		})
		if not newEquippedPets[action.petName] then
			newEquippedPets[action.petName] = Sift.None
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				EquippedPets = newEquippedPets,
				PetFearMultiplier = state[action.playerName].PetFearMultiplier
					- ReplicatedStorage.Pets:FindFirstChild(action.petName, true).Multiplier.Value,
				CurrentPetEquipCount = state[action.playerName].CurrentPetEquipCount - 1,
			},
		})
	end,
	lockPet = function(state, action)
		local petLockCount = state[action.playerName].LockedPets[action.petName] or 0
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = Sift.Dictionary.mergeDeep(state[action.playerName].LockedPets, {
					[action.petName] = petLockCount + 1,
				}),
			},
		})
	end,
	unlockPet = function(state, action)
		local petLockCount = state[action.playerName].LockedPets[action.petName] or 0
		local newLockedPets = Sift.Dictionary.mergeDeep(state[action.playerName].LockedPets, {
			[action.petName] = if petLockCount > 1 then petLockCount - 1 else Sift.None,
		})
		if not newLockedPets[action.petName] then
			newLockedPets[action.petName] = Sift.None
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = newLockedPets,
			},
		})
	end,
	deletePet = function(state, action)
		local petOwnedCount = state[action.playerName].OwnedPets[action.petName] or 0
		local newOwnedPets = Sift.Dictionary.mergeDeep(state[action.playerName].OwnedPets, {
			[action.petName] = if petOwnedCount > 1 then petOwnedCount - 1 else Sift.None,
		})
		if not newOwnedPets[action.petName] then
			newOwnedPets[action.petName] = Sift.None
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = newOwnedPets,
				CurrentPetCount = state[action.playerName].CurrentPetCount - 1,
			},
		})
	end,
})
