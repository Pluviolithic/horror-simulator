local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local PetInventory = CentralUI.new(player.PlayerGui:WaitForChild "PetInventory") :: {
	_initialize: () -> (),
	Refresh: () -> (),
	ClearFocusedDisplay: () -> (),
} & CentralUI.CentralUI

local pets = ReplicatedStorage.Pets
local rarityTemplates = ReplicatedStorage.RarityTemplates
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

local function getPet(petName: string): Instance?
	for _, area in pets:GetChildren() do
		local pet = area:FindFirstChild(petName)
		if pet then
			return pet
		end
	end
	return nil
end

function PetInventory:_initialize()
	player.PlayerGui:WaitForChild("MainUI").Pets.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Background.Storage.Buy.Activated:Connect(function()
		local playerState = store:getState().Players[player.Name]
		if playerState.MaxPetCount == 30 or playerState.MaxPetCount == 130 then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["+50"].Value)
		else
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["+100"].Value)
		end
	end)

	playerStatePromise:andThen(function()
		self:Refresh()

		store.changed:connect(function(newState, oldState)
			if newState.Players[player.Name].MaxPetCount == oldState.Players[player.Name].MaxPetCount then
				return
			elseif newState.Players[player.Name].MaxPetEquipCount == oldState.Players[player.Name].MaxPetEquipCount then
				return
			end
			self:Refresh()
		end)
	end)
end

function PetInventory:Refresh()
	local playerState = store:getState().Players[player.Name]
	if not playerState or not next(playerState) then
		return
	end

	if playerState.MaxPetCount == 180 and self._ui.Background.Storage:FindFirstChild "Buy" then
		self._ui.Background.Storage.Buy:Destroy()
	end

	-- get rid of buy button if max equipped pets is at gamepass limit

	-- TODO: template creation should take into account previously created templates instead of destroying and recreating them
	-- clear the inventory
	for _, rarityTemplate in pairs(self._ui.Background.ScrollingFrame:GetChildren()) do
		if rarityTemplate:IsA "ImageButton" then
			rarityTemplate:Destroy()
		end
	end

	-- display all the owned pets in the inventory
	for petName, quantity in playerState.OwnedPets do
		local pet = getPet(petName)
		local rarityTemplate = rarityTemplates[pet.RarityName.Value]:Clone()

		rarityTemplate.PetImage.Image = pet.ImageID.Value
		rarityTemplate.PetName.Text = petName
		rarityTemplate.Name = petName

		for i = 1, quantity do
			rarityTemplate:Clone().Parent = self._ui.Background.ScrollingFrame
		end
	end
end

function PetInventory:ClearFocusedDisplay() end

function PetInventory:OnOpen()
	self:Refresh()
end

task.spawn(PetInventory._initialize, PetInventory)

return PetInventory
