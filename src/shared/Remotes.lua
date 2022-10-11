local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)

local Remotes = Net.CreateDefinitions {
	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	GetGlobalState = Net.Definitions.ServerFunction(),
	SendNPCHealthBar = Net.Definitions.ServerToClientEvent(),
}

return Remotes
