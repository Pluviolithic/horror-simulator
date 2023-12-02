local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local player = Players.LocalPlayer
local BossUI = player.PlayerGui:WaitForChild "BossUI"
local maxFearFromBossPercentage = ReplicatedStorage.Config.Combat.BossFearPercentage.Value

Remotes.Client:Get("SendFightInfo"):Connect(function(info)
	local fearMultiplier = selectors.getMultiplierData(store:getState(), player.Name).FearMultiplier
	local fearMultiplierCount = selectors.getMultiplierData(store:getState(), player.Name).FearMultiplierCount
	local fearBoostData = selectors.getActiveBoosts(store:getState(), player.Name).FearBoost
	local fearToDisplay = math.clamp(info.DamageDealtByPlayer, 0, info.MaxHealth * maxFearFromBossPercentage)

	if fearMultiplierCount < 1 then
		fearToDisplay *= (1 + fearMultiplier) * (fearBoostData and 2 or 1)
	else
		fearToDisplay *= fearMultiplier * (fearBoostData and 2 or 1)
	end

	BossUI.Background.Frame.HP.Text = formatter.formatNumberWithCommas(info.Health)
	BossUI.Background.FearCounter.Text = formatter.formatNumberWithSuffix(fearToDisplay)
	BossUI.Background.DamageCounter.Text = formatter.formatNumberWithSuffix(info.DamageDealtByPlayer)
	BossUI.Background.GemsCounter.Text =
		formatter.formatNumberWithSuffix(info.Gems * info.DamageDealtByPlayer / info.MaxHealth)
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

	if CollectionService:HasTag(currentEnemy, "Boss") and not BossUI.Enabled then
		BossUI.Enabled = true
	end
end)

return 0
