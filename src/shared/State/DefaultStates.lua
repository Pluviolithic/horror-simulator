-- some elements are unnecessary to list explicitly
-- the reducers generate them
-- I just leave them so I have an idea of the game state
return {
	PlayerState = {
		Strength = 0,
		Fear = 0,
		Kills = 0,
		Rebirths = 0,

		RequiredFear = 5,
		EquippedTool = "Fists",

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
