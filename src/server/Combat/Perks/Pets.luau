local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local pets = ReplicatedStorage.Pets

local function petExists(petName: string): boolean
	for _, area in pets:GetChildren() do
		if area:FindFirstChild(petName) then
			return true
		end
	end
	return false
end

Remotes.Server:Get("EquipPet"):Connect(function(player: Player, petName: string)
	if not petExists(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if playerState.CurrentPetEquipCount == playerState.MaxPetEquipCount then
		return 1
	end

	if not playerState.OwnedPets[petName] or playerState.EquippedPets[petName] then
		return 1
	end

	store:dispatch(actions.equipPet(player.Name, petName))

	return 0
end)

Remotes.Server:Get("UnequipPet"):Connect(function(player: Player, petName: string)
	if not petExists(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.EquippedPets[petName] or not playerState.OwnedPets[petName] then
		return 1
	end

	store:dispatch(actions.unequipPet(player.Name, petName))

	return 0
end)
