local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local function isScared(player, state)
	return selectors.getStat(state, player.Name, "CurrentFearMeter")
			== selectors.getStat(state, player.Name, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, player.Name, "LastScaredTimestamp")) < 121
end

local function trackPlayerScaredStatus(player)
	repeat
		task.wait(0.25)
	until not isScared(player, store:getState())

	if
		selectors.getStat(store:getState(), player.Name, "CurrentFearMeter")
		== selectors.getStat(store:getState(), player.Name, "MaxFearMeter")
	then
		store:dispatch(actions.setPlayerStat(player.Name, "CurrentFearMeter", 0))
	end
end

store.changed:connect(function(newState, oldState)
	for _, player in Players:GetPlayers() do
		if not selectors.isPlayerLoaded(newState, player) or not selectors.isPlayerLoaded(oldState, player) then
			continue
		end

		if isScared(player, newState) and not isScared(player, oldState) then
			task.spawn(trackPlayerScaredStatus, newState)
		end
	end
end)

return 0
