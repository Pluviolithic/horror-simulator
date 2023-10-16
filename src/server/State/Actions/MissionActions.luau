local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	startMission = makeActionCreator("startMission", function(playerName: string, areaName: string)
		return {
			areaName = areaName,
			playerName = playerName,
			shouldSave = true,
		}
	end),
	completeMission = makeActionCreator(
		"completeMission",
		function(playerName: string, areaName: string, gemReward: number)
			return {
				areaName = areaName,
				playerName = playerName,
				gemReward = gemReward,
				shouldSave = true,
			}
		end
	),
	logKilledEnemyType = makeActionCreator("logKilledEnemyType", function(playerName: string, enemyType: string)
		return {
			enemyType = enemyType,
			playerName = playerName,
			shouldSave = true,
		}
	end),
	logPurchasedWeaponType = makeActionCreator(
		"logPurchasedWeaponType",
		function(playerName: string, weaponType: string)
			return {
				weaponType = weaponType,
				playerName = playerName,
				shouldSave = true,
			}
		end
	),
	logHatchedPetRarities = makeActionCreator(
		"logHatchedPetRarities",
		function(playerName: string, petRarities: { string })
			return {
				petRarities = petRarities,
				playerName = playerName,
				shouldSave = true,
			}
		end
	),
}
