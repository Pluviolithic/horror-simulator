local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.MultiplierData, action.profileData.MultiplierData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = defaultStates.MultiplierData
		end)
	end,
	incrementPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			local multiplierWholePartCount = draft[action.playerName][action.multiplierName .. "Count"] or 0
			draft[action.playerName][action.multiplierName] += action.incrementAmount
			if action.incrementAmount > 1 then
				draft[action.playerName][action.multiplierName .. "Count"] = multiplierWholePartCount + 1
			end
		end)
	end,
	setPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.multiplierName] = action.value
			if draft[action.playerName][action.multiplierName] < 1 then
				draft[action.playerName][action.multiplierName] += 1
			end
		end)
	end,
	equipPlayerPets = function(state, action)
		return produce(state, function(draft)
			local multiplierWholePartCount = draft[action.playerName].FearMultiplierCount or 0
			local addedFearMultiplier = 0
			for petName, quantity in action.petsToEquip do
				local singleMultiplier = petUtils.getPet(petName).Multiplier.Value
				addedFearMultiplier += singleMultiplier * quantity
				if singleMultiplier > 1 then
					multiplierWholePartCount += quantity
				end
			end
			draft[action.playerName].FearMultiplier += addedFearMultiplier
			draft[action.playerName].FearMultiplierCount = multiplierWholePartCount
		end)
	end,
	unequipPlayerPets = function(state, action)
		return produce(state, function(draft)
			local multiplierWholePartCount = draft[action.playerName].FearMultiplierCount or 0
			local removedFearMultiplier = 0
			for petName, quantity in action.petsToUnequip do
				local singleMultiplier = petUtils.getPet(petName).Multiplier.Value
				removedFearMultiplier -= singleMultiplier * quantity
				if singleMultiplier > 1 then
					multiplierWholePartCount -= quantity
				end
			end
			draft[action.playerName].FearMultiplier += removedFearMultiplier
			draft[action.playerName].FearMultiplierCount = multiplierWholePartCount
		end)
	end,
})
