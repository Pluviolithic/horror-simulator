local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

return function(enemy, info, janitor)
	if info.AnimationsActive then
		return
	end
	info.AnimationsActive = true

	local attackDelay = if CollectionService:HasTag(enemy, "Boss") then bossAttackSpeed else enemyAttackSpeed
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
