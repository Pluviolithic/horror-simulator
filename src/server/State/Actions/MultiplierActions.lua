local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	incrementPlayerMultiplier = makeActionCreator(
		"incrementPlayerMultiplier",
		function(playerName: string, multiplierName: string, incrementAmount: number)
			return {
				playerName = playerName,
				multiplierName = multiplierName,
				incrementAmount = incrementAmount,
				shouldSave = true,
			}
		end
	),
	setPlayerMultiplier = makeActionCreator(
		"setPlayerMultiplier",
		function(playerName: string, multiplierName: string, value: number)
			return {
				playerName = playerName,
				multiplierName = multiplierName,
				value = value,
				shouldSave = true,
			}
		end
	),
	addFriend = makeActionCreator("addFriend", function(playerName: string, friendName: string)
		return {
			playerName = playerName,
			friendName = friendName,
		}
	end),
	removeFriend = makeActionCreator("removeFriend", function(playerName: string, friendName: string)
		return {
			playerName = playerName,
			friendName = friendName,
		}
	end),
}
