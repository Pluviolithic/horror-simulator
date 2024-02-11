return {
	Stats = {
		Fear = 0,
		Kills = 0,
		Rebirths = 0,
		Strength = game:GetService("ReplicatedStorage").Config.Workout.Strength.Value,

		Luck = 0,
		Gems = 0,
		Rank = 1,
		RebirthTokens = 0,
		MissionAreasCompleted = 0,

		RequiredFear = game:GetService("ReplicatedStorage").Config.Workout.RequiredFear.Value
			* game:GetService("ReplicatedStorage").Config.Workout.Strength.Value,
		MaxFearMeter = 100,
		CurrentFearMeter = 0,
		LastScaredTimestamp = -1,

		LogInCount = 0,
		TimePlayed = 0,

		LastLogOn = -1,
		LastLogOff = -1,

		LastClaimedAGiftTimestamp = -1,
		GiftCycleBeganTimestamp = -1,

		VIPChestAwardIndex = 1,
		GroupChestAwardIndex = 1,

		MaxPetCount = 30,
		CurrentPetCount = 0,
		MaxPetEquipCount = 3,
		CurrentPetEquipCount = 0,
	},

	MultiplierData = {
		FearMultiplier = 0,
		StrengthMultiplier = 0,
		GemsMultiplier = 0,
	},

	PurchaseData = {
		AwardedGamepasses = {},
		PurchasedTeleporters = {},
		PurchasedBoosts = {},
		ActiveBoosts = {},
		RedeemedCodes = {},
		RebirthUpgrades = {
			EquipMorePets = 0,
			Evolver = 0,
			ExtraPetStorage = 0,
			FasterHatch = 0,
			Lucky = 0,
			MoreDamage = 0,
			MoreFear = 0,
			MoreGems = 0,
			MoreStrength = 0,
			Sprint = 0,
			WorkoutSpeed = 0,
			KeepLegendaries = 0,
		},
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

	MissionData = {
		["Clown Town"] = {
			CurrentMissionNumber = 1,
			CurrentMissionProgress = 0,
			Active = false,
			ViewedRewardPopup = false,
		},
		["Spider Cave"] = {
			CurrentMissionNumber = 1,
			CurrentMissionProgress = 0,
			Active = false,
			ViewedRewardPopup = false,
		},
		["Howling Woods"] = {
			CurrentMissionNumber = 1,
			CurrentMissionProgress = 0,
			Active = false,
			ViewedRewardPopup = false,
		},
		["Zombie City"] = {
			CurrentMissionNumber = 1,
			CurrentMissionProgress = 0,
			Active = false,
			ViewedRewardPopup = false,
		},
		["Ghostly Manor"] = {
			CurrentMissionNumber = 1,
			CurrentMissionProgress = 0,
			Active = false,
			ViewedRewardPopup = false,
		},
	},

	SavedSettings = {
		Tips = true,
		VipChatTag = false,
		VipNameTag = false,
		JumpscareCooldown = true,
	},

	ChestTimers = {
		VIPChest = -1,
		GroupChest = -1,
	},

	TutorialData = {
		CurrentStep = 1,
	},

	MilestonesData = {
		["100MStrength"] = false,
	},

	GiftData = {
		ClaimedGifts = {},
		SkippedAll = false,
	},
}
