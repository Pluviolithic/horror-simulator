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
	pet:WaitForChild("PetUI").Enabled = enabled
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
			task.spawn(setPetEnabled, pet, show)
		end
	end
end

local function updateOtherPets(show)
	for _, playerPetFolder in petsFolder:GetChildren() do
		if playerPetFolder.Name == playerName then
			continue
		end

		for _, pet in playerPetFolder:GetChildren() do
			task.spawn(setPetEnabled, pet, show)
		end
	end
end

local function handleSubPetFolder(subPetFolder)
	if subPetFolder.Name == playerName then
		updateMyPets(selectors.getSetting(store:getState(), playerName, "ShowMyPets"))
		subPetFolder.ChildAdded:Connect(function()
			updateMyPets(selectors.getSetting(store:getState(), playerName, "ShowMyPets"))
		end)
	else
		updateOtherPets(selectors.getSetting(store:getState(), playerName, "ShowOtherPets"))
		subPetFolder.ChildAdded:Connect(function()
			updateOtherPets(selectors.getSetting(store:getState(), playerName, "ShowOtherPets"))
		end)
	end
end

petsFolder.ChildAdded:Connect(handleSubPetFolder)
task.spawn(function()
	for _, player in Players:GetPlayers() do
		handleSubPetFolder(petsFolder:WaitForChild(player.Name))
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
