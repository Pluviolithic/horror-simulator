local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local confirmationUI = require(StarterPlayer.StarterPlayerScripts.Client.Areas.ConfirmationUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local Remotes = require(ReplicatedStorage.Common.Remotes)

local areaRequirements = ReplicatedStorage.Config.AreaRequirements
local player = Players.LocalPlayer

local TeleportUI = CentralUI.new(player.PlayerGui:WaitForChild "Teleport") :: {
	_initialize: () -> (),
	Refresh: () -> (),
} & CentralUI.CentralUI

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
			if newState.Players[player.Name].Strength == oldState.Players[player.Name].Strength then
				return
			end

			self:Refresh()
		end)
	end)

	for _, area in self._ui.Background.ScrollingFrame:GetChildren() do
		if not area:IsA "ImageLabel" then
			continue
		end

		area.Teleport.Activated:Connect(function()
			if area.Locked.Visible or area.CostUI.Visible then
				return
			end
			if not player.Character or not player.Character:FindFirstChild "HumanoidRootPart" then
				return
			end
			local goal = CollectionService:GetTagged(area.Name .. "TP")[1]
			player.Character:PivotTo(
				CFrame.fromMatrix(
					goal.Position + goal.CFrame.LookVector * 5 + goal.CFrame.UpVector * 5,
					goal.CFrame.RightVector,
					goal.CFrame.UpVector
				)
			)
		end)

		area.CostUI.Activated:Connect(function()
			local playerState = store:getState().Players[player.Name]
			if playerState.Gems < area.Cost.Value then
				return
			end
			confirmationUI({
				AreaName = area.Name,
				Cost = area.Cost.Value,
			}, function()
				Remotes.Client:Get("PurchaseTeleporter"):SendToServer(area.Name)
			end)
		end)
	end
end

function TeleportUI:Refresh()
	local playerState = store:getState().Players[player.Name]
	for _, requirement in areaRequirements:GetChildren() do
		if requirement.Value > playerState.Strength then
			self:_unlockArea(requirement.Name, true)
		else
			self:_unlockArea(requirement.Name, false)
		end

		if playerState.PurchasedTeleporters[requirement.Name] then
			self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Visible = false
		else
			self._ui.Background.ScrollingFrame[requirement.Name].CostUI.Visible = true
		end
	end
end

task.spawn(TeleportUI._initialize, TeleportUI)

return TeleportUI
