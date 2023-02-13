local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local PetInventory = CentralUI.new(player.PlayerGui:WaitForChild "PetInventory") :: {
	_initialize: () -> (),
	_focusedTemplate: Instance?,
	_initializeLockButton: (petTemplate: ImageButton | any) -> (),
	Refresh: () -> (),
	_focusedDestructor: typeof(Janitor.new())?,
	_clearFocusedDisplay: () -> (),
	_setFocusedDisplay: (details: { [any]: any }) -> (),
} & CentralUI.CentralUI

local pets = ReplicatedStorage.Pets
local rarityTemplates = ReplicatedStorage.RarityTemplates
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

local ableToEvolveColor = Color3.fromRGB(0, 229, 255)
local unableToEvolveColor = Color3.fromRGB(255, 255, 255)

local function multiplierComparator(a: { [any]: any }, b: { [any]: any }): boolean
	return a.Multiplier > b.Multiplier
end

local function getPet(petName: string): Instance?
	for _, area in pets:GetChildren() do
		local pet = area:FindFirstChild(petName)
		if pet then
			return pet
		end
	end
	return nil
end

function PetInventory:_initialize(): ()
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

function PetInventory:_initializeLockButton(petTemplate: ImageButton | any, locked: boolean): ()
	local destructor = Janitor.new()
	destructor:LinkToInstance(petTemplate)

	if self._focusedTemplate == petTemplate then
		petTemplate.Unlocked.Visible = true
	end

	if locked then
		petTemplate.Lock.Visible = true
		destructor:Add(
			petTemplate.Lock.Activated:Connect(function()
				petTemplate.Lock.Visible = false
				destructor:Cleanup()
				Remotes.Client:Get("UnlockPet"):SendToServer(petTemplate.PetName.Text)
				self:_initializeLockButton(petTemplate, false)
			end),
			"Disconnect"
		)
	else
		destructor:Add(
			petTemplate.MouseEnter:Connect(function()
				petTemplate.Unlocked.Visible = true
			end),
			"Disconnect"
		)
		destructor:Add(
			petTemplate.MouseLeave:Connect(function()
				if self._focusedTemplate == petTemplate then
					return
				end
				petTemplate.Unlocked.Visible = false
			end),
			"Disconnect"
		)
		destructor:Add(
			petTemplate.Unlocked.Activated:Connect(function()
				petTemplate.Unlocked.Visible = false
				petTemplate.Lock.Visible = true
				destructor:Cleanup()
				Remotes.Client:Get("LockPet"):SendToServer(petTemplate.PetName.Text)
				self:_initializeLockButton(petTemplate, true)
			end),
			"Disconnect"
		)
	end
end

function PetInventory:Refresh()
	local playerState = store:getState().Players[player.Name]
	if not playerState or not next(playerState) then
		return
	end

	if playerState.MaxPetCount == 180 and self._ui.Background.Storage:FindFirstChild "Buy" then
		self._ui.Background.Storage.Buy:Destroy()
	end

	-- TODO: get rid of buy button if max equipped pets is at gamepass limit

	-- TODO: template creation should (maybe) take into account previously created templates instead of destroying and recreating them
	-- clear the inventory
	for _, rarityTemplate in pairs(self._ui.Background.ScrollingFrame:GetChildren()) do
		if rarityTemplate:IsA "ImageButton" then
			rarityTemplate:Destroy()
		end
	end

	self._focusedTemplate = nil

	local lockCounters = table.clone(playerState.LockedPets)
	local equippedCounters = table.clone(playerState.EquippedPets)

	local equippedPetTemplates = {}
	local lockedPetTemplates = {}
	local petTemplates = {}

	for petName, quantity in playerState.OwnedPets do
		local pet = getPet(petName)
		local rarityTemplate = rarityTemplates[pet.RarityName.Value]:Clone()

		rarityTemplate.PetImage.Image = pet.ImageID.Value
		rarityTemplate.PetName.Text = petName
		rarityTemplate.Lock.Visible = false
		rarityTemplate.Unlocked.Visible = false
		rarityTemplate.Equipped.Visible = false
		rarityTemplate.Name = petName

		for _ = 1, quantity do
			local petTemplate = rarityTemplate:Clone()
			local details = {
				PetName = petName,
				Quantity = quantity,
				PetImage = pet.ImageID.Value,
				PetTemplate = petTemplate,
				Multiplier = pet.Multiplier.Value,
			}

			if lockCounters[petName] and lockCounters[petName] > 0 then
				lockCounters[petName] -= 1
				self:_initializeLockButton(petTemplate, true)
				details.Locked = true
				table.insert(lockedPetTemplates, details)
			else
				self:_initializeLockButton(petTemplate, false)
				details.Locked = false
			end

			if equippedCounters[petName] and equippedCounters[petName] > 0 then
				equippedCounters[petName] -= 1
				petTemplate.Equipped.Visible = true
				details.Equipped = true
				table.insert(equippedPetTemplates, details)
			else
				details.Equipped = false
			end

			if not details.Locked and not details.Equipped then
				table.insert(petTemplates, details)
			end

			petTemplate.Activated:Connect(function()
				if self._focusedTemplate == petTemplate then
					self:_clearFocusedDisplay()
					return
				elseif self._focusedTemplate then
					self._focusedTemplate.Unlocked.Visible = false
				end
				self._focusedTemplate = petTemplate
				self:_setFocusedDisplay(details)
			end)
		end
	end

	table.sort(equippedPetTemplates, multiplierComparator)
	table.sort(lockedPetTemplates, multiplierComparator)
	table.sort(petTemplates, multiplierComparator)

	local templates = Sift.Array.concat(equippedPetTemplates, lockedPetTemplates, petTemplates)

	for _, template in templates do
		template.PetTemplate.Parent = self._ui.Background.ScrollingFrame
	end
end

function PetInventory:_clearFocusedDisplay()
	if self._focusedDestructor then
		self._focusedDestructor:Cleanup()
		self._focusedDestructor = nil
		self._focusedTemplate = nil
	end

	self._ui.RightBackground.Icon.Visible = false
	self._ui.RightBackground.Equip.Visible = false
	self._ui.RightBackground.Delete.Visible = false
	self._ui.RightBackground.Evolve.Visible = false
	self._ui.RightBackground.PetName.Visible = false
	self._ui.RightBackground.PetImage.Visible = false
	self._ui.RightBackground.Multiplier.Visible = false
end

function PetInventory:_setFocusedDisplay(details)
	self:_clearFocusedDisplay()
	self._focusedDestructor = Janitor.new()

	self._ui.RightBackground.Icon.Visible = true
	self._ui.RightBackground.Equip.Visible = true
	self._ui.RightBackground.Delete.Visible = true

	self._ui.RightBackground.PetName.Text = details.PetName
	self._ui.RightBackground.PetImage.Image = details.PetImage
	self._ui.RightBackground.Multiplier.Text = "x" .. details.Multiplier
	self._ui.RightBackground.Evolve.EvolveText.Text = "Evolve (" .. math.min(details.Quantity, 5) .. "/5)"

	if details.Quantity > 4 then
		self._ui.RightBackground.Evolve.ImageColor3 = ableToEvolveColor
	else
		self._ui.RightBackground.Evolve.ImageColor3 = unableToEvolveColor
	end

	if details.Equipped then
		self._ui.RightBackground.Equip.EquipText.Text = "Unequip"
	else
		self._ui.RightBackground.Equip.EquipText.Text = "Equip"
	end

	self._ui.RightBackground.Evolve.Visible = true
	self._ui.RightBackground.PetName.Visible = true
	self._ui.RightBackground.PetImage.Visible = true
	self._ui.RightBackground.Multiplier.Visible = true

	self._focusedDestructor:Add(self._ui.RightBackground.Equip.Activated:Connect(function()
		if details.Equipped then
			Remotes.Client:Get("UnequipPet"):SendToServer(details.PetName)
		else
			Remotes.Client:Get("EquipPet"):SendToServer(details.PetName)
		end
	end))

	self._focusedDestructor:Add(self._ui.RightBackground.Delete.Activated:Connect(function()
		if not details.Locked then
			Remotes.Client:Get("DeletePet"):SendToServer(details.PetName)
		end
	end))
end

function PetInventory:OnOpen()
	self:_clearFocusedDisplay()
	self:Refresh()
end

task.spawn(PetInventory._initialize, PetInventory)

return PetInventory
