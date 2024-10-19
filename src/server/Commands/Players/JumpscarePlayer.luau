return {
	Name = "jumpscare",
	Aliases = { "j" },
	Description = "Jumpscares player",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player who you want to give the pet to.",
		},
		{
			Type = "string",
			Name = "Name",
			Description = "The enemy to jumpscare them with.",
		},
	},
}
