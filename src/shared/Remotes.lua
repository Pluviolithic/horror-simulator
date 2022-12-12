local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)

local Remotes = Net.CreateDefinitions {
	EquipWeapon = Net.Definitions.ServerFunction(),
	GetGlobalState = Net.Definitions.ServerFunction(),
	PurchaseWeapon = Net.Definitions.ServerFunction(),
	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	SendNPCHealthBar = Net.Definitions.ServerToClientEvent(),
	SetControlsEnabled = Net.Definitions.ServerToClientEvent(),
}

return Remotes
