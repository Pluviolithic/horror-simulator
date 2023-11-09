local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)

local doubleSpeedGamepassID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xSpeed"].Value)

return function(nextDispatch, store)
	return function(action)
		local oldWalkSpeed, newWalkSpeed
		if selectors.isPlayerLoaded(store:getState(), action.playerName) then
			oldWalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
		end
		nextDispatch(action)
		if selectors.isPlayerLoaded(store:getState(), action.playerName) then
			newWalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
		else
			return
		end
		local player = Players[action.playerName]
		local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
		if humanoid and oldWalkSpeed ~= newWalkSpeed then
			humanoid.WalkSpeed = selectors.getStat(store:getState(), action.playerName, "WalkSpeed")
			if selectors.hasGamepass(store:getState(), action.playerName, doubleSpeedGamepassID) then
				humanoid.WalkSpeed *= 2
			end
		end
	end
end
