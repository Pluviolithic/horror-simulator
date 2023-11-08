local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local displayClientLogs = ReplicatedStorage.Config.Output.DisplayClientLogs.Value
local originalAnimationId

local function updateIdleAnimationMiddleware(nextDispatch, store)
	return function(action)
		if
			action.playerName ~= player.Name
			or (action.type ~= "switchPlayerEnemy" and action.type ~= "setCurrentPunchingBag")
		then
			nextDispatch(action)
			return
		end

		if player.Character then
			if action.enemy or action.currentPunchingBag then
				if not originalAnimationId then
					originalAnimationId = player.Character.Animate.idle.Animation1.AnimationId
				end
				local equippedWeapon = selectors.getEquippedWeapon(store:getState(), player.Name)
				if equippedWeapon and not action.currentPunchingBag then
					player.Character.Animate.idle.Animation1.AnimationId =
						ReplicatedStorage.CombatAnimations[equippedWeapon].Idle.AnimationId
				else
					player.Character.Animate.idle.Animation1.AnimationId =
						ReplicatedStorage.CombatAnimations.Fists.Idle.AnimationId
				end
			elseif originalAnimationId then
				local humanoid = player.Character and player.Character:FindFirstChild "Humanoid"
				if humanoid then
					for _, animationTrack in player.Character.Humanoid.Animator:GetPlayingAnimationTracks() do
						if animationTrack.Priority == Enum.AnimationPriority.Idle then
							animationTrack:Stop()
						end
					end
				end
				player.Character.Animate.idle.Animation1.AnimationId = originalAnimationId
			end
		end
		nextDispatch(action)
	end
end

return {
	updateIdleAnimationMiddleware,
	if displayClientLogs then Rodux.loggerMiddleware else nil,
}
