local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.Areas.ConfirmationUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local Sift = require(ReplicatedStorage.Common.lib.Sift)

local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local player = Players.LocalPlayer

local TeleportUI = CentralUI.new(player.PlayerGui:WaitForChild "Teleport")

local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

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

	for _, area in self._ui.Background.ScrollingFrame:GetChildren() do
		if not area:IsA "ImageLabel" then
			continue
		end

		area.Teleport.Active = true

		area.Teleport.Activated:Connect(function()
			if area.Locked.Visible or area.CostUI.Visible then
				if selectors.getStat(store:getState(), player.Name, "Gems") < area.Cost.Value then
					return
				end
				confirmationUI({
					AreaName = area.Name,
					Cost = area.Cost.Value,
				}, function()
					Remotes.Client:Get("PurchaseTeleporter"):SendToServer(area.Name)
				end)
				return
			end
			if not player.Character or not player.Character:FindFirstChild "HumanoidRootPart" then
				return
			end
			local goal = getAreaTeleporter(area.Name)
			player.Character:PivotTo(
				CFrame.fromMatrix(
					goal.Position + goal.CFrame.LookVector * 5 + goal.CFrame.UpVector * 5,
					goal.CFrame.RightVector,
					goal.CFrame.UpVector
				)
			)
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
			self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Visible = true
		end
	end
end

function TeleportUI:OnOpen()
	self:Refresh()
end

task.spawn(TeleportUI._initialize, TeleportUI)

return TeleportUI
