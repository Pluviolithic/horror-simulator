local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

return Promise.new(function(resolve)
	local connection
	local currentThread = coroutine.running()

	if store:getState().GameState.Players[player.Name] then
		resolve(store:getState().GameState.Players[player.Name])
		return
	end

	connection = store.changed:connect(function(newState)
		if newState.GameState.Players[player.Name] then
			connection:disconnect()
			coroutine.resume(currentThread)
		end
	end)

	coroutine.yield()
	resolve(store:getState().GameState.Players[player.Name])
end)
