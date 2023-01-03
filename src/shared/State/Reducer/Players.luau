local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local Sift = require(ReplicatedStorage.Common.lib.Sift)

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {},
		})
	end,
	removePlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = Sift.None,
		})
	end,
	updatePlayerWithProfile = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = Sift.Dictionary.mergeDeep(defaultStates.PlayerState, action.profileData),
		})
	end,
	incrementPlayerStat = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				[action.statName] = state[action.playerName][action.statName] + (action.incrementAmount or 1),
			},
		})
	end,
	switchPlayerEnemy = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentEnemy = action.enemy or Sift.None,
			},
		})
	end,
	resetPlayerData = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = defaultStates.PlayerState,
		})
	end,
	setCurrentPunchingBag = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				CurrentPunchingBag = action.currentPunchingBag or Sift.None,
			},
		})
	end,
	givePlayerWeapon = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedWeapons = Sift.Dictionary.mergeDeep(state[action.playerName].OwnedWeapons, {
					[action.weaponName] = true,
				}),
			},
		})
	end,
	equipWeapon = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				EquippedWeapon = action.weaponName,
			},
		})
	end,
	givePlayerPets = function(state, action)
		local newOwnedPets = table.clone(state[action.playerName].OwnedPets)
		local newFoundPets = table.clone(state[action.playerName].FoundPets)
		for _, petName in ipairs(action.petNames) do
			newFoundPets[petName] = true
			newOwnedPets[petName] = if newOwnedPets[petName] then newOwnedPets[petName] + 1 else 1
		end
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				OwnedPets = newOwnedPets,
				FoundPets = newFoundPets,
			},
		})
	end,
	awardGamepassToPlayer = function(state, action)
		return Sift.Dictionary.mergeDeep(state, {
			[action.playerName] = {
				AwardedGamepasses = Sift.Dictionary.mergeDeep(state[action.playerName].AwardedGamepasses, {
					[action.gamepassID] = true,
				}),
			},
		})
	end,
})
