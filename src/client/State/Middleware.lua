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
				if equippedWeapon then
					player.Character.Animate.idle.Animation1.AnimationId =
						ReplicatedStorage.CombatAnimations[equippedWeapon].Idle.AnimationId
				end
			elseif originalAnimationId then
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
