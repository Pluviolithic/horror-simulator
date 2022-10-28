local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	addPlayer = makeActionCreator("addPlayer", function(playerName)
		return {
			playerName = playerName,
		}
	end),
	removePlayer = makeActionCreator("removePlayer", function(playerName)
		return {
			playerName = playerName,
		}
	end),
	updatePlayerWithProfile = makeActionCreator("updatePlayerWithProfile", function(playerName, profileData)
		return {
			playerName = playerName,
			profileData = profileData,
		}
	end),
	incrementPlayerStat = makeActionCreator("incrementPlayerStat", function(playerName, statName, incrementAmount)
		return {
			incrementAmount = incrementAmount,
			playerName = playerName,
			statName = statName,
		}
	end),
	switchPlayerEnemy = makeActionCreator("switchPlayerEnemy", function(playerName, enemy)
		return {
			enemy = enemy,
			playerName = playerName,
		}
	end),
	resetPlayerData = makeActionCreator("resetPlayerData", function(playerName)
		return {
			playerName = playerName,
		}
	end),
	setCurrentPunchingBag = makeActionCreator("setCurrentPunchingBag", function(playerName, bag)
		return {
			playerName = playerName,
			currentPunchingBag = bag,
		}
	end),
}
