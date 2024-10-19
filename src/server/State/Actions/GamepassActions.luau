local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	awardGamepassToPlayer = makeActionCreator("awardGamepassToPlayer", function(playerName: string, gamepassID: number)
		return {
			playerName = playerName,
			gamepassID = gamepassID,
			shouldSave = true,
		}
	end),
}
