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
	redeemCode = makeActionCreator("redeemCode", function(playerName: string, code: string)
		return {
			playerName = playerName,
			code = code,
			shouldSave = true,
		}
	end),
	incrementRebirthUpgradeLevel = makeActionCreator(
		"incrementRebirthUpgradeLevel",
		function(playerName: string, upgradeName: string, incrementAmount: number)
			return {
				playerName = playerName,
				upgradeName = upgradeName,
				incrementAmount = incrementAmount or 1,
				shouldSave = true,
			}
		end
	),
}
