local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local playerAttackSpeed = ReplicatedStorage.Config.Combat.PlayerAttackSpeed.Value
local doubleAttackSpeedID = tostring(ReplicatedStorage.Config.GamepassData.IDs["2xAttackSpeed"].Value)

local animationUtilities
animationUtilities = {
	removeIdleFromAnimationList = function(animationInstances)
		for i, animationInstance in animationInstances do
			if animationInstance.Name == "Idle" then
				table.remove(animationInstances, i)
				break
			end
		end
	end,
	sortAnimationListByName = function(animationInstances)
		table.sort(animationInstances, function(a, b)
			return tonumber(a.Name:match "%d+") < tonumber(b.Name:match "%d+")
		end)
	end,
	filterAndSortAnimationInstances = function(animationInstances)
		animationUtilities.removeIdleFromAnimationList(animationInstances)
		animationUtilities.sortAnimationListByName(animationInstances)
		return animationInstances
	end,
	getNextIndexAndAnimationTrack = function(animationInstances, currentIndex)
		currentIndex = (currentIndex % #animationInstances) + 1
		return currentIndex, animationInstances[currentIndex]:Clone()
	end,
	getPlayerAttackSpeed = function(player)
		if not selectors.isPlayerLoaded(store:getState(), player.Name) then
			return playerAttackSpeed
		end
		local multiplier = 1
		if selectors.hasGamepass(store:getState(), player.Name, doubleAttackSpeedID) then
			multiplier /= 2
		end
		if selectors.getActiveBoosts(store:getState(), player.Name)["DamageBoost"] then
			multiplier /= 2
		end
		if
			selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
			== selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
		then
			multiplier *= 2
		end
		return playerAttackSpeed * multiplier
	end,
}

return animationUtilities
