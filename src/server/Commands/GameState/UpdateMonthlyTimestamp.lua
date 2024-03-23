return {
	Name = "updatemonthlytimestamp",
	Aliases = { "umt" },
	Description = "Updates the monthly timestamp prefix to a value of your choice.",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "string",
			Name = "Timestamp",
			Description = "The string you want to set as the monthly timestamp prefix.",
		},
	},
}
