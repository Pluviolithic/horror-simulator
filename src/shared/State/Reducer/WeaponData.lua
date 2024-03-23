local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce
local weapons = ReplicatedStorage.Weapons

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.WeaponData, action.profileData.WeaponData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.WeaponData)
		end)
	end,
	givePlayerWeapon = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].OwnedWeapons[action.weaponName] = true
		end)
	end,
	takePlayerWeapon = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].OwnedWeapons[action.weaponName] = nil
			local bestWeaponName, bestWeaponDamage = "Fists", -1
			for weaponName in draft[action.playerName].OwnedWeapons do
				if weaponName == "Fists" then
					continue
				end
				if weapons[weaponName].Damage.Value > bestWeaponDamage then
					bestWeaponName = weaponName
					bestWeaponDamage = weapons[weaponName].Damage.Value
				end
			end
			draft[action.playerName].EquippedWeapon = bestWeaponName
		end)
	end,
	unequipWeapon = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].EquippedWeapon = "Fists"
		end)
	end,
	equipWeapon = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].EquippedWeapon = action.weaponName
		end)
	end,
	rebirthPlayer = function(state, action)
		return produce(state, function(draft)
			local bestWeaponName, bestWeaponDamage = "Fists", -1
			local ownedWeapons = table.clone(state[action.playerName].OwnedWeapons)
			for weaponName in ownedWeapons do
				if weaponName == "Fists" then
					continue
				end
				if weapons[weaponName]:FindFirstChild "Price" then
					draft[action.playerName].OwnedWeapons[weaponName] = nil
				elseif weapons[weaponName].Damage.Value > bestWeaponDamage then
					bestWeaponName = weaponName
					bestWeaponDamage = weapons[weaponName].Damage.Value
				end
			end
			draft[action.playerName].EquippedWeapon = bestWeaponName
		end)
	end,
})
