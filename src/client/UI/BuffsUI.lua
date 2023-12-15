local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local RobuxShop = require(StarterPlayer.StarterPlayerScripts.Client.UI.Shops.RobuxShop)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer

local buffTray = player.PlayerGui:WaitForChild "Buffs"
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

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
		if activeBoosts[buffDisplay.Name] then
			buffDisplay.Timer.Text = clockUtils.getFormattedRemainingTime(
				activeBoosts[buffDisplay.Name].StartTime,
				activeBoosts[buffDisplay.Name].Duration
			)
			buffDisplay.Visible = true
		elseif buffDisplay.Visible then
			buffDisplay.Visible = false

			local multiplierAmount = "2x "
			if buffDisplay.Name:match "Luck" then
				multiplierAmount = "5x "
			elseif buffDisplay.Name:match "Fearless" then
				multiplierAmount = ""
			end

			PopupUI(`{multiplierAmount}{buffDisplay.Name:match "(%u.+)%u"} Boost Has Expired!`)
		end
	end
end

for _, buffDisplay in buffTray.Frame:GetChildren() do
	if not buffDisplay:IsA "GuiButton" then
		continue
	end

	DescriptionUI(buffDisplay, buffDisplay.Frame)

	if not buffDisplay.Name:match "Boost" then
		continue
	end
	buffDisplay.Activated:Connect(function()
		playSoundEffect "UIButton"
		RobuxShop:OpenSubShop "Boosts"
	end)
end

buffTray.Frame.DamageDebuff.Activated:Connect(function()
	playSoundEffect "UIButton"
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xAttackSpeed"].Value)
end)

buffTray.Frame.SpeedDebuff.Activated:Connect(function()
	playSoundEffect "UIButton"
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xSpeed"].Value)
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
