local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local bossAttackSpeed = ReplicatedStorage.Config.Combat.BossAttackSpeed.Value
local enemyAttackSpeed = ReplicatedStorage.Config.Combat.EnemyAttackSpeed.Value

local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

return function(enemy, janitor)
	local attackDelay = if CollectionService:HasTag(enemy, "Boss") then bossAttackSpeed else enemyAttackSpeed
	local runAnimations = true

	local animationInstances =
		animationUtilities.filterAndSortAnimationInstances(enemy.Configuration.AttackAnims:GetChildren())
	local currentIndex, animationTrack = 0, nil

	while runAnimations do
		currentIndex, animationTrack =
			animationUtilities.getNextAnimationTrackAndIndex(animationInstances, currentIndex)
		animationTrack.Priority = Enum.AnimationPriority.Action

		animationTrack:Play()
		animationTrack.Stopped:Wait()
		animationTrack:Destroy()
		task.wait(attackDelay)
	end

	janitor:Add(function()
		runAnimations = false
		if animationTrack.IsPlaying then
			animationTrack:Stop()
		end
	end, true)
end
