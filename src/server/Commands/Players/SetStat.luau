return {
	Name = "setstat",
	Aliases = { "ss" },
	Description = "Sets the stat of a player.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose stat you want to set.",
		},
		{
			Type = "string",
			Name = "Stat",
			Description = "The stat you want to set.",
		},
		{
			Type = "number",
			Name = "Value",
			Description = "The value to set the stat to.",
		},
	},
}
