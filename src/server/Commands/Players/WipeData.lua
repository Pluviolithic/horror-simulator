return {
	Name = "wipedata",
	Aliases = { "wd" },
	Description = "Wipes the data of a player.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose cash you want to set",
		},
	},
}
