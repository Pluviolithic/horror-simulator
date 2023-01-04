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

local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

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
			if newState.Players[player.Name].MaxPetCount ~= oldState.Players[player.Name].MaxPetCount then
				self:Refresh()
			end
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
end

function PetInventory:ClearFocusedDisplay() end

function PetInventory:OnOpen()
	self:Refresh()
end

task.spawn(PetInventory._initialize, PetInventory)

return PetInventory
