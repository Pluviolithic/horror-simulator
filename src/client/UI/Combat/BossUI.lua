local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local player = Players.LocalPlayer
local BossUI = player.PlayerGui:WaitForChild "BossUI"
local maxFearFromBossPercentage = ReplicatedStorage.Config.Combat.BossFearPercentage.Value

Remotes.Client:Get("SendFightInfo"):Connect(function(info)
	if not info.IsBoss then
		return
	end

	local gemsMultiplier = selectors.getMultiplierData(store:getState(), player.Name).GemsMultiplier
	local gemsMultiplierCount = selectors.getMultiplierData(store:getState(), player.Name).GemsMultiplierCount or 0
	local gemsBoostData = selectors.getActiveBoosts(store:getState(), player.Name).GemsBoost
	local gemsToDisplay = info.Gems * info.DamageDealtByPlayer / info.MaxHealth

	local fearMultiplier = selectors.getMultiplierData(store:getState(), player.Name).FearMultiplier
	local fearMultiplierCount = selectors.getMultiplierData(store:getState(), player.Name).FearMultiplierCount or 0
	local fearBoostData = selectors.getActiveBoosts(store:getState(), player.Name).FearBoost
	local fearToDisplay = math.clamp(info.DamageDealtByPlayer, 0, info.MaxHealth * maxFearFromBossPercentage / 100)
	local maxAddon = if fearToDisplay == info.MaxHealth * maxFearFromBossPercentage / 100 then " (Max)" else ""

	if not BossUI.Enabled then
		BossUI.Enabled = true
	end

	if fearMultiplierCount < 1 then
		fearToDisplay *= (1 + fearMultiplier) * (fearBoostData and 2 or 1)
	else
		fearToDisplay *= fearMultiplier * (fearBoostData and 2 or 1)
	end

	if gemsMultiplierCount < 1 then
		gemsToDisplay *= (1 + gemsMultiplier) * (gemsBoostData and 2 or 1)
	else
		gemsToDisplay *= gemsMultiplier * (gemsBoostData and 2 or 1)
	end

	BossUI.Background.Frame.Health:TweenSize(
		UDim2.fromScale(1.013 * info.Health / info.MaxHealth, 1.104),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.5,
		true
	)
	BossUI.Background.Frame.HP.Text = formatter.formatNumberWithCommas(info.Health)
	BossUI.Background.FearCounter.Text = "Fear: " .. formatter.formatNumberWithSuffix(fearToDisplay) .. maxAddon
	BossUI.Background.DamageCounter.Text = "Damage: " .. formatter.formatNumberWithSuffix(info.DamageDealtByPlayer)
	BossUI.Background.GemsCounter.Text = "Gems: " .. formatter.formatNumberWithSuffix(gemsToDisplay)
end)

store.changed:connect(function(newState)
	local currentEnemy = selectors.getCurrentTarget(newState, player.Name)
	if not currentEnemy and BossUI.Enabled then
		BossUI.Enabled = false
		BossUI.Background.FearCounter.Text = ""
		BossUI.Background.DamageCounter.Text = ""
		BossUI.Background.GemsCounter.Text = ""
		BossUI.Background.Frame.HP.Text = ""
	end
end)

return 0
