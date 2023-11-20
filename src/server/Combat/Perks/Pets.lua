local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)

local devProductIDs = ReplicatedStorage.Config.DevProductData.IDs

local function evolvePet(player, petName)
	local petOwnedCount = selectors.getPetOwnedCount(store:getState(), player.Name, petName)

	if not petOwnedCount or petOwnedCount < 5 then
		return 1
	end

	local unlockedPetCount = petOwnedCount - (selectors.getPetLockedCount(store:getState(), player.Name, petName) or 0)
	local equippedPets = selectors.getEquippedPets(store:getState(), player.Name)

	if unlockedPetCount < 5 then
		local countToUnlock = 5 - unlockedPetCount
		if countToUnlock > (petOwnedCount - equippedPets[petName]) then
			store:dispatch(
				actions.unequipPlayerPets(
					player.Name,
					{ [petName] = countToUnlock - (petOwnedCount - equippedPets[petName]) }
				)
			)
		end
		store:dispatch(actions.unlockPlayerPets(player.Name, { [petName] = countToUnlock }))
	end

	store:dispatch(actions.deletePlayerPets(player.Name, { [petName] = 5 }, true))
	store:dispatch(actions.givePlayerPets(player.Name, { ["Evolved " .. petName] = 1 }))

	return 0
end

Remotes.Server:Get("EquipPet"):Connect(function(player: Player, petName: string, locked: boolean)
	if not petUtils.getPet(petName) then
		return 1
	end

	if
		selectors.getStat(store:getState(), player.Name, "CurrentPetEquipCount")
		== selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount")
	then
		return 1
	end

	if not selectors.getPetOwnedCount(store:getState(), player.Name, petName) then
		return 1
	end

	store:dispatch(actions.equipPlayerPets(player.Name, { [petName] = 1 }))
	if not locked then
		store:dispatch(actions.lockPlayerPets(player.Name, { [petName] = 1 }))
	end

	return 0
end)

Remotes.Server:Get("UnequipPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	if
		not selectors.getPetEquippedCount(store:getState(), player.Name, petName)
		or not selectors.getPetOwnedCount(store:getState(), player.Name, petName)
	then
		return 1
	end

	store:dispatch(actions.unequipPlayerPets(player.Name, { [petName] = 1 }))
	store:dispatch(actions.unlockPlayerPets(player.Name, { [petName] = 1 }))

	return 0
end)

Remotes.Server:Get("LockPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	if not selectors.getPetOwnedCount(store:getState(), player.Name, petName) then
		return 1
	end

	store:dispatch(actions.lockPlayerPets(player.Name, { [petName] = 1 }))

	return 0
end)

Remotes.Server:Get("UnlockPet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	if
		not selectors.getPetOwnedCount(store:getState(), player.Name, petName)
		or not selectors.getPetLockedCount(store:getState(), player.Name, petName)
	then
		return 1
	end

	store:dispatch(actions.unlockPlayerPets(player.Name, { [petName] = 1 }))

	return 0
end)

Remotes.Server:Get("DeletePet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	if not selectors.getPetOwnedCount(store:getState(), player.Name, petName) then
		return 1
	end

	if
		selectors.getPetLockedCount(store:getState(), player.Name, petName)
		and selectors.getPetLockedCount(store:getState(), player.Name, petName)
			>= selectors.getPetOwnedCount(store:getState(), player.Name, petName)
	then
		return 1
	end

	store:dispatch(actions.deletePlayerPets(player.Name, { [petName] = 1 }))

	return 0
end)

Remotes.Server:Get("EvolvePet"):Connect(function(player: Player, petName: string)
	if not petUtils.getPet(petName) then
		return 1
	end

	evolvePet(player, petName)

	return 0
end)

Remotes.Server:Get("EquipBestPets"):Connect(function(player: Player)
	local equippedPets = selectors.getEquippedPets(store:getState(), player.Name)
	local bestPets = petUtils.getBestPetNames(
		selectors.getOwnedPets(store:getState(), player.Name),
		selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount")
	)

	if #bestPets == 0 then
		return 1
	end

	local bestPetsDict = {}
	for _, bestPetName in bestPets do
		bestPetsDict[bestPetName] = (bestPetsDict[bestPetName] or 0) + 1
	end

	store:dispatch(actions.unlockPlayerPets(player.Name, equippedPets))
	store:dispatch(actions.unequipPlayerPets(player.Name, equippedPets))
	store:dispatch(actions.equipPlayerPets(player.Name, bestPetsDict))
	store:dispatch(actions.lockPlayerPets(player.Name, bestPetsDict))

	return 0
end)

Remotes.Server:Get("UnequipAllPets"):Connect(function(player: Player)
	local equippedPets = selectors.getEquippedPets(store:getState(), player.Name)
	store:dispatch(actions.unlockPlayerPets(player.Name, equippedPets))
	store:dispatch(actions.unequipPlayerPets(player.Name, equippedPets))
	return 0
end)

Remotes.Server:Get("DeleteAllPets"):Connect(function(player: Player)
	local ownedPets = table.clone(selectors.getOwnedPets(store:getState(), player.Name))
	local lockedPets = selectors.getLockedPets(store:getState(), player.Name)
	for petName, count in ownedPets do
		ownedPets[petName] = count - (lockedPets[petName] or 0)
	end
	store:dispatch(actions.deletePlayerPets(player.Name, ownedPets))
	return 0
end)

Remotes.Server:Get("EvolveAllPets"):Connect(function(player: Player)
	for petName in selectors.getOwnedPets(store:getState(), player.Name) do
		local returnCode = 0
		repeat
			returnCode = evolvePet(player, petName)
		until returnCode == 1
	end
	return 0
end)

workspace.BuyGoldenDominus.Prompt.Triggered:Connect(function(player)
	MarketplaceService:PromptProductPurchase(player, devProductIDs["1GoldenDominus"].Value)
end)

workspace.BuyReaper.Prompt.Triggered:Connect(function(player)
	MarketplaceService:PromptProductPurchase(player, devProductIDs["1Reaper"].Value)
end)

store.changed:connect(function(newState, oldState)
	for playerName, petInfo in newState.PetData do
		if petInfo ~= oldState.PetData[playerName] then
			petUtils.instantiatePets(playerName, selectors.getEquippedPets(store:getState(), playerName))
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if workspace.PetModels:FindFirstChild(player.Name) then
		workspace.PetModels[player.Name]:Destroy()
	end
end)

return 0
