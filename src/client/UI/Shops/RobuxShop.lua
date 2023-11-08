local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Table = require(ReplicatedStorage.Common.Utils.Table)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)

local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local RobuxShop = CentralUI.new(player.PlayerGui:WaitForChild "RobuxShop")
local mainUI = player.PlayerGui:WaitForChild "MainUI"

RobuxShop.Trigger = "RobuxShop"

function RobuxShop:_closeFramesWithExclude(exclude)
	for _, frame in self._ui.Background:GetChildren() do
		if frame ~= exclude and self._ui:FindFirstChild(frame.Name:match "(%a+)Frame") then
			frame.Visible = false
		end
	end
end

function RobuxShop:_initialize(): ()
	mainUI.RobuxShop.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	self._ui.Boosts.Activated:Connect(function()
		self._ui.Background.BoostsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.BoostsFrame)
	end)

	self._ui.Fear.Activated:Connect(function()
		self._ui.Background.FearFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.FearFrame)
	end)

	self._ui.Gamepasses.Activated:Connect(function()
		self._ui.Background.GamepassesFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GamepassesFrame)
	end)

	self._ui.Gems.Activated:Connect(function()
		self._ui.Background.GemsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.GemsFrame)
	end)

	self._ui.Pets.Activated:Connect(function()
		self._ui.Background.PetsFrame.Visible = true
		self:_closeFramesWithExclude(self._ui.Background.PetsFrame)
	end)

    for _, buttonDisplay in self._ui.Background.GamepassesFrame:GetChildren() do
        local gamepassIDInstance = gamepassIDs:FindFirstChild(button.Name)
        if gamepassIDInstance then
            buttonDisplay.Purchase.Activated:Connect(function()
                MarketplaceService:PromptGamePassPurchase(player, gamepassIDInstance.Value)
            end)
        end
    end
end

task.spawn(RobuxShop._initialize, RobuxShop)

return RobuxShop
