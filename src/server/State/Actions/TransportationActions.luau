local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	givePlayerTeleporter = makeActionCreator("givePlayerTeleporter", function(playerName: string, areaName: string)
		return {
			playerName = playerName,
			areaName = areaName,
			shouldSave = true,
		}
	end),
}
