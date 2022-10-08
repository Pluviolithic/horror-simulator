-- some elements are unnecessary to list explicitly
-- the reducers generate them
-- I just leave them so I have an idea of the game state
return {
	PlayerState = {
		Cash = 0,
		LogInCount = 0,
		HoursPlayed = 0,
	},

	ClientState = {},

	GameState = {
		Players = {},
	},
}
