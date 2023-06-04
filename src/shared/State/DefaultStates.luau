-- some elements are unnecessary to list explicitly
-- the reducers generate them
-- I just leave them so I have an idea of the game state
return {
	Stats = {
		Strength = 1,
		Fear = 0,
		Kills = 0,
		Rebirths = 0,

		Luck = 0,
		Gems = 0,
		Rank = 1,

		LogInCount = 0,
		HoursPlayed = 0,

		MaxPetCount = 30,
		CurrentPetCount = 0,
		MaxPetEquipCount = 3,
		PetFearMultiplier = 0,
		CurrentPetEquipCount = 0,
	},

	PetData = {
		FoundPets = {},
		OwnedPets = {},
		LockedPets = {},
		EquippedPets = {},
	},

	WeaponData = {
		OwnedWeapons = {
			["Fists"] = true,
		},
		EquippedWeapon = "Fists",
	},

	CombatData = {
		CurrentEnemy = nil,
		CurrentPunchingBag = nil,
	},

	PurchaseData = {
		AwardedGamepasses = {},
		PurchasedTeleporters = {},
	},
}
