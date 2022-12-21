local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	addPlayer = makeActionCreator("addPlayer", function(playerName: string)
		return {
			playerName = playerName,
		}
	end),
	removePlayer = makeActionCreator("removePlayer", function(playerName: string)
		return {
			playerName = playerName,
		}
	end),
	updatePlayerWithProfile = makeActionCreator(
		"updatePlayerWithProfile",
		function(playerName: string, profileData: any)
			return {
				playerName = playerName,
				profileData = profileData,
			}
		end
	),
	incrementPlayerStat = makeActionCreator(
		"incrementPlayerStat",
		function(playerName: string, statName: string, incrementAmount: number)
			return {
				incrementAmount = incrementAmount,
				playerName = playerName,
				statName = statName,
			}
		end
	),
	switchPlayerEnemy = makeActionCreator("switchPlayerEnemy", function(playerName: string, enemy: Model)
		return {
			enemy = enemy,
			playerName = playerName,
		}
	end),
	resetPlayerData = makeActionCreator("resetPlayerData", function(playerName: string)
		return {
			playerName = playerName,
		}
	end),
	setCurrentPunchingBag = makeActionCreator("setCurrentPunchingBag", function(playerName: string, bag: Model)
		return {
			playerName = playerName,
			currentPunchingBag = bag,
		}
	end),
	equipWeapon = makeActionCreator("equipWeapon", function(playerName: string, weaponName: string)
		return {
			playerName = playerName,
			weaponName = weaponName,
		}
	end),
	givePlayerWeapon = makeActionCreator("givePlayerWeapon", function(playerName: string, weaponName: string)
		return {
			playerName = playerName,
			weaponName = weaponName,
		}
	end),
}
