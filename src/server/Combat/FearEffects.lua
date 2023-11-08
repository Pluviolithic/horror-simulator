local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local doubleFearMeterGamepassID = tostring(ReplicatedStorage.Config.Gamepasses.DoubleFearMeter.Value)
local trackedPlayers = {}

local function isScared(playerName, state)
	if not selectors.isPlayerLoaded(state, playerName) then
		return false
	end
	return selectors.getStat(state, playerName, "CurrentFearMeter")
			== selectors.getStat(state, playerName, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, playerName, "LastScaredTimestamp")) < 121
end

local function trackPlayerScaredStatus(player)
	local playerName = player.Name
	if trackedPlayers[player] then
		return
	end
	trackedPlayers[player] = true

	repeat
		task.wait(0.25)
	until not selectors.isPlayerLoaded(store:getState(), playerName) or not isScared(playerName, store:getState())

	if
		selectors.isPlayerLoaded(store:getState(), playerName)
		and selectors.getStat(store:getState(), playerName, "CurrentFearMeter")
			== selectors.getStat(store:getState(), playerName, "MaxFearMeter")
	then
		store:dispatch(actions.setPlayerStat(playerName, "CurrentFearMeter", 0))
	end

	trackedPlayers[player] = nil
end

store.changed:connect(function(newState, oldState)
	for _, player in Players:GetPlayers() do
		if isScared(player.Name, newState) then
			task.spawn(trackPlayerScaredStatus, player)
			if not isScared(player.Name, oldState) then
				store:dispatch(actions.incrementPlayerStat(player.Name, "WalkSpeed", -4))
			end
		elseif isScared(player.Name, oldState) then
			store:dispatch(actions.incrementPlayerStat(player.Name, "WalkSpeed", 4))
		end
		-- if player has bought the 2x fear meter, reset their fear meter
		if
	end
end)

return 0
