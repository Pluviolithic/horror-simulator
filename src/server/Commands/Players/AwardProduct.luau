return {
	Name = "awardproduct",
	Aliases = { "ap" },
	Description = "Simulates a product purchase",
	Group = "DefaultAdmin",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player who you want to award the product to.",
		},
		{
			Type = "number",
			Name = "ID",
			Description = "The product ID.",
		},
	},
}
