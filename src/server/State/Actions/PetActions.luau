local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	givePlayerPets = makeActionCreator("givePlayerPets", function(playerName: string, petNames: { [string]: boolean })
		return {
			playerName = playerName,
			petNames = petNames,
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
	unequipAllPets = makeActionCreator("unequipAllPets", function(playerName: string)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
	equipPets = makeActionCreator("equipPets", function(playerName: string, petNames: { string })
		return {
			playerName = playerName,
			petNames = petNames,
			shouldSave = true,
		}
	end),
	evolvePet = makeActionCreator("evolvePet", function(playerName: string, petName: string)
		return {
			playerName = playerName,
			petName = petName,
			shouldSave = true,
		}
	end),
	evolveAllPets = makeActionCreator("evolveAllPets", function(playerName: string)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
	deleteAllPets = makeActionCreator("deleteAllPets", function(playerName: string)
		return {
			playerName = playerName,
			shouldSave = true,
		}
	end),
}
