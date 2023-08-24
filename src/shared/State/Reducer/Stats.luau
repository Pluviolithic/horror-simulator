local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.Stats, action.profileData.Stats)
			if
				draft[action.playerName].CurrentFearMeter == draft[action.playerName].MaxFearMeter
				and (os.time() - draft[action.playerName].LastScaredTimestamp) > 120
			then
				draft[action.playerName].CurrentFearMeter = 0
			end
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = defaultStates.Stats
		end)
	end,
	incrementPlayerStat = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.statName] += (action.incrementAmount or 1)
			if action.statName == "Strength" then
				draft[action.playerName].Rank = rankUtils.getRankFromStrength(draft[action.playerName][action.statName])
				draft[action.playerName].MaxFearMeter = rankUtils.getMaxFearMeterFromRank(draft[action.playerName].Rank)
				draft[action.playerName].RequiredFear = 5 * draft[action.playerName][action.statName]
			elseif action.statName == "CurrentFearMeter" then
				if draft[action.playerName].CurrentFearMeter == draft[action.playerName].MaxFearMeter then
					draft[action.playerName].LastScaredTimestamp = os.time()
				else
					draft[action.playerName].LastScaredTimestamp = -1
				end
			end
		end)
	end,
	setPlayerStat = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.statName] = action.value
			if action.statName == "Strength" then
				draft[action.playerName].Rank = rankUtils.getRankFromStrength(draft[action.playerName][action.statName])
				draft[action.playerName].MaxFearMeter = rankUtils.getMaxFearMeterFromRank(draft[action.playerName].Rank)
				draft[action.playerName].RequiredFear = 5 * draft[action.playerName][action.statName]
			elseif action.statName == "CurrentFearMeter" then
				if draft[action.playerName].CurrentFearMeter == draft[action.playerName].MaxFearMeter then
					draft[action.playerName].LastScaredTimestamp = os.time()
				end
			end
		end)
	end,
	givePlayerPets = function(state, action)
		local addedPetCount = 0
		for _, quantity in action.petsToGive do
			addedPetCount += quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetCount += addedPetCount
		end)
	end,
	deletePlayerPets = function(state, action)
		local removedPetCount = 0
		for _, quantity in action.petsToDelete do
			removedPetCount -= quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetCount += removedPetCount
		end)
	end,
	equipPlayerPets = function(state, action)
		local addedPetEquipCount = 0
		local addedPetFearMultiplier = 0
		for petName, quantity in action.petsToEquip do
			addedPetEquipCount += quantity
			addedPetFearMultiplier += petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetEquipCount += addedPetEquipCount
			draft[action.playerName].PetFearMultiplier += addedPetFearMultiplier
		end)
	end,
	unequipPlayerPets = function(state, action)
		local removedPetEquipCount = 0
		local removedPetFearMultiplier = 0
		for petName, quantity in action.petsToUnequip do
			removedPetEquipCount -= quantity
			removedPetFearMultiplier -= petUtils.getPet(petName).Multiplier.Value * quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetEquipCount += removedPetEquipCount
			draft[action.playerName].PetFearMultiplier += removedPetFearMultiplier
		end)
	end,
})
