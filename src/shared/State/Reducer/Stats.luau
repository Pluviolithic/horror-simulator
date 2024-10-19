local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)

local produce = Immut.produce
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local baseRequiredFear = game:GetService("ReplicatedStorage").Config.Workout.RequiredFear.Value

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
			draft[action.playerName] = table.clone(defaultStates.Stats)
		end)
	end,
	incrementPlayerStat = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.statName] += (action.incrementAmount or 1)
			if action.statName == "Strength" then
				draft[action.playerName].Rank = rankUtils.getRankFromStrength(draft[action.playerName][action.statName])
				draft[action.playerName].RequiredFear = baseRequiredFear * draft[action.playerName][action.statName]
			elseif action.statName == "CurrentFearMeter" then
				if draft[action.playerName].CurrentFearMeter == draft[action.playerName].MaxFearMeter then
					draft[action.playerName].LastScaredTimestamp = os.time()
				else
					draft[action.playerName].LastScaredTimestamp = -1
				end
			end

			if action.statName == "Strength" or action.statName == "Kills" or action.statName == "Rebirths" then
				local monthlyTimestamp = clockUtils.getMonthlyTimestamp()
				draft[action.playerName][action.statName .. monthlyTimestamp] = (
					draft[action.playerName][action.statName .. monthlyTimestamp] or 0
				) + (action.incrementAmount or 1)
			end
		end)
	end,
	setPlayerStat = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.statName] = action.value
			if action.statName == "Strength" then
				draft[action.playerName].Rank = rankUtils.getRankFromStrength(draft[action.playerName][action.statName])
				draft[action.playerName].RequiredFear = baseRequiredFear * draft[action.playerName][action.statName]
			elseif action.statName == "CurrentFearMeter" then
				if draft[action.playerName].CurrentFearMeter == draft[action.playerName].MaxFearMeter then
					draft[action.playerName].LastScaredTimestamp = os.time()
				end
			end

			if action.statName == "Strength" or action.statName == "Kills" or action.statName == "Rebirths" then
				local monthlyTimestamp = clockUtils.getMonthlyTimestamp()
				draft[action.playerName][action.statName .. monthlyTimestamp] = action.value
			end
		end)
	end,
	givePlayerPets = function(state, action)
		local addedPetCount = 0
		for petName, quantity in action.petsToGive do
			if petUtils.getPet(petName):FindFirstChild "PermaLock" then
				continue
			end
			addedPetCount += quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetCount += addedPetCount
		end)
	end,
	deletePlayerPets = function(state, action)
		local removedPetCount = 0
		for petName, quantity in action.petsToDelete do
			if petUtils.getPet(petName):FindFirstChild "PermaLock" then
				continue
			end
			removedPetCount -= quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetCount += removedPetCount
		end)
	end,
	equipPlayerPets = function(state, action)
		local addedPetEquipCount = 0
		for _, quantity in action.petsToEquip do
			addedPetEquipCount += quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetEquipCount += addedPetEquipCount
		end)
	end,
	unequipPlayerPets = function(state, action)
		local removedPetEquipCount = 0
		for _, quantity in action.petsToUnequip do
			removedPetEquipCount -= quantity
		end
		return produce(state, function(draft)
			draft[action.playerName].CurrentPetEquipCount += removedPetEquipCount
		end)
	end,
	rebirthPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].Strength = defaultStates.Stats.Strength
			draft[action.playerName].Fear = defaultStates.Stats.Fear
			draft[action.playerName].Gems = defaultStates.Stats.Gems
			draft[action.playerName].LastScaredTimestamp = defaultStates.Stats.LastScaredTimestamp
			draft[action.playerName].MaxFearMeter = defaultStates.Stats.MaxFearMeter
			draft[action.playerName].CurrentFearMeter = defaultStates.Stats.CurrentFearMeter
			draft[action.playerName].RequiredFear = baseRequiredFear * defaultStates.Stats.Strength
			draft[action.playerName].Rank = rankUtils.getRankFromStrength(defaultStates.Stats.Strength)
		end)
	end,
})
