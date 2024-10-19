return {
	Name = "changemultiplier",
	Aliases = { "cm" },
	Description = "Sets the multiplier for a stat of a player.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose multiplier you want to change.",
		},
		{
			Type = "string",
			Name = "Stat",
			Description = "The stat for which you want to change the multiplier.",
		},
		{
			Type = "number",
			Name = "Value",
			Description = "The value to change the multiplier to.",
		},
	},
}
