return {
	Name = "givepet",
	Aliases = { "gp" },
	Description = "Gives a pet",
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
			Description = "The pet name.",
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "How many of that pet to give.",
		},
	},
}
