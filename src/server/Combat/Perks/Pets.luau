local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)

Remotes.Server:Get("EquipPet"):Connect(function(player: Player, petName: string, locked: boolean)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if playerState.CurrentPetEquipCount == playerState.MaxPetEquipCount then
		return 1
	end

	if not playerState.OwnedPets[petName] then
		return 1
	end

	store:dispatch(actions.equipPet(player.Name, petName))
	if not locked then
		store:dispatch(actions.lockPet(player.Name, petName))
	end

	return 0
end)

Remotes.Server:Get("UnequipPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.EquippedPets[petName] or not playerState.OwnedPets[petName] then
		return 1
	end

	store:dispatch(actions.unequipPet(player.Name, petName))
	store:dispatch(actions.unlockPet(player.Name, petName))

	return 0
end)

Remotes.Server:Get("LockPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.OwnedPets[petName] then
		return 1
	end

	store:dispatch(actions.lockPet(player.Name, petName))

	return 0
end)

Remotes.Server:Get("UnlockPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.OwnedPets[petName] or not playerState.LockedPets[petName] then
		return 1
	end

	store:dispatch(actions.unlockPet(player.Name, petName))

	return 0
end)

Remotes.Server:Get("DeletePet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.OwnedPets[petName] then
		return 1
	end

	if playerState.LockedPets[petName] and playerState.LockedPets[petName] >= playerState.OwnedPets[petName] then
		return 1
	end

	store:dispatch(actions.deletePet(player.Name, petName))

	return 0
end)

Remotes.Server:Get("EvolvePet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	local playerState = store:getState().Players[player.Name]

	if not playerState.OwnedPets[petName] or playerState.OwnedPets[petName] < 5 then
		return 1
	end

	local quantityDifference = playerState.OwnedPets[petName] - (playerState.LockedPets[petName] or 0)
	if quantityDifference < 5 then
		store:dispatch(actions.unlockPet(player.Name, petName, 5 - quantityDifference))
	end
	store:dispatch(actions.deletePet(player.Name, petName, 5))
	store:dispatch(actions.givePlayerPets(player.Name, { "Evolved " .. petName }))

	return 0
end)

return 0
