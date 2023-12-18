local Players = game:GetService "Players"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local getStatAdjustedMultiplier =
	require(ReplicatedStorage.Common.Utils.Player.MultiplierUtils).getMultiplierAdjustedStat

local originalCFrame = nil
local alreadyRotated = false
local player = Players.LocalPlayer
local BossUI = player.PlayerGui:WaitForChild "BossUI"
local maxFearFromBossPercentage = ReplicatedStorage.Config.Combat.BossFearPercentage.Value

Remotes.Client:Get("SendFightInfo"):Connect(function(info)
	local enemy = selectors.getCurrentTarget(store:getState(), player.Name)
	if not info.IsBoss or not enemy then
		return
	end

	local gemsToDisplay = info.Gems * info.DamageDealtByPlayer / info.MaxHealth
	local fearToDisplay = math.clamp(info.DamageDealtByPlayer, 0, info.MaxHealth * maxFearFromBossPercentage / 100)
	local maxAddon = if fearToDisplay == info.MaxHealth * maxFearFromBossPercentage / 100 then " (Max)" else ""

	if not BossUI.Enabled then
		BossUI.Enabled = true
	end

	gemsToDisplay = getStatAdjustedMultiplier(player, "Gems", gemsToDisplay)
	fearToDisplay = getStatAdjustedMultiplier(player, "Fear", fearToDisplay)

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

	if alreadyRotated then
		return
	end
	alreadyRotated = true

	if not CollectionService:HasTag(enemy, "RotatingBoss") then
		return
	end

	local rootPart = if enemy.Humanoid.RootPart then enemy.Humanoid.RootPart else enemy:FindFirstChild "RootPart"
	local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
	if humanoid and rootPart then
		originalCFrame = rootPart.CFrame
		local tween = TweenService:Create(rootPart, TweenInfo.new(0.3), {
			CFrame = CFrame.lookAt(
				rootPart.Position,
				humanoid.RootPart.Position * Vector3.new(1, 0, 1) + rootPart.Position.Y * Vector3.new(0, 1, 0)
			),
		})
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()
	end
end)

playerStatePromise:andThen(function()
	store.changed:connect(function(newState, oldState)
		local currentEnemy = selectors.getCurrentTarget(newState, player.Name)
		if not currentEnemy and BossUI.Enabled then
			BossUI.Enabled = false
			BossUI.Background.FearCounter.Text = ""
			BossUI.Background.DamageCounter.Text = ""
			BossUI.Background.GemsCounter.Text = ""
			BossUI.Background.Frame.HP.Text = ""
		end

		if not selectors.isPlayerLoaded(oldState, player.Name) then
			return
		end

		local oldEnemy = selectors.getCurrentTarget(oldState, player.Name)
		if
			(not currentEnemy or not CollectionService:HasTag(currentEnemy, "RotatingBoss"))
			and CollectionService:HasTag(oldEnemy, "RotatingBoss")
			and oldEnemy:FindFirstChild "Humanoid"
		then
			local rootPart = if oldEnemy.Humanoid.RootPart
				then oldEnemy.Humanoid.RootPart
				else oldEnemy:FindFirstChild "RootPart"
			if rootPart and originalCFrame then
				local tween = TweenService:Create(rootPart, TweenInfo.new(0.3), { CFrame = originalCFrame })
				tween:Play()
				task.spawn(function()
					tween.Completed:Wait()
					tween:Destroy()
				end)
			end
			alreadyRotated = false
		end
	end)
end)

return 0
