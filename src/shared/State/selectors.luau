local ReplicatedStorage = game:GetService "ReplicatedStorage"

local GamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

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
	hasGamepass = function(state, playerName, gamepass)
		if not state.PurchaseData[playerName] then
			return false
		elseif GamepassIDs:FindFirstChild(gamepass) then
			return state.PurchaseData[playerName].AwardedGamepasses[tostring(GamepassIDs[gamepass].Value)]
		end
		return state.PurchaseData[playerName].AwardedGamepasses[tostring(gamepass)]
	end,
	hasTeleporter = function(state, playerName, areaName)
		return state.PurchaseData[playerName].PurchasedTeleporters[areaName]
	end,
	getPetOwnedCount = function(state, playerName, petName)
		return state.PetData[playerName].OwnedPets[petName]
	end,
	getPetEquippedCount = function(state, playerName, petName)
		return state.PetData[playerName].EquippedPets[petName]
	end,
	getPetLockedCount = function(state, playerName, petName)
		return state.PetData[playerName].LockedPets[petName]
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
	getStats = function(state, playerName)
		return state.Stats[playerName]
	end,
	getPurchaseData = function(state, playerName)
		return state.PurchaseData[playerName]
	end,
	getPurchasedTeleporters = function(state, playerName)
		return state.PurchaseData[playerName].PurchasedTeleporters
	end,
	getPetData = function(state, playerName)
		return state.PetData[playerName]
	end,
	getWeaponData = function(state, playerName)
		return state.WeaponData[playerName]
	end,
	getMissionData = function(state, playerName)
		return state.MissionData[playerName]
	end,
	getMultiplierData = function(state, playerName)
		return state.MultiplierData[playerName]
	end,
	getAudioData = function(state, playerName)
		return state.AudioData[playerName]
	end,
	getTempSettings = function(state, playerName)
		return state.TempSettings[playerName]
	end,
	getSavedSettings = function(state, playerName)
		return state.SavedSettings[playerName]
	end,
	getSetting = function(state, playerName, setting)
		return if type(state.SavedSettings[playerName][setting]) == "boolean"
			then state.SavedSettings[playerName][setting]
			else state.TempSettings[playerName][setting]
	end,
	getPurchasedBoosts = function(state, playerName)
		return state.PurchaseData[playerName].PurchasedBoosts
	end,
	getActiveBoosts = function(state, playerName)
		return state.PurchaseData[playerName].ActiveBoosts
	end,
	getBoostCount = function(state, playerName, boostName)
		return state.PurchaseData[playerName].PurchasedBoosts[boostName] or 0
	end,
	getChestTimers = function(state, playerName)
		return state.ChestTimers[playerName]
	end,
	hasRedeemedCode = function(state, playerName, code)
		return state.PurchaseData[playerName].RedeemedCodes[code]
	end,
	getTutorialData = function(state, playerName)
		return state.TutorialData[playerName]
	end,
	getTutorialStep = function(state, playerName)
		return state.TutorialData[playerName].CurrentStep
	end,
	achievedMilestone = function(state, playerName, milestone)
		return state.MilestonesData[playerName][milestone]
	end,
	getMilestonesData = function(state, playerName)
		return state.MilestonesData[playerName]
	end,
	getActiveFriendsWhoJoined = function(state, playerName)
		return state.MultiplierData[playerName].ActiveFriendsWhoJoined
	end,
	getGiftData = function(state, playerName)
		return state.GiftData[playerName]
	end,
	hasClaimedGift = function(state, playerName, giftName)
		return state.GiftData[playerName].ClaimedGifts[giftName]
	end,
	skippedGiftTimers = function(state, playerName)
		return state.GiftData[playerName].SkippedAll
	end,
	getClaimedGifts = function(state, playerName)
		return state.GiftData[playerName].ClaimedGifts
	end,
	getRebirthUpgradeLevel = function(state, playerName, upgradeName)
		return state.PurchaseData[playerName].RebirthUpgrades[upgradeName]
	end,
}
