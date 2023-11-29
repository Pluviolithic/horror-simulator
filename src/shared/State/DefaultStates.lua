return {
	Stats = {
		Fear = 0,
		Kills = 0,
		Rebirths = 0,
		Strength = game:GetService("ReplicatedStorage").Config.Workout.Strength.Value,

		Luck = 0,
		Gems = 0,
		Rank = 1,

		RequiredFear = game:GetService("ReplicatedStorage").Config.Workout.RequiredFear.Value
			* game:GetService("ReplicatedStorage").Config.Workout.Strength.Value,
		MaxFearMeter = 100,
		CurrentFearMeter = 0,
		LastScaredTimestamp = -1,

		LogInCount = 0,
		HoursPlayed = 0,

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
		PurchasedBoosts = {},
		ActiveBoosts = {},
		RedeemedCodes = {},
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
	},

	AudioData = {
		PrimarySoundRegion = nil,
		OccupiedSoundRegions = {},
		BackgroundTracks = {},
	},

	SavedSettings = {
		VipChatTag = false,
		VipNameTag = false,
		JumpscareCooldown = true,
	},

	TempSettings = {
		BackgroundMusic = true,
		["2xSpeed"] = true,
		BrightMode = false,
		ShowMyPets = true,
		ShowOtherPets = true,
		Jumpscares = true,
	},

	ChestTimers = {
		VIPChest = -1,
		GroupChest = -1,
	},
}
