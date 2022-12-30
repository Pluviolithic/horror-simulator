local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

return Promise.new(function(resolve)
	local connection: typeof(store.changed:connect(function() end)) = nil
	local currentThread: thread = coroutine.running()

	if store:getState().Players[player.Name] and next(store:getState().Players[player.Name]) then
		resolve(store:getState().Players[player.Name])
		return
	end

	connection = store.changed:connect(function(newState)
		if newState.Players[player.Name] and next(newState.Players[player.Name]) then
			connection:disconnect()
			coroutine.resume(currentThread)
		end
	end)

	coroutine.yield()
	resolve()
end)
