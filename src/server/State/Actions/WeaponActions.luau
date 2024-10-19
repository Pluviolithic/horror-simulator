local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	equipWeapon = makeActionCreator("equipWeapon", function(playerName: string, weaponName: string)
		return {
			playerName = playerName,
			weaponName = weaponName,
			shouldSave = true,
		}
	end),
	unequipWeapon = makeActionCreator("unequipWeapon", function(playerName: string)
		return {
			playerName = playerName,
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
	takePlayerWeapon = makeActionCreator("takePlayerWeapon", function(playerName: string, weaponName: string)
		return {
			playerName = playerName,
			weaponName = weaponName,
			shouldSave = true,
		}
	end),
}
