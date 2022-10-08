local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local reducer = require(StarterPlayer.StarterPlayerScripts.Client.State.Reducer)
local middleware = require(StarterPlayer.StarterPlayerScripts.Client.State.Middleware)

local currentState = Remotes.Client:Get("GetGlobalState"):CallServer()
local store = Rodux.Store.new(reducer, { GameState = currentState }, middleware)

-- resolve server actions on the client
Remotes.Client:Get("SendRoduxAction"):Connect(function(action)
	store:dispatch(action)
end)

return store
