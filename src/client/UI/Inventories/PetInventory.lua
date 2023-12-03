local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Sift = require(ReplicatedStorage.Common.lib.Sift)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.ConfirmationUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local PetInventory = CentralUI.new(player.PlayerGui:WaitForChild "PetInventory")
local confirmationUIInstance = player.PlayerGui:WaitForChild("PetInventory").Confirmation
local rarityTemplates = ReplicatedStorage.RarityTemplates
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

local evolvedColor = Color3.fromRGB(255, 255, 0)
local ableToEvolveColor = Color3.fromRGB(0, 229, 255)
local unableToEvolveColor = Color3.fromRGB(255, 255, 255)

local function multiplierComparator(a: { [any]: any }, b: { [any]: any }): boolean
	return a.Multiplier > b.Multiplier
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
	interfaces[self] = true

	player.PlayerGui:WaitForChild("MainUI").Pets.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Background.Storage.Buy.Activated:Connect(function()
		local maxPetCount = selectors.getStat(store:getState(), player.Name, "MaxPetCount")
		if maxPetCount == 30 or maxPetCount == 130 then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["50PetStorage"].Value)
		else
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["100PetStorage"].Value)
		end
	end)

	self._ui.Background.Equipped.Buy.Activated:Connect(function()
		if not selectors.hasGamepass(store:getState(), player.Name, "1PetEquipped") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["1PetEquipped"].Value)
		elseif not selectors.hasGamepass(store:getState(), player.Name, "2PetEquipped") then
			MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2PetEquipped"].Value)
		end
	end)

	self._ui.Background.UnequipAll.Activated:Connect(function()
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
				if
					petTemplate.Equipped.Visible
					or petUtils.getPet(petTemplate.PetName.Text):FindFirstChild "PermaLock"
				then
					return
				end
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
				if self._focusedTemplate == petTemplate or petTemplate.Lock.Visible then
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
	if
		selectors.getStat(store:getState(), player.Name, "MaxPetCount") == 180
		and self._ui.Background.Storage:FindFirstChild "Buy"
	then
		self._ui.Background.Storage.Buy:Destroy()
		self._ui.Background.Storage.Amount.Position = UDim2.fromScale(0.352, 0.113)
	end

	if
		selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount") == 6
		and self._ui.Background.Equipped:FindFirstChild "Buy"
	then
		self._ui.Background.Equipped.Buy:Destroy()
		self._ui.Background.Equipped.Amount.Position = UDim2.fromScale(0.352, 0.113)
	end

	-- clear the inventory
	for _, rarityTemplate in self._ui.Background.ScrollingFrame:GetChildren() do
		if rarityTemplate:IsA "ImageButton" then
			rarityTemplate:Destroy()
		end
	end

	self._focusedTemplate = nil

	local lockCounters = table.clone(selectors.getLockedPets(store:getState(), player.Name))
	local equippedCounters = table.clone(selectors.getEquippedPets(store:getState(), player.Name))

	local equippedPetTemplates = {}
	local lockedPetTemplates = {}
	local petTemplates = {}

	for petName, quantity in selectors.getOwnedPets(store:getState(), player.Name) do
		local pet = petUtils.getPet(petName)
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

			if details.Multiplier < 1 then
				details.Multiplier += 1
			end

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

			if petName:match "Evolved" then
				details.Evolved = true
				petTemplate.PetName.TextColor3 = evolvedColor
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

	self._focusedTemplate = details.PetTemplate

	if not details.Locked and details.PetTemplate:FindFirstChild "Unlocked" then
		details.PetTemplate.Unlocked.Visible = true
	end

	self._ui.RightBackground.Icon.Visible = true
	self._ui.RightBackground.Equip.Visible = true
	self._ui.RightBackground.Delete.Visible = true

	self._ui.RightBackground.PetName.Text = details.PetName
	self._ui.RightBackground.PetImage.Image = details.PetImage
	self._ui.RightBackground.Multiplier.Text = "x" .. details.Multiplier

	if details.Evolved then
		self._ui.RightBackground.PetName.TextColor3 = evolvedColor
		self._ui.RightBackground.Evolve.ImageColor3 = evolvedColor
		self._ui.RightBackground.Evolve.EvolveText.Text = "Evolved"
	else
		self._ui.RightBackground.Evolve.EvolveText.Text = "Evolve (" .. details.Quantity .. "/5)"
		self._ui.RightBackground.PetName.TextColor3 = unableToEvolveColor
		if details.Quantity > 4 then
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
		details.Locked = not details.Locked
		details.Equipped = not details.Equipped
		self:_setFocusedDisplay(details)
	end))

	self._focusedDestructor:Add(self._ui.RightBackground.Delete.Activated:Connect(function()
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
		end
	end))

	if details.Evolved then
		return
	end

	self._focusedDestructor:Add(self._ui.RightBackground.Evolve.Activated:Connect(function()
		if details.Quantity > 4 then
			Remotes.Client:Get("EvolvePet"):SendToServer(details.PetName)
			self:_clearFocusedDisplay()
		end
	end))
end

function PetInventory:OnOpen()
	self:_clearFocusedDisplay()
	self:Refresh()
end

task.spawn(PetInventory._initialize, PetInventory)

return PetInventory
