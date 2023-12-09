local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local combatAnimations = ReplicatedStorage.CombatAnimations

local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

return function(player, janitor)
	local runAnimations = true

	local currentIndex, animationTrack, animation = 0, nil, nil
	local idleAnimation = combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)].Idle
	local animationInstances = animationUtilities.filterAndSortAnimationInstances(
		combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)]:GetChildren()
	)

	local loadedIdleAnimation = player.Character.Humanoid:LoadAnimation(idleAnimation)
	loadedIdleAnimation.Priority = Enum.AnimationPriority.Idle

	task.spawn(function()
		while runAnimations do
			currentIndex, animation = animationUtilities.getNextIndexAndAnimationTrack(animationInstances, currentIndex)
			animationTrack = player.Character.Humanoid:LoadAnimation(animation)
			animationTrack.Priority = Enum.AnimationPriority.Action

			animationTrack:Play()
			animationTrack.Stopped:Wait()
			animationTrack:Destroy()

			loadedIdleAnimation:Play()

			task.wait(animationUtilities.getPlayerAttackSpeed(player))

			loadedIdleAnimation:Stop()
		end
	end)

	janitor:Add(function()
		runAnimations = false
		if loadedIdleAnimation.IsPlaying then
			loadedIdleAnimation:Stop()
		end
		loadedIdleAnimation:Destroy()
		if animationTrack.IsPlaying then
			task.spawn(function()
				animationTrack.Stopped:Wait()
				animationTrack:Destroy()
			end)
		end
	end, true)
end
