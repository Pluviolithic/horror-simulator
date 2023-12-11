local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	incrementTutorialStep = makeActionCreator("incrementTutorialStep", function(playerName)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
}
