local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Client = StarterPlayer.StarterPlayerScripts.Client
local player = Players.LocalPlayer

local playerStatePromise = require(Client.State.PlayerStatePromise)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local store = require(Client.State.Store)

Promise.new(function(resolve)
	local requiredFearUI: TextLabel = CollectionService:GetTagged("RequiredFear")[1]
	if not requiredFearUI then
		requiredFearUI = CollectionService:GetInstanceAddedSignal("RequiredFear"):Wait()
	end
	resolve(requiredFearUI)
end):andThen(function(requiredFearUI)
	playerStatePromise:andThen(function()
		requiredFearUI.Text = store:getState().Players[player.Name].Strength * 5
		store.changed:connect(function(newState)
			requiredFearUI.Text = newState.Players[player.Name].Strength * 5
		end)
	end)
end)

return 0
