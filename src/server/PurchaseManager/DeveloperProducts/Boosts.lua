local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)

Remotes.Server:Get("UseBoost"):Connect(function(player, boostName)
	if selectors.getBoostCount(store:getState(), player.Name, boostName) < 1 then
		return
	end
	store:dispatch(actions.incrementPlayerBoostCount(player.Name, boostName, -1))
	store:dispatch(actions.applyBoostToPlayer(player.Name, boostName))
end)

task.spawn(function()
	while true do
		local currentState = store:getState()
		for _, player in Players:GetPlayers() do
			if not selectors.isPlayerLoaded(currentState, player.Name) then
				continue
			end
			local activeBoosts = selectors.getActiveBoosts(currentState, player.Name)

			for boostName, boostData in activeBoosts do
				if not clockUtils.hasTimeLeft(boostData.StartTime, boostData.Duration) then
					store:dispatch(actions.removeBoostFromPlayer(player.Name, boostName))
				end
			end
		end
		task.wait(1)
	end
end)

return 0
