local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	givePlayerPets = makeActionCreator("givePlayerPets", function(playerName: string, petNames: { [string]: number })
		return {
			playerName = playerName,
			petsToGive = petNames,
			shouldSave = true,
		}
	end),
	deletePlayerPets = makeActionCreator(
		"deletePlayerPets",
		function(playerName: string, petNames: { [string]: number })
			return {
				playerName = playerName,
				petsToDelete = petNames,
				shouldSave = true,
			}
		end
	),
	equipPlayerPets = makeActionCreator("equipPlayerPets", function(playerName: string, petNames: { [string]: number })
		return {
			playerName = playerName,
			petsToEquip = petNames,
			shouldSave = true,
		}
	end),
	unequipPlayerPets = makeActionCreator(
		"unequipPlayerPets",
		function(playerName: string, petNames: { [string]: number })
			return {
				playerName = playerName,
				petsToUnequip = petNames,
				shouldSave = true,
			}
		end
	),
	lockPlayerPets = makeActionCreator(
		"lockPlayerPets",
		function(playerName: string, petNames: { [string]: number }, fromEquip: boolean)
			return {
				playerName = playerName,
				petsToLock = petNames,
				fromEquip = fromEquip,
				shouldSave = true,
			}
		end
	),
	unlockPlayerPets = makeActionCreator(
		"unlockPlayerPets",
		function(playerName: string, petNames: { [string]: number }, force: boolean)
			return {
				playerName = playerName,
				petsToUnlock = petNames,
				force = force,
				shouldSave = true,
			}
		end
	),
}
