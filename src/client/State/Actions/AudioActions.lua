local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	addOccupiedSoundRegion = makeActionCreator(
		"addOccupiedSoundRegion",
		function(playerName: string, occupiedSoundRegion)
			return {
				occupiedSoundRegion = occupiedSoundRegion,
				playerName = playerName,
			}
		end
	),
	removeOccupiedSoundRegion = makeActionCreator(
		"removeOccupiedSoundRegion",
		function(playerName: string, deoccupiedSoundRegion)
			return {
				deoccupiedSoundRegion = deoccupiedSoundRegion,
				playerName = playerName,
			}
		end
	),
	setPrimarySoundRegion = makeActionCreator("setPrimarySoundRegion", function(playerName: string, primarySoundRegion)
		return {
			primarySoundRegion = primarySoundRegion,
			playerName = playerName,
		}
	end),
}
