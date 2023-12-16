local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local random = Random.new()
local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

local function dealDamageToPlayers(enemy, info)
	for _, player in info.EngagedPlayers do
		if not selectors.isPlayerLoaded(store:getState(), player.Name) then
			continue
		end
		if selectors.getActiveBoosts(store:getState(), player.Name)["FearlessBoost"] then
			continue
		end
		local fearMeterGoal = math.min(
			selectors.getStat(store:getState(), player.Name, "CurrentFearMeter") + enemy.Configuration.Damage.Value,
			selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
		)
		local fearMeterAddendum = fearMeterGoal - selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")

		if fearMeterAddendum ~= 0 then
			store:dispatch(actions.incrementPlayerStat(player.Name, "CurrentFearMeter", fearMeterAddendum))
		end
	end
end

return function(enemy, info, janitor)
	if info.AnimationsActive or not enemy:FindFirstChild "Configuration" then
		return
	end
	info.AnimationsActive = true

	local damagePlayers = true
	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local attackDelay = if isBoss then bossAttackSpeed else enemyAttackSpeed

	local sounds = enemy.Hitbox:FindFirstChild "Sounds"

	local animationInstances =
		animationUtilities.filterAndSortAnimationInstances(enemy.Configuration.AttackAnims:GetChildren())
	local currentIndex, animationTrack, animation = 0, nil, nil

	task.spawn(function()
		while damagePlayers and enemy:FindFirstChild "Humanoid" do
			currentIndex, animation = animationUtilities.getNextIndexAndAnimationTrack(animationInstances, currentIndex)
			animationTrack = enemy.Humanoid:LoadAnimation(animation)
			animationTrack.Priority = Enum.AnimationPriority.Action

			animationTrack:Play()

			if sounds then
				for _, sound in sounds:GetChildren() do
					if sound.Name == "Impact" then
						task.delay(sound.Delay.Value - 0.1, function()
							dealDamageToPlayers(enemy, info)
						end)
					end
					task.spawn(function()
						if sound:FindFirstChild "Delay" and sound.Delay.Value ~= 0 then
							task.wait(sound.Delay.Value)
						end
						sound.PlaybackSpeed = random:NextNumber(0.9, 1.1)
						sound:Play()
						if sound:FindFirstChild "Duration" then
							task.wait(sound.Duration.Value)
							sound:Stop()
						end
					end)
				end
			else
				task.delay(0.1, dealDamageToPlayers, enemy, info)
			end

			animationTrack.Stopped:Wait()
			animationTrack:Destroy()
			task.wait(attackDelay)
		end
	end)

	if Janitor.Is(janitor) then
		janitor:Add(function()
			damagePlayers = false
			info.DamageActive = nil
			info.AnimationsActive = nil
			if animationTrack.IsPlaying then
				animationTrack:Stop()
			end
		end, true)
	else
		print "oh dear, we have a problem"
		damagePlayers = false
		info.DamageActive = nil
		info.AnimationsActive = nil
		if animationTrack.IsPlaying then
			animationTrack:Stop()
		end
	end
end
