local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local trackedPlayers = {}

local function isScared(playerName, state)
	if not selectors.isPlayerLoaded(state, playerName) then
		return false
	end
	if selectors.getActiveBoosts(state, playerName)["FearlessBoost"] then
		if selectors.getStat(state, playerName, "CurrentFearMeter") ~= 0 then
			store:dispatch(actions.setPlayerStat(playerName, "CurrentFearMeter", 0))
		end
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

local defaultWalkSpeed = 14
local walkSpeedFearDebuff = -4
store.changed:connect(function(newState, oldState)
	for _, player in Players:GetPlayers() do
		local hasPass = selectors.hasGamepass(newState, player.Name, "2xSpeed")
		local modifiedDebuff = walkSpeedFearDebuff * (hasPass and 2 or 1)
		local newWalkSpeed = defaultWalkSpeed * (hasPass and 2 or 1)
		if isScared(player.Name, newState) then
			task.spawn(trackPlayerScaredStatus, player)
			newWalkSpeed += modifiedDebuff
		elseif isScared(player.Name, oldState) then
			newWalkSpeed -= modifiedDebuff
		end
		local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
		if humanoid and humanoid.WalkSpeed ~= newWalkSpeed then
			humanoid.WalkSpeed = newWalkSpeed
		end
		if
			selectors.isPlayerLoaded(oldState, player.Name)
			and selectors.hasGamepass(newState, player.Name, "2xFearMeter")
			and not selectors.hasGamepass(oldState, player.Name, "2xFearMeter")
		then
			store:dispatch(actions.setPlayerStat(player.Name, "CurrentFearMeter", 0))
		end
	end
end)

return 0
