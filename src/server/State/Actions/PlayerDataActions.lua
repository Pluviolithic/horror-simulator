local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	addPlayer = makeActionCreator("addPlayer", function(playerName: string, profileData: any)
		return {
			playerName = playerName,
			profileData = profileData,
		}
	end),
	removePlayer = makeActionCreator("removePlayer", function(playerName: string)
		return {
			playerName = playerName,
		}
	end),
	incrementPlayerStat = makeActionCreator(
		"incrementPlayerStat",
		function(
			playerName: string,
			statName: string,
			incrementAmount: number,
			source: string?,
			skipMultipliers: boolean?
		)
			return {
				incrementAmount = incrementAmount,
				playerName = playerName,
				statName = statName,
				source = source,
				skipMultipliers = skipMultipliers,
				shouldSave = true,
			}
		end
	),
	setPlayerStat = makeActionCreator("setPlayerStat", function(playerName: string, statName: string, value: number)
		return {
			value = value,
			playerName = playerName,
			statName = statName,
			shouldSave = true,
		}
	end),
	resetPlayerData = makeActionCreator("resetPlayerData", function(playerName: string)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
	rebirthPlayer = makeActionCreator("rebirthPlayer", function(playerName: string)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
}
