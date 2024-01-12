local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce
local GamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.MultiplierData)

			local fearMultiplier, fearMultiplierWholePartCount =
				petUtils.getEquippedPetsMultiplier(action.profileData.PetData.EquippedPets, action.playerName)
			if action.profileData.PurchaseData.AwardedGamepasses[tostring(GamepassIDs["2xFear"].Value)] then
				fearMultiplier += 2
				fearMultiplierWholePartCount += 1
			end

			draft[action.playerName].FearMultiplier = fearMultiplier
			draft[action.playerName].FearMultiplierCount = fearMultiplierWholePartCount

			if action.profileData.PurchaseData.AwardedGamepasses[tostring(GamepassIDs["2xStrength"].Value)] then
				draft[action.playerName].StrengthMultiplier = 2
				draft[action.playerName].StrengthMultiplierCount = 1
			end

			if action.profileData.PurchaseData.AwardedGamepasses[tostring(GamepassIDs["2xGems"].Value)] then
				draft[action.playerName].GemsMultiplier = 2
				draft[action.playerName].GemsMultiplierCount = 1
			end

			if action.profileData.PurchaseData.AwardedGamepasses[tostring(GamepassIDs["2xFearMeter"].Value)] then
				draft[action.playerName].MaxFearMeterMultiplier = 2
				draft[action.playerName].MaxFearMeterMultiplierCount = 1
			end

			if action.profileData.PurchaseData.AwardedGamepasses[tostring(GamepassIDs["2xTokens"].Value)] then
				draft[action.playerName].RebirthTokensMultiplier = 2
				draft[action.playerName].RebirthTokensMultiplierCount = 1
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
			draft[action.playerName] = table.clone(defaultStates.MultiplierData)
		end)
	end,
	incrementPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			if not draft[action.playerName][action.multiplierName] then
				draft[action.playerName][action.multiplierName] = 0
			end
			local multiplierWholePartCount = draft[action.playerName][action.multiplierName .. "Count"] or 0
			draft[action.playerName][action.multiplierName] += action.incrementAmount
			if action.incrementAmount > 1 then
				multiplierWholePartCount += 1
			end
			draft[action.playerName][action.multiplierName .. "Count"] = multiplierWholePartCount
		end)
	end,
	setPlayerMultiplier = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName][action.multiplierName] = action.value
			if action.value > 1 then
				draft[action.playerName][action.multiplierName .. "Count"] = 1
			else
				draft[action.playerName][action.multiplierName .. "Count"] = 0
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
	addFriend = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].ActiveFriendsWhoJoined[action.friendName] = true
		end)
	end,
	removeFriend = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].ActiveFriendsWhoJoined[action.friendName] = nil
		end)
	end,
})
