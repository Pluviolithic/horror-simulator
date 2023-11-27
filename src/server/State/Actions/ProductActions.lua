local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	incrementPlayerBoostCount = makeActionCreator(
		"incrementPlayerBoostCount",
		function(playerName: string, boostName: string, incrementAmount: number)
			return {
				playerName = playerName,
				boostName = boostName,
				incrementAmount = incrementAmount,
				shouldSave = true,
			}
		end
	),
	applyBoostToPlayer = makeActionCreator("applyBoostToPlayer", function(playerName: string, boostName: string)
		return {
			playerName = playerName,
			boostName = boostName,
			shouldSave = true,
		}
	end),
	removeBoostFromPlayer = makeActionCreator("removeBoostFromPlayer", function(playerName: string, boostName: string)
		return {
			playerName = playerName,
			boostName = boostName,
			shouldSave = true,
		}
	end),
}
