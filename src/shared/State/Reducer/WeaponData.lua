local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

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
	equipWeapon = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].EquippedWeapon = action.weaponName
		end)
	end,
})
