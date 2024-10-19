local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)
local t = require(ReplicatedStorage.Common.lib.t)

local Remotes = Net.CreateDefinitions {
	HatchEggs = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.number, t.string),
	},
	EquipWeapon = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	UnequipWeapon = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
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
	DisableMissionRewardPopup = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	SwitchSetting = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	UseBoost = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	RedeemCode = Net.Definitions.ServerFunction {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	IncrementTutorialStep = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
	},
	SetTutorialFearMeterPercent = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.number),
	},
	SetComboMeterLevel = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 120,
		},
		Net.Middleware.TypeChecking(t.number),
	},
	AchievedMilestone = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	ClaimGift = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 60,
		},
		Net.Middleware.TypeChecking(t.string),
	},
	Rebirth = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 120,
		},
	},
	PurchaseRebirthUpgrade = Net.Definitions.ClientToServerEvent {
		Net.Middleware.RateLimit {
			MaxRequestsPerMinute = 120,
		},
		Net.Middleware.TypeChecking(t.string),
	},

	CombatBegan = Net.Definitions.ServerToClientEvent(),
	JumpscarePlayer = Net.Definitions.ServerToClientEvent(),
	DropGems = Net.Definitions.ServerToClientEvent(),
	SpawnRewardPart = Net.Definitions.ServerToClientEvent(),
	SendPopupMessage = Net.Definitions.ServerToClientEvent(),
	SendFightInfo = Net.Definitions.ServerToClientEvent(),
	OpenRobuxShopOnClient = Net.Definitions.ServerToClientEvent(),
	LegendaryUnboxed = Net.Definitions.ServerToClientEvent(),
	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	SetControlsEnabled = Net.Definitions.ServerToClientEvent(),
	NotifyOfShutdown = Net.Definitions.ServerToClientEvent(),
}

return Remotes
