local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.ConfirmationUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local PetInventory = CentralUI.new(player.PlayerGui:WaitForChild "PetInventory")
local confirmationUIInstance = player.PlayerGui:WaitForChild("PetInventory").Confirmation
local rarityTemplates = ReplicatedStorage.RarityTemplates
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local globalMaxPetEquipCount = ReplicatedStorage.Config.Pets.GlobalMaxPetEquipCount.Value

local evolvedColor = Color3.fromRGB(255, 255, 0)
local ableToEvolveColor = Color3.fromRGB(0, 229, 255)
local unableToEvolveColor = Color3.fromRGB(255, 255, 255)

local pets = {}
local layoutOrders = {}

local function multiplierComparator(a, b): boolean
	return a.Multiplier.Value > b.Multiplier.Value
end

local function shouldRefresh(newState, oldState): boolean
	if selectors.isPlayerLoaded(newState, player.Name) and not selectors.isPlayerLoaded(oldState, player.Name) then
		return true
	end
	return selectors.getStat(newState, player.Name, "MaxPetCount")
			~= selectors.getStat(oldState, player.Name, "MaxPetCount")
		or selectors.getStat(newState, player.Name, "MaxPetEquipCount") ~= selectors.getStat(
			oldState,
			player.Name,
			"MaxPetEquipCount"
		)
		or selectors.getOwnedPets(newState, player.Name) ~= selectors.getOwnedPets(oldState, player.Name)
		or selectors.getEquippedPets(newState, player.Name) ~= selectors.getEquippedPets(oldState, player.Name)
		or selectors.getLockedPets(newState, player.Name) ~= selectors.getLockedPets(oldState, player.Name)
end

function PetInventory:_initialize(): ()
	for _, petFolder in ReplicatedStorage.Pets:GetChildren() do
		for _, pet in petFolder:GetChildren() do
			table.insert(pets, pet)
		end
	end

	for _, petFolder in ReplicatedStorage.EvolvedPets:GetChildren() do
		for _, pet in petFolder:GetChildren() do
			table.insert(pets, pet)
		end
	end

	table.sort(pets, multiplierComparator)

	for index, pet in pets do
		layoutOrders[pet.Name] = index + globalMaxPetEquipCount
	end

	table.clear(pets)

	player.PlayerGui:WaitForChild("MainUI").Pets.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Background.Storage.Buy.Activated:Connect(function()
		playSoundEffect "UIButton"
		if not selectors.hasGamepass(store:getState(), player.Name, "50PetStorage") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["50PetStorage"].Value)
		elseif not selectors.hasGamepass(store:getState(), player.Name, "100PetStorage") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["100PetStorage"].Value)
		end
	end)

	self._ui.Background.Equipped.Buy.Activated:Connect(function()
		playSoundEffect "UIButton"
		if not selectors.hasGamepass(store:getState(), player.Name, "1PetEquipped") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["1PetEquipped"].Value)
		elseif not selectors.hasGamepass(store:getState(), player.Name, "2PetEquipped") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2PetEquipped"].Value)
		end
	end)

	self._ui.Background.UnequipAll.Activated:Connect(function()
		playSoundEffect "UIButton"
		if self._confirmationDestructor then
			self._confirmationDestructor:Cleanup()
		end
		self._confirmationDestructor = confirmationUI(
			confirmationUIInstance,
			"Are you sure you want to Unequip All Pets?",
			function()
				Remotes.Client:Get("UnequipAllPets"):SendToServer()
				self:_clearFocusedDisplay()
			end,
			self
		)
	end)

	self._ui.Background.EquipBest.Activated:Connect(function()
		playSoundEffect "UIButton"
		if self._confirmationDestructor then
			self._confirmationDestructor:Cleanup()
		end
		self._confirmationDestructor = confirmationUI(
			confirmationUIInstance,
			"Are you sure you want to Equip Your Best Pets?",
			function()
				Remotes.Client:Get("EquipBestPets"):SendToServer()
				self:_clearFocusedDisplay()
			end,
			self
		)
	end)

	self._ui.Background.EvolveAll.Activated:Connect(function()
		playSoundEffect "UIButton"
		if self._confirmationDestructor then
			self._confirmationDestructor:Cleanup()
		end
		self._confirmationDestructor = confirmationUI(
			confirmationUIInstance,
			"Are you sure you want to Evolve All Pets?",
			function()
				Remotes.Client:Get("EvolveAllPets"):SendToServer()
				self:_clearFocusedDisplay()
			end,
			self
		)
	end)

	self._ui.Background.DeleteAll.Activated:Connect(function()
		playSoundEffect "UIButton"
		if self._confirmationDestructor then
			self._confirmationDestructor:Cleanup()
		end
		self._confirmationDestructor = confirmationUI(
			confirmationUIInstance,
			"Delete All Pets? Make sure all the pets you want to keep are Locked.",
			function()
				Remotes.Client:Get("DeleteAllPets"):SendToServer()
				self:_clearFocusedDisplay()
			end,
			self
		)
	end)

	playerStatePromise:andThen(function()
		self:Refresh()

		store.changed:connect(function(newState, oldState)
			if not shouldRefresh(newState, oldState) then
				return
			end
			self:Refresh()
		end)
	end)
end

function PetInventory:Refresh()
	if
		selectors.hasGamepass(store:getState(), player.Name, "50PetStorage")
		and selectors.hasGamepass(store:getState(), player.Name, "100PetStorage")
		and self._ui.Background.Storage:FindFirstChild "Buy"
	then
		self._ui.Background.Storage.Buy:Destroy()
		self._ui.Background.Storage.Amount.Position = UDim2.fromScale(0.352, 0.113)
	end

	if
		selectors.hasGamepass(store:getState(), player.Name, "1PetEquipped")
		and selectors.hasGamepass(store:getState(), player.Name, "2PetEquipped")
		and self._ui.Background.Equipped:FindFirstChild "Buy"
	then
		self._ui.Background.Equipped.Buy:Destroy()
		self._ui.Background.Equipped.Amount.Position = UDim2.fromScale(0.352, 0.113)
	end

	local ownedPets = table.clone(selectors.getOwnedPets(store:getState(), player.Name))
	local equippedPets = table.clone(selectors.getEquippedPets(store:getState(), player.Name))
	local lockedPets = table.clone(selectors.getLockedPets(store:getState(), player.Name))

	local lastFoundIndices = {}
	local sortedEquippedPets = {}
	for petName, count in equippedPets do
		for _ = 1, count do
			table.insert(sortedEquippedPets, petUtils.getPet(petName))
		end
	end
	table.sort(sortedEquippedPets, multiplierComparator)

	local foundMatch = if self._focusedTemplateDetails then false else true
	local propertiesToMatch
	if not foundMatch then
		propertiesToMatch = {
			Equipped = self._focusedTemplateDetails.Equipped,
			Locked = self._focusedTemplateDetails.Locked,
			Name = self._focusedTemplateDetails.PetName,
		}
	end

	for _, petTemplate in self._ui.Background.ScrollingFrame:GetChildren() do
		if not petTemplate:IsA "UIGridLayout" then
			petTemplate:Destroy()
		end
	end

	for petName, count in ownedPets do
		for _ = 1, count do
			local lockedPetCount = lockedPets[petName] or 0
			local equippedPetCount = equippedPets[petName] or 0
			local pet = petUtils.getPet(petName)
			local petTemplate = rarityTemplates[pet.RarityName.Value]:Clone()

			petTemplate.PetImage.Image = pet.ImageID.Value
			petTemplate.PetName.Text = petName
			petTemplate.Visible = true
			petTemplate.Name = petName
			petTemplate.LayoutOrder = layoutOrders[pet.Name]

			if petName:match "Evolved" then
				petTemplate.PetName.TextColor3 = evolvedColor
			end

			petTemplate.Parent = self._ui.Background.ScrollingFrame

			if lockedPetCount > 0 then
				petTemplate.Lock.Visible = true
				lockedPets[petName] -= 1
			else
				petTemplate.Lock.Visible = false
			end
			if equippedPetCount > 0 then
				petTemplate.LayoutOrder = table.find(sortedEquippedPets, pet, lastFoundIndices[pet] or 1)
				lastFoundIndices[pet] = petTemplate.LayoutOrder + 1
				petTemplate.Equipped.Visible = true
				equippedPets[petName] -= 1
			else
				petTemplate.Equipped.Visible = false
			end

			if
				not foundMatch
				and petTemplate.Equipped.Visible == propertiesToMatch.Equipped
				and petTemplate.Lock.Visible == propertiesToMatch.Locked
				and petTemplate.PetName.Text == propertiesToMatch.Name
			then
				foundMatch = true
				self._focusedTemplate = petTemplate
				self:_setFocusedDisplay()
			end

			petTemplate.Activated:Connect(function()
				playSoundEffect "UIButton"
				if self._focusedTemplate == petTemplate then
					self:_clearFocusedDisplay()
					self._focusedTemplate = nil
					return
				elseif self._focusedTemplate and self._focusedTemplate.Parent ~= nil then
					self._focusedTemplate.Unlocked.Visible = false
				end
				self._focusedTemplate = petTemplate
				self._focusedTemplateDetails = {
					Equipped = petTemplate.Equipped.Visible,
					Locked = petTemplate.Lock.Visible,
					PetName = petTemplate.PetName.Text,
				}
				self:_setFocusedDisplay()
			end)

			petTemplate.Unlocked.Activated:Connect(function()
				playSoundEffect "UIButton"
				--petTemplate.Unlocked.Visible = false
				--petTemplate.Lock.Visible = true
				self._focusedTemplateDetails.Locked = true
				Remotes.Client:Get("LockPet"):SendToServer(petName)
			end)

			petTemplate.Lock.Activated:Connect(function()
				playSoundEffect "UIButton"
				--petTemplate.Unlocked.Visible = true
				--petTemplate.Lock.Visible = false
				if petTemplate.Equipped.Visible or pet:FindFirstChild "PermaLock" then
					--PopupUI "You Can Not Unlock This Pet!"
					return
				end
				self._focusedTemplateDetails.Locked = false
				Remotes.Client:Get("UnlockPet"):SendToServer(petName)
			end)

			petTemplate.MouseEnter:Connect(function()
				if not petTemplate.Lock.Visible then
					petTemplate.Unlocked.Visible = true
				end
			end)

			petTemplate.MouseLeave:Connect(function()
				if self._focusedTemplate ~= petTemplate then
					petTemplate.Unlocked.Visible = false
				end
			end)
		end
	end
end

function PetInventory:_clearFocusedDisplay()
	if self._focusedDestructor then
		self._focusedDestructor:Cleanup()
		self._focusedDestructor = nil
	end

	self._ui.RightBackground.Icon.Visible = false
	self._ui.RightBackground.Equip.Visible = false
	self._ui.RightBackground.Delete.Visible = false
	self._ui.RightBackground.Evolve.Visible = false
	self._ui.RightBackground.PetName.Visible = false
	self._ui.RightBackground.PetImage.Visible = false
	self._ui.RightBackground.Multiplier.Visible = false
end

function PetInventory:_setFocusedDisplay()
	self:_clearFocusedDisplay()
	self._focusedDestructor = Janitor.new()

	if not self._focusedTemplate or not self._focusedTemplate:FindFirstChild "PetName" then
		return
	end

	local pet = petUtils.getPet(self._focusedTemplate.PetName.Text)
	local details = {
		PetName = self._focusedTemplate.PetName.Text,
		PetImage = self._focusedTemplate.PetImage.Image,
		Multiplier = pet.Multiplier.Value,
		Evolved = pet.Name:match "Evolved",
		Quantity = selectors.getOwnedPets(store:getState(), player.Name)[pet.Name],
		Equipped = self._focusedTemplate.Equipped.Visible,
		Locked = self._focusedTemplate.Lock.Visible,
		PetTemplate = self._focusedTemplate,
	}

	self._focusedTemplateDetails = details

	if not details.Locked and details.PetTemplate:FindFirstChild "Unlocked" then
		details.PetTemplate.Unlocked.Visible = true
	end

	self._ui.RightBackground.Icon.Visible = true
	self._ui.RightBackground.Equip.Visible = true
	self._ui.RightBackground.Delete.Visible = true

	self._ui.RightBackground.PetName.Text = details.PetName
	self._ui.RightBackground.PetImage.Image = details.PetImage
	self._ui.RightBackground.Multiplier.Text = "x"
		.. string.format("%.2f", (if details.Multiplier < 1 then details.Multiplier + 1 else details.Multiplier))

	if details.Evolved then
		self._ui.RightBackground.PetName.TextColor3 = evolvedColor
		self._ui.RightBackground.Evolve.ImageColor3 = evolvedColor
		self._ui.RightBackground.Evolve.EvolveText.Text = "Evolved"
	else
		local amountToEvolve = 5
		if selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "Evolver") then
			amountToEvolve = 4
		end
		self._ui.RightBackground.Evolve.EvolveText.Text = `Evolve ({details.Quantity}/{amountToEvolve})`
		self._ui.RightBackground.PetName.TextColor3 = unableToEvolveColor
		if details.Quantity >= amountToEvolve then
			self._ui.RightBackground.Evolve.ImageColor3 = ableToEvolveColor
		else
			self._ui.RightBackground.Evolve.ImageColor3 = unableToEvolveColor
		end
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
		playSoundEffect "UIButton"
		if details.Equipped then
			Remotes.Client:Get("UnequipPet"):SendToServer(details.PetName)
		elseif
			selectors.getStat(store:getState(), player.Name, "CurrentPetEquipCount")
			< selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount")
		then
			Remotes.Client:Get("EquipPet"):SendToServer(details.PetName, details.Locked)
		else
			PopupUI "Unequip A Pet First Or Buy More Pet Equips!"
			if not selectors.hasGamepass(store:getState(), player.Name, "1PetEquipped") then
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["1PetEquipped"].Value)
			elseif not selectors.hasGamepass(store:getState(), player.Name, "2PetEquipped") then
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2PetEquipped"].Value)
			end
			return
		end
		pcall(function()
			self._focusedTemplate.Equipped.Visible = not details.Equipped
			self._focusedTemplate.Lock.Visible = details.Locked
		end)
		self:_setFocusedDisplay()
	end))

	self._focusedDestructor:Add(self._ui.RightBackground.Delete.Activated:Connect(function()
		playSoundEffect "UIButton"
		if details.Locked then
			if petUtils.getPet(details.PetName):FindFirstChild "PermaLock" then
				PopupUI "You Can Not Delete This Pet!"
				return
			end
			if details.Equipped then
				PopupUI "Unequip The Pet First!"
			else
				PopupUI "Unlock The Pet First!"
			end
		else
			Remotes.Client:Get("DeletePet"):SendToServer(details.PetName)
			self:_clearFocusedDisplay()
			self._focusedTemplate = nil
		end
	end))

	if details.Evolved then
		return
	end

	self._focusedDestructor:Add(self._ui.RightBackground.Evolve.Activated:Connect(function()
		playSoundEffect "UIButton"
		local amountToEvolve = 5
		if selectors.getRebirthUpgradeLevel(store:getState(), player.Name, "Evolver") then
			amountToEvolve = 4
		end
		if details.Quantity >= amountToEvolve then
			Remotes.Client:Get("EvolvePet"):SendToServer(details.PetName)
			self:_clearFocusedDisplay()
			self._focusedTemplate = nil
		end
	end))
end

function PetInventory:OnOpen()
	self:_clearFocusedDisplay()
	self._focusedTemplate = nil
	self:Refresh()
end

task.spawn(PetInventory._initialize, PetInventory)

interfaces[PetInventory] = true

return PetInventory
