local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

Remotes.Server:Get("IncrementTutorialStep"):Connect(function(player)
	if selectors.getTutorialStep(store:getState(), player.Name) < 11 then
		store:dispatch(actions.incrementTutorialStep(player.Name))
	end
end)

Remotes.Server:Get("SetTutorialFearMeterPercent"):Connect(function(player, amount)
	if (amount == 0 or amount == 0.98) and selectors.getTutorialStep(store:getState(), player.Name) == 3 then
		store:dispatch(
			actions.setPlayerStat(
				player.Name,
				"CurrentFearMeter",
				amount * selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
			)
		)
		if amount == 0 then
			store:dispatch(actions.setPlayerStat(player.Name, "LastScaredTimestamp", -1))
		end
	end
end)

return 0
