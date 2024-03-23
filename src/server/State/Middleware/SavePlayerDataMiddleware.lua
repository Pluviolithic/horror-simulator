local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)

local function getFilteredState(playerName, state)
	state = table.clone(state)
	local filteredState = {
		Stats = selectors.getStats(state, playerName),
		PetData = selectors.getPetData(state, playerName),
		WeaponData = selectors.getWeaponData(state, playerName),
		PurchaseData = selectors.getPurchaseData(state, playerName),
		MissionData = selectors.getMissionData(state, playerName),
		SavedSettings = selectors.getSavedSettings(state, playerName),
		ChestTimers = selectors.getChestTimers(state, playerName),
		TutorialData = selectors.getTutorialData(state, playerName),
		MilestonesData = selectors.getMilestonesData(state, playerName),
		GiftData = selectors.getGiftData(state, playerName),
	}
	for field, entry in filteredState do
		if field == "Stats" then
			continue
		end
		for key in entry do
			if key:match "Multiplier" then
				continue
			end
			if type(profileTemplate[field][key]) == "nil" then
				entry[key] = nil
			end
		end
	end
	return filteredState
end

return function(nextDispatch, store)
	return function(action)
		local oldState = table.clone(store:getState())
		nextDispatch(action)
		if not action.shouldSave then
			return
		end

		local newState = store:getState()

		if not profiles[action.playerName] then
			return
		end

		local profileData = profiles[action.playerName].Data

		local filteredOldState = getFilteredState(action.playerName, oldState)
		local filteredNewState = getFilteredState(action.playerName, newState)

		for key, value in filteredNewState do
			if filteredOldState[key] ~= value then
				profileData[key] = value
			end
		end
	end
end
