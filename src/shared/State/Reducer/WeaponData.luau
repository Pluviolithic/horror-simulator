local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Dict = require(ReplicatedStorage.Common.lib.Sift).Dict
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		local playerWeaponData = Dict.Filter(action.playerData, function(key)
			return Dict.has(defaultStates.WeaponData, key)
		end)
		return Dict.set(state, action.playerName, Dict.merge(defaultStates.WeaponData, playerWeaponData))
	end,
	removePlayer = function(state, action)
		return Dict.removeKey(state, action.playerName)
	end,
	resetPlayerData = function(state, action)
		return Dict.set(state, action.playerName, defaultStates.WeaponData)
	end,
	givePlayerWeapon = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				OwnedWeapons = {
					[action.weaponName] = true,
				},
			},
		})
	end,
	equipWeapon = function(state, action)
		return Dict.mergeDeep(state, {
			[action.playerName] = {
				EquippedWeapon = action.weaponName,
			},
		})
	end,
})
