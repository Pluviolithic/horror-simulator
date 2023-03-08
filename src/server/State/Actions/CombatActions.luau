local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	switchPlayerEnemy = makeActionCreator("switchPlayerEnemy", function(playerName: string, enemy: Model)
		return {
			enemy = enemy,
			playerName = playerName,
		}
	end),
	setCurrentPunchingBag = makeActionCreator("setCurrentPunchingBag", function(playerName: string, bag: Model)
		return {
			playerName = playerName,
			currentPunchingBag = bag,
		}
	end),
}
