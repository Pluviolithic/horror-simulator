return {
	Name = "incrementstat",
	Aliases = { "is" },
	Description = "Increments the stat of a player.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose stat you want to increment.",
		},
		{
			Type = "string",
			Name = "Stat",
			Description = "The stat you want to increment.",
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "The amount to add to the stat.",
		},
	},
}
