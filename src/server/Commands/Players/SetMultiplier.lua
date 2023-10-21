return {
	Name = "setmultiplier",
	Aliases = { "sm" },
	Description = "Sets the multiplier for a stat of a player.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose multiplier you want to set.",
		},
		{
			Type = "string",
			Name = "Stat",
			Description = "The stat for which you want to set the multiplier.",
		},
		{
			Type = "number",
			Name = "Value",
			Description = "The value to set the multiplier to.",
		},
	},
}
