local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local RobuxShop = require(StarterPlayer.StarterPlayerScripts.Client.UI.Shops.RobuxShop)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local buffTray = player.PlayerGui:WaitForChild "Buffs"
local productIDs = ReplicatedStorage.Config.DevProductData.IDs

local function isScared(state)
	if selectors.getActiveBoosts(state, player.Name)["FearlessBoost"] then
		return false
	end
	return selectors.getStat(state, player.Name, "CurrentFearMeter")
			== selectors.getStat(state, player.Name, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, player.Name, "LastScaredTimestamp")) < 121
end

local function updateBuffTray(state)
	local activeBoosts = selectors.getActiveBoosts(state, player.Name)
	for _, buffDisplay in buffTray.Frame:GetChildren() do
		if not buffDisplay.Name:match "Boost" then
			if buffDisplay:IsA "GuiButton" then
				buffDisplay.Visible = isScared(state)
				buffDisplay.Timer.Text = clockUtils.getFormattedRemainingTime(
					selectors.getStat(state, player.Name, "LastScaredTimestamp"),
					120
				)
			end
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

for _, buffDisplay in buffTray.Frame:GetChildren() do
	buffDisplay.MouseEnter:Connect(function()
		if not UserInputService.MouseEnabled then
			return
		end
		buffDisplay.Description.Visible = true
	end)

	buffDisplay.MouseLeave:Connect(function()
		if not UserInputService.MouseEnabled then
			return
		end
		buffDisplay.Description.Visible = false
	end)

	if not buffDisplay.Name:match "Boost" then
		continue
	end
	buffDisplay.Activated:Connect(function()
		RobuxShop:OpenSubShop "Boosts"
	end)
end

playerStatePromise:andThen(function()
	updateBuffTray(store:getState())
	store.changed:connect(updateBuffTray)
	while true do
		task.wait(1)
		updateBuffTray(store:getState())
	end
end)

return 0
