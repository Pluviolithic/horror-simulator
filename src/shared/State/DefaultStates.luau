-- some elements are unnecessary to list explicitly
-- the reducers generate them
-- I just leave them so I have an idea of the game state
return {
	PlayerState = {
		Strength = 1,
		Fear = 0,
		Kills = 0,
		Rebirths = 0,

		Luck = 0,
		Gems = 0,
		Rank = 1,

		PetFearMultiplier = 0,

		CurrentPetCount = 0,
		MaxPetCount = 30,

		CurrentPetEquipCount = 0,
		MaxPetEquipCount = 3,

		AwardedGamepasses = {},
		PurchasedTeleporters = {},

		FoundPets = {},
		OwnedPets = {},
		LockedPets = {},
		EquippedPets = {},
		OwnedWeapons = {
			["Fists"] = true,
		},
		EquippedWeapon = "Fists",

		LogInCount = 0,
		HoursPlayed = 0,

		CurrentEnemy = nil,
		CurrentPunchingBag = nil,
	},

	ClientState = {},

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

		PetCount = 0,
		PetEquipCount = 0,

		PetFearMultiplier = 0,
		MaxPetCount = 30,
		MaxPetEquipCount = 3,
	},

	PetData = {
		--[[
				[playerName] = {
					FoundPets = {},
					OwnedPets = {},
					LockedPets = {},
					EquippedPets = {},
				}
			]]
	},
	WeaponData = {
		--[[
				[playerName] = {
					OwnedWeapons = {
						["Fists"] = true,
					},
					EquippedWeapon = "Fists",
				}
			]]
	},
	CombatData = {
		--[[
				[playerName] = {
					CurrentEnemy = nil,
					CurrentPunchingBag = nil,
				}
			]]
	},
	PurchaseData = {
		--[[
				[playerName] = {
					AwardedGamepasses = {},
					PurchasedTeleporters = {},
				}
			]]
	},
}
