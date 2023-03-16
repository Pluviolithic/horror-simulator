local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

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
			if not petName:match "Evolved" then
				newFoundPets[petName] = true
			end
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
					+ (petUtils.getPet(action.petName) :: any).Multiplier.Value,
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
					- (petUtils.getPet(action.petName) :: any).Multiplier.Value,
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
			[action.petName] = if petLockCount > action.quantity then petLockCount - action.quantity else Sift.None,
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
			[action.petName] = if petOwnedCount > action.quantity then petOwnedCount - action.quantity else Sift.None,
		})
		if not newOwnedPets[action.petName] then
			newOwnedPets[action.petName] = Sift.None
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = newOwnedPets,
				CurrentPetCount = state[action.playerName].CurrentPetCount - math.min(petOwnedCount, action.quantity),
			},
		})
	end,
	increaseMaxPetEquipCount = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				MaxPetEquipCount = state[action.playerName].MaxPetEquipCount + action.amount,
			},
		})
	end,
	unequipAllPets = function(state, action)
		local newLockedPets = table.clone(state[action.playerName].LockedPets)
		local newEquippedPets = {}
		for petName, petEquipCount in state[action.playerName].EquippedPets do
			newEquippedPets[petName] = Sift.None
			newLockedPets[petName] -= petEquipCount
			if newLockedPets[petName] <= 0 then
				newLockedPets[petName] = Sift.None
			end
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = newLockedPets,
				EquippedPets = newEquippedPets,
				PetFearMultiplier = 0,
				CurrentPetEquipCount = 0,
			},
		})
	end,
	equipPets = function(state, action)
		local newLockedPets = table.clone(state[action.playerName].LockedPets)
		local newEquippedPets = table.clone(state[action.playerName].EquippedPets)
		local newPetFearMultiplier = state[action.playerName].PetFearMultiplier

		for _, petName in action.petNames do
			newLockedPets[petName] = (newLockedPets[petName] or 0) + 1
			newEquippedPets[petName] = (newEquippedPets[petName] or 0) + 1
			newPetFearMultiplier += (petUtils.getPet(petName) :: any).Multiplier.Value
		end

		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = newLockedPets,
				EquippedPets = newEquippedPets,
				PetFearMultiplier = newPetFearMultiplier,
				CurrentPetEquipCount = state[action.playerName].CurrentPetEquipCount + #action.petNames,
			},
		})
	end,
	evolvePet = function(state, action)
		local quantityDifference = state[action.playerName].OwnedPets[action.petName]
			- state[action.playerName].LockedPets[action.petName]
		local newLockedPets = table.clone(state[action.playerName].LockedPets)
		local newOwnedPets = table.clone(state[action.playerName].OwnedPets)
		local newEquippedPets = {}
		local newPetCount = 0

		if quantityDifference < 5 then
			newLockedPets[action.petName] -= quantityDifference
			if newLockedPets[action.petName] <= 0 then
				newLockedPets[action.petName] = Sift.None
			end
		end

		newOwnedPets[action.petName] -= 5
		if newOwnedPets[action.petName] <= 0 then
			newOwnedPets[action.petName] = Sift.None
		end

		newOwnedPets["Evolved " .. action.petName] = (newOwnedPets["Evolved " .. action.petName] or 0) + 1

		for _, petCount in state[action.playerName].OwnedPets do
			newPetCount += petCount
		end

		if state[action.playerName].EquippedPets[action.petName] then
			newEquippedPets[action.petName] = newEquippedPets[action.petName] - 1
			if newEquippedPets[action.petName] <= 0 then
				newEquippedPets[action.petName] = Sift.None
			end
		end

		return Sift.Dictionary.mergeDeep(state, {
			LockedPets = newLockedPets,
			OwnedPets = newOwnedPets,
			EquippedPets = newEquippedPets,
			CurrentPetCount = newPetCount,
		})
	end,
	evolveAllPets = function(state, action)
		local newLockedPets = table.clone(state[action.playerName].LockedPets)
		local newOwnedPets = table.clone(state[action.playerName].OwnedPets)
		local newEquippedPets = table.clone(state[action.playerName].EquippedPets)
		local newPetCount = 0

		for petName, petCount in state[action.playerName].OwnedPets do
			if petName:match "Evolved" then
				continue
			end

			for _ = 1, math.floor(petCount / 5) do
				local quantityDifference = petCount - (newLockedPets[petName] or 0)
				if quantityDifference < 5 then
					newLockedPets[petName] -= quantityDifference
					if newLockedPets[petName] <= 0 then
						newLockedPets[petName] = Sift.None
					end
				end

				newOwnedPets[petName] -= 5
				if newOwnedPets[petName] <= 0 then
					newOwnedPets[petName] = Sift.None
				end

				newOwnedPets["Evolved " .. petName] = (newOwnedPets["Evolved " .. petName] or 0) + 1
			end
		end

		for _, petCount in newOwnedPets do
			if petCount == Sift.None then
				continue
			end
			newPetCount += petCount
		end

		for petName, quantity in state[action.playerName].EquippedPets do
			newEquippedPets[petName] -= quantity - (newOwnedPets[petName] or 0)
			if newEquippedPets[petName] <= 0 then
				newEquippedPets[petName] = Sift.None
			end
		end

		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				LockedPets = newLockedPets,
				OwnedPets = newOwnedPets,
				EquippedPets = newEquippedPets,
				CurrentPetCount = newPetCount,
			},
		})
	end,
	deleteAllPets = function(state, action)
		local newOwnedPets = table.clone(state[action.playerName].OwnedPets)
		local newPetCount = 0
		for petName, petCount in pairs(state[action.playerName].OwnedPets) do
			newOwnedPets[petName] -= petCount - (state[action.playerName].LockedPets[petName] or 0)
		end
		for _, petCount in newOwnedPets do
			newPetCount += petCount
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = newOwnedPets,
				CurrentPetCount = newPetCount,
			},
		})
	end,
	givePlayerTeleporter = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				PurchasedTeleporters = { action.areaName },
			},
		})
	end,
})
