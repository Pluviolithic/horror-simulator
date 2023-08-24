return {
	Stats = {
		Fear = 0,
		Kills = 0,
		Rebirths = 0,
		Strength = 1,

		Luck = 0,
		Gems = 0,
		Rank = 1,

		WalkSpeed = 14,
		RequiredFear = 5,
		MaxFearMeter = 100,
		CurrentFearMeter = 0,
		LastScaredTimestamp = -1,

		LogInCount = 0,
		HoursPlayed = 0,

		MaxPetCount = 30,
		CurrentPetCount = 0,
		MaxPetEquipCount = 3,
		PetFearMultiplier = 0,
		CurrentPetEquipCount = 0,
	},

	PurchaseData = {
		AwardedGamepasses = {},
		PurchasedTeleporters = {},
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
}
