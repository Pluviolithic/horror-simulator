local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)
local t = require(ReplicatedStorage.Common.lib.t)

local Remotes = Net.CreateDefinitions {
	HatchEggs = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 20,
		},
		Net.Middleware.TypeChecking(t.number, t.string),
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
	EquipPet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string, t.boolean),
	},
	UnequipPet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	LockPet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	UnlockPet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	DeletePet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	EvolvePet = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	EquipBestPets = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	EvolveAllPets = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	DeleteAllPets = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	UnequipAllPets = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	PurchaseTeleporter = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	StartMission = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	CompleteMission = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},

	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	--SendNPCHealthBar = Net.Definitions.ServerToClientEvent(),
	SetControlsEnabled = Net.Definitions.ServerToClientEvent(),
}

return Remotes
