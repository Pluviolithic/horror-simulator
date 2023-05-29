local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Client = StarterPlayer.StarterPlayerScripts.Client

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)

return Promise.new(function(resolve)
	local connection = nil
	local currentThread: thread = coroutine.running()

	if selectors.isPlayerLoaded(store:getState(), player.Name) then
		resolve()
		return
	end

	connection = store.changed:connect(function(newState)
		if selectors.isPlayerLoaded(newState, player.Name) then
			connection:disconnect()
			coroutine.resume(currentThread)
		end
	end)

	coroutine.yield()
	resolve()
end)
