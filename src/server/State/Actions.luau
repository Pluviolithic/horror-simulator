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
				shouldSave = true,
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
			shouldSave = true,
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
			shouldSave = true,
		}
	end),
	givePlayerWeapon = makeActionCreator("givePlayerWeapon", function(playerName: string, weaponName: string)
		return {
			playerName = playerName,
			weaponName = weaponName,
			shouldSave = true,
		}
	end),
	givePlayerPets = makeActionCreator("givePlayerPets", function(playerName: string, petNames: { [string]: boolean })
		return {
			playerName = playerName,
			petNames = petNames,
			shouldSave = true,
		}
	end),
	awardGamepassToPlayer = makeActionCreator("awardGamepassToPlayer", function(playerName: string, gamepassID: number)
		return {
			playerName = playerName,
			gamepassID = gamepassID,
			shouldSave = true,
		}
	end),
	increaseMaxPetCount = makeActionCreator("increaseMaxPetCount", function(playerName: string, amount: number)
		return {
			playerName = playerName,
			amount = amount,
			shouldSave = true,
		}
	end),
	increasePlayerLuck = makeActionCreator("increasePlayerLuck", function(playerName: string, amount: number)
		return {
			playerName = playerName,
			amount = amount,
			shouldSave = true,
		}
	end),
	equipPet = makeActionCreator("equipPet", function(playerName: string, petName: string)
		return {
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	unequipPet = makeActionCreator("unequipPet", function(playerName: string, petName: string)
		return {
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	lockPet = makeActionCreator("lockPet", function(playerName: string, petName: string)
		return {
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	unlockPet = makeActionCreator("unlockPet", function(playerName: string, petName: string, quantity: number?)
		return {
			quantity = quantity or 1,
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	deletePet = makeActionCreator("deletePet", function(playerName: string, petName: string, quantity: number?)
		return {
			quantity = quantity or 1,
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	increaseMaxPetEquipCount = makeActionCreator(
		"increaseMaxPetEquipCount",
		function(playerName: string, amount: number)
			return {
				playerName = playerName,
				amount = amount,
				shouldSave = true,
			}
		end
	),
}
