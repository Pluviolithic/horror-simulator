local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)

local Remotes = Net.CreateDefinitions {
	GetGlobalState = Net.Definitions.ServerFunction(),
	CancelExchange = Net.Definitions.ClientToServerEvent(),
	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	SendNPCHealthBar = Net.Definitions.ServerToClientEvent(),
	SetControlsEnabled = Net.Definitions.ServerToClientEvent(),
}

return Remotes
