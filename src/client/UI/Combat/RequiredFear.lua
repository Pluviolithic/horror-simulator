local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local client = StarterPlayer.StarterPlayerScripts.Client
local player = Players.LocalPlayer

local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(client.State.Store)

Promise.new(function(resolve)
	local requiredFearUI = CollectionService:GetTagged("RequiredFear")[1]
	if not requiredFearUI then
		requiredFearUI = CollectionService:GetInstanceAddedSignal("RequiredFear"):Wait()
	end

	local connection
	local currentThread = coroutine.running()
	connection = store.changed:connect(function(newState)
		if newState.GameState.Players[player.Name] then
			connection:disconnect()
			coroutine.resume(currentThread)
		end
	end)

	coroutine.yield()
	resolve(requiredFearUI)
end):andThen(function(requiredFearUI)
	requiredFearUI.Text = store:getState().GameState.Players[player.Name].Strength * 5
	store.changed:connect(function(newState)
		requiredFearUI.Text = newState.GameState.Players[player.Name].Strength * 5
	end)
end)

return 0
