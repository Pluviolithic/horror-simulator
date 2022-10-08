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
	incrementPlayerLogInCount = makeActionCreator("incrementPlayerLogInCount", function(playerName)
		return {
			playerName = playerName,
		}
	end),
}
