local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Net = require(ReplicatedStorage.Common.lib.Net)

local Remotes = Net.CreateDefinitions {
	SendRoduxAction = Net.Definitions.ServerToClientEvent(),
	GetGlobalState = Net.Definitions.ServerFunction(),
	GetAreaCameraLocation = Net.Definitions.ServerFunction(),
	GetCabinAreaInfo = Net.Definitions.ServerFunction(),
}

return Remotes
