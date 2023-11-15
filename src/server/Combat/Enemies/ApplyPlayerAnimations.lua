local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local combatAnimations = ReplicatedStorage.CombatAnimations

local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local animationUtilities = require(ReplicatedStorage.Common.Utils.AnimationUtils)

return function(player, janitor)
	local runAnimations = true

	local currentIndex, animationTrack = 0, nil
	local animationInstances = animationUtilities.filterAndSortAnimationInstances(
		combatAnimations[selectors.getEquippedWeapon(store:getState(), player.Name)]:GetChildren()
	)

	task.spawn(function()
		while runAnimations do
			currentIndex, animationTrack =
				animationUtilities.getNextAnimationTrackAndIndex(animationInstances, currentIndex)
			animationTrack.Priority = Enum.AnimationPriority.Action

			animationTrack:Play()
			animationTrack.Stopped:Wait()
			animationTrack:Destroy()
			task.wait(animationUtilities.getPlayerAttackSpeed(player))
		end
	end)

	janitor:Add(function()
		runAnimations = false
		if animationTrack.IsPlaying then
			animationTrack:Stop()
		end
	end, true)
end
