-- some elements are unnecessary to list explicitly
-- the reducers generate them
-- I just leave them so I have an idea of the game state
return {
	PlayerState = {
		Strength = 0,
		Fear = 0,
		Kills = 0,
		Rebirths = 0,

		LogInCount = 0,
		HoursPlayed = 0,
		CurrentEnemy = nil,
	},

	ClientState = {},

	GameState = {
		Players = {},
	},
}
