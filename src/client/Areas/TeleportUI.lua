local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local teleportPlayer = require(StarterPlayer.StarterPlayerScripts.Client.Areas.TeleportPlayer)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.ConfirmationUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Sift = require(ReplicatedStorage.Common.lib.Sift)

local freeTeleportersGamepassID = ReplicatedStorage.Config.GamepassData.IDs.FreeTeleporters.Value
local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local player = Players.LocalPlayer

local mainUI = player.PlayerGui:WaitForChild "MainUI"
local TeleportUI = CentralUI.new(player.PlayerGui:WaitForChild "Teleport")
local confirmationUIInstance = player.PlayerGui:WaitForChild("Teleport").Confirmation
local afkConfirmationUIInstance = mainUI.AFK.Confirmation

local function getAreaTeleporter(areaName: string): Instance?
	for _, teleporter in CollectionService:GetTagged "AreaTeleport" do
		if teleporter.Name == areaName .. "TP" then
			return teleporter
		end
	end
	return nil
end

function TeleportUI:_unlockArea(areaName: string, lock: boolean)
	if not self._ui.Background.ScrollingFrame[areaName]:FindFirstChild "Locked" then
		return
	end
	self._ui.Background.ScrollingFrame[areaName].Locked.Visible = lock
end

function TeleportUI:_initialize()
	playerStatePromise:andThen(function()
		self:Refresh()
		store.changed:connect(function(newState, oldState)
			if
				selectors.isPlayerLoaded(oldState, player.Name)
				and (
					selectors.getStat(newState, player.Name, "Strength")
						~= selectors.getStat(oldState, player.Name, "Strength")
					or not Sift.Dictionary.equalsDeep(
						selectors.getPurchasedTeleporters(newState, player.Name),
						selectors.getPurchasedTeleporters(oldState, player.Name)
					)
					or (
						selectors.hasGamepass(newState, player.Name, "FreeTeleporters")
						and not selectors.hasGamepass(oldState, player.Name, "FreeTeleporters")
					)
				)
			then
				self:Refresh()
			end
		end)
	end)

	interfaces[self] = true

	player.PlayerGui:WaitForChild("MainUI").Teleport.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Ad.Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, freeTeleportersGamepassID)
	end)

	mainUI.AFK.Activated:Connect(function()
		local primarySoundArea = selectors.getAudioData(store:getState(), player.Name).PrimarySoundRegion
		local purchasedTeleporters = selectors.getPurchasedTeleporters(store:getState(), player.Name)
		local target, targetAreaName = nil, nil

		if areaRequirements["Howling Woods"].Value <= selectors.getStat(store:getState(), player.Name, "Strength") then
			targetAreaName = "Howling Woods"
			target = workspace.Teleports.AFK2TP
		else
			targetAreaName = "Clown Town"
			target = workspace.Teleports.AFK1TP
		end

		if purchasedTeleporters[targetAreaName] or primarySoundArea == targetAreaName then
			confirmationUI(afkConfirmationUIInstance, "", function()
				teleportPlayer { target = target }
				petUtils.instantiatePets(player.Name, selectors.getEquippedPets(store:getState(), player.Name))
			end)
		else
			PopupUI(`You Must Buy The {targetAreaName} Teleport First!`)
			self:setEnabled(true)
		end
	end)

	for _, area in self._ui.Background.ScrollingFrame:GetChildren() do
		if not area:IsA "ImageLabel" then
			continue
		end

		area.Teleport.Active = true

		area.Teleport.Activated:Connect(function()
			local hasFreeTeleporters = selectors.hasGamepass(store:getState(), player.Name, "FreeTeleporters")
			if area.Locked.Visible or area.CostUI.Visible then
				if selectors.getStat(store:getState(), player.Name, "Strength") < areaRequirements[area.Name].Value then
					return
				end
				if
					selectors.getStat(store:getState(), player.Name, "Gems") < area.Cost.Value
					and not hasFreeTeleporters
				then
					PopupUI "You Can Not Afford This Teleporter!"
					MarketplaceService:PromptGamePassPurchase(player, freeTeleportersGamepassID)
					return
				end

				confirmationUI(
					confirmationUIInstance,
					string.format(
						'Unlock the %s teleport for <font color="rgb(224, 18, 231)">%s Gems</font>?',
						area.Name,
						if hasFreeTeleporters then "0" else formatter.formatNumberWithSuffix(area.Cost.Value)
					),
					function()
						Remotes.Client:Get("PurchaseTeleporter"):SendToServer(area.Name)
					end
				)
				return
			end
			if not player.Character or not player.Character:FindFirstChild "HumanoidRootPart" then
				return
			end
			teleportPlayer {
				target = getAreaTeleporter(area.Name),
			}
			petUtils.instantiatePets(player.Name, selectors.getEquippedPets(store:getState(), player.Name))
		end)
	end
end

function TeleportUI:Refresh()
	for _, requirement in areaRequirements:GetChildren() do
		local shouldLock = requirement.Value > selectors.getStat(store:getState(), player.Name, "Strength")

		self:_unlockArea(requirement.Name, shouldLock)

		if selectors.hasTeleporter(store:getState(), player.Name, requirement.Name) then
			self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Visible = false
		elseif not shouldLock then
			if selectors.hasGamepass(store:getState(), player.Name, "FreeTeleporters") then
				self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Gems.Text =
					'<font color= "rgb(224, 18, 231)">0 Gems</font>'
			end
			self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Visible = true
		end
	end

	if selectors.hasGamepass(store:getState(), player.Name, "FreeTeleporters") then
		self._ui.Ad.Visible = false
	else
		self._ui.Ad.Visible = true
	end
end

function TeleportUI:OnOpen()
	self:Refresh()
end

task.spawn(TeleportUI._initialize, TeleportUI)

return TeleportUI
