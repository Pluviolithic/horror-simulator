-- script to make pets invisible based on setting

local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local petsFolder = workspace.PetModels
local playerName = Players.LocalPlayer.Name

local function setPetEnabled(pet, enabled)
	pet.PetUI.Enabled = enabled
	for _, part in pet:GetChildren() do
		if part:IsA "BasePart" then
			part.Transparency = if enabled then 0 else 1
		end
	end
end

local function updateMyPets(show)
	for _, playerPetFolder in petsFolder:GetChildren() do
		if playerPetFolder.Name ~= playerName then
			continue
		end

		for _, pet in playerPetFolder:GetChildren() do
			setPetEnabled(pet, show)
		end
	end
end

local function updateOtherPets(show)
	for _, playerPetFolder in petsFolder:GetChildren() do
		if playerPetFolder.Name == playerName then
			continue
		end

		for _, pet in playerPetFolder:GetChildren() do
			setPetEnabled(pet, show)
		end
	end
end

petsFolder.DescendantAdded:Connect(function(descendant)
	if not descendant:FindFirstChild "PetUI" then
		return
	end

	if descendant.Parent.Name == playerName then
		if not selectors.getSetting(store:getState(), playerName, "ShowMyPets") then
			setPetEnabled(descendant, false)
		end
		return
	end

	if not selectors.getSetting(store:getState(), descendant.Parent.Name, "ShowOtherPets") then
		setPetEnabled(descendant, false)
	end
end)

playerStatePromise:andThen(function()
	updateMyPets(selectors.getSetting(store:getState(), playerName, "ShowMyPets"))
	updateOtherPets(selectors.getSetting(store:getState(), playerName, "ShowOtherPets"))

	store.changed:connect(function(newState, oldState)
		if
			selectors.getSetting(newState, playerName, "ShowMyPets")
			~= selectors.getSetting(oldState, playerName, "ShowMyPets")
		then
			updateMyPets(selectors.getSetting(newState, playerName, "ShowMyPets"))
		end

		if
			selectors.getSetting(newState, playerName, "ShowOtherPets")
			~= selectors.getSetting(oldState, playerName, "ShowOtherPets")
		then
			updateOtherPets(selectors.getSetting(newState, playerName, "ShowOtherPets"))
		end
	end)
end)

return 0
