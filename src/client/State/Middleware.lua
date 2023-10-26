local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local displayClientLogs = ReplicatedStorage.Config.Output.DisplayClientLogs.Value
local doubleSpeedGamepassID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xSpeed"].Value)

local function updateWalkSpeedMiddleware(nextDispatch, store)
	return function(action)
		local oldWalkSpeed, newWalkSpeed
		if selectors.isPlayerLoaded(store:getState(), player.Name) then
			oldWalkSpeed = selectors.getStat(store:getState(), player.Name, "WalkSpeed")
		end
		nextDispatch(action)
		if selectors.isPlayerLoaded(store:getState(), player.Name) then
			newWalkSpeed = selectors.getStat(store:getState(), player.Name, "WalkSpeed")
		end
		local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
		if humanoid and oldWalkSpeed ~= newWalkSpeed then
			humanoid.WalkSpeed = selectors.getStat(store:getState(), player.Name, "WalkSpeed")
			if selectors.hasGamepass(store:getState(), player.Name, doubleSpeedGamepassID) then
				humanoid.WalkSpeed *= 2
			end
		end
	end
end

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
	updateWalkSpeedMiddleware,
	updateIdleAnimationMiddleware,
	if displayClientLogs then Rodux.loggerMiddleware else nil,
}
