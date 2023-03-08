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
	increaseMaxPetCount = makeActionCreator("increaseMaxPetCount", function(playerName: string, amount: number)
		return {
			playerName = playerName,
			amount = amount,
			shouldSave = true,
		}
	end),
	increasePlayerLuck = makeActionCreator("increasePlayerLuck", function(playerName: string, amount: number)
		return {
			playerName = playerName,
			amount = amount,
			shouldSave = true,
		}
	end),
}
