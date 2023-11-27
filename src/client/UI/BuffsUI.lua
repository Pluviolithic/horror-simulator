local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local buffTray = player.PlayerGui:WaitForChild "Buffs"
local productIDs = ReplicatedStorage.Config.DevProductData.IDs

local function updateBuffTray(state)
	local activeBoosts = selectors.getActiveBoosts(state, player.Name)
	for _, buffDisplay in buffTray.Frame:GetChildren() do
		if buffDisplay.Name:match "Buff" then
			continue
		end
		buffDisplay.Timer.Text = clockUtils.getFormattedRemainingTime(
			activeBoosts[buffDisplay.Name].StartTime,
			activeBoosts[buffDisplay.Name].Duration
		)
		if activeBoosts[buffDisplay.Name] then
			buffDisplay.Visible = true
		else
			buffDisplay.Visible = false
		end
	end
end

buffTray.Frame.DamageDebuff.Activated:Connect(function()
	MarketplaceService:PromptProductPurchase(player, productIDs["2xAttackSpeed"].Value)
end)

buffTray.Frame.SpeedDebuff.Activated:Connect(function()
	MarketplaceService:PromptProductPurchase(player, productIDs["2xSpeed"].Value)
end)

playerStatePromise:andThen(function()
	updateBuffTray(store:getState())
	store.changed:connect(updateBuffTray)
	while true do
		task.wait(1)
		updateBuffTray(store:getState())
	end
end)

return 0
