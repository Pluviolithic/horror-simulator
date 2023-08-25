return {
	Stats = {
		Fear = 0,
		Kills = 0,
		Rebirths = 0,
		Strength = game:GetService("ReplicatedStorage").Config.Workout.Strength.Value,

		Luck = 0,
		Gems = 0,
		Rank = 1,

		WalkSpeed = 14,
		RequiredFear = game:GetService("ReplicatedStorage").Config.Workout.RequiredFear.Value,
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
