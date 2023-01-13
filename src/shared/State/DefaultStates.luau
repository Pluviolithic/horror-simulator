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

		CurrentPetCount = 0,
		MaxPetCount = 30,

		AwardedGamepasses = {},
		FoundPets = {},
		OwnedPets = {},
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

	GameState = {
		Players = {},
	},
}
