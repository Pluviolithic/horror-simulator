local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

local random = Random.new()
local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

return function(enemy, info, janitor)
	if info.AnimationsActive then
		return
	end
	info.AnimationsActive = true

	local isBoss = CollectionService:HasTag(enemy, "Boss")
	local attackDelay = if isBoss then bossAttackSpeed else enemyAttackSpeed
	local runAnimations = true

	local animationInstances =
		animationUtilities.filterAndSortAnimationInstances(enemy.Configuration.AttackAnims:GetChildren())
	local currentIndex, animationTrack, animation = 0, nil, nil

	task.spawn(function()
		while runAnimations do
			currentIndex, animation = animationUtilities.getNextIndexAndAnimationTrack(animationInstances, currentIndex)
			animationTrack = enemy.Humanoid:LoadAnimation(animation)
			animationTrack.Priority = Enum.AnimationPriority.Action

			animationTrack:Play()

			if isBoss then
				for _, sound in enemy.Hitbox.Sounds:GetChildren() do
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
			end

			animationTrack.Stopped:Wait()
			animationTrack:Destroy()
			task.wait(attackDelay)
		end
	end)

	janitor:Add(function()
		runAnimations = false
		info.AnimationsActive = nil
		if animationTrack.IsPlaying then
			animationTrack:Stop()
		end
	end, true)
end
