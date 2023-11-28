local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	startChestTimer = makeActionCreator("startChestTimer", function(playerName: string, chestName: string)
		return {
			playerName = playerName,
			chestName = chestName,
			shouldSave = true,
		}
	end),
}
