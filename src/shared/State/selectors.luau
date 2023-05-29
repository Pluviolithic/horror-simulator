return {
	isPlayerLoaded = function(state, playerName)
		return state.Stats[playerName]
			and state.PurchaseData[playerName]
			and state.CombatData[playerName]
			and state.WeaponData[playerName]
			and state.PetData[playerName]
	end,
	getStat = function(state, playerName, statName)
		return state.Stats[playerName][statName]
	end,
	hasGamepass = function(state, playerName, gamepassID)
		return state.PurchaseData[playerName].AwardedGamepasses[gamepassID]
	end,
	hasTeleporter = function(state, playerName, areaName)
		return state.PurchaseData[playerName].PurchasedTeleporters[areaName]
	end,
	getCurrentTarget = function(state, playerName)
		return state.CombatData[playerName].CurrentEnemy or state.CombatData[playerName].CurrentPunchingBag
	end,
	getEquippedPets = function(state, playerName)
		return state.PetData[playerName].EquippedPets
	end,
	getLockedPets = function(state, playerName)
		return state.PetData[playerName].LockedPets
	end,
	getOwnedPets = function(state, playerName)
		return state.PetData[playerName].OwnedPets
	end,
	getFoundPets = function(state, playerName)
		return state.PetData[playerName].FoundPets
	end,
	getEquippedWeapon = function(state, playerName)
		return state.WeaponData[playerName].EquippedWeapon
	end,
	getOwnedWeapons = function(state, playerName)
		return state.WeaponData[playerName].OwnedWeapons
	end,
}
