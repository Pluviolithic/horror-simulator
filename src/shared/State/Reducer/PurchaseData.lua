local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Immut = require(ReplicatedStorage.Common.lib.Immut)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local Dict = require(ReplicatedStorage.Common.lib.Sift).Dictionary
local defaultStates = require(ReplicatedStorage.Common.State.DefaultStates)

local produce = Immut.produce

return Rodux.createReducer({}, {
	addPlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = Dict.mergeDeep(defaultStates.PurchaseData, action.profileData.PurchaseData)
		end)
	end,
	removePlayer = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = nil
		end)
	end,
	resetPlayerData = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName] = table.clone(defaultStates.PurchaseData)
		end)
	end,
	awardGamepassToPlayer = function(state, action)
		return produce(state, function(draft)
			if draft[action.playerName] then
				draft[action.playerName].AwardedGamepasses[tostring(action.gamepassID)] = true
			end
		end)
	end,
	givePlayerTeleporter = function(state, action)
		return produce(state, function(draft)
			draft[action.playerName].PurchasedTeleporters[action.areaName] = true
		end)
	end,
})
