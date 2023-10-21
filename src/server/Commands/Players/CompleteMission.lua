return {
	Name = "completemission",
	Aliases = { "cm" },
	Description = "Completes the current mission of the player for the region they're in.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose mission you want to complete.",
		},
	},
}
