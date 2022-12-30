local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)
local t = require(ReplicatedStorage.Common.lib.t)

local Remotes = Net.CreateDefinitions {
	HatchEggs = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 20,
		},
		Net.Middleware.TypeChecking(t.number, t.boolean, t.string),
	},
	EquipWeapon = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	GetGlobalState = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	PurchaseWeapon = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},

	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	SendNPCHealthBar = Net.Definitions.ServerToClientEvent(),
	SetControlsEnabled = Net.Definitions.ServerToClientEvent(),
	AutoHatchResponses = Net.Definitions.ServerToClientEvent(),
}

return Remotes
