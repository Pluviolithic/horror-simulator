local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local player = Players.LocalPlayer
local connections: { [string]: RBXScriptConnection } = {}

local areaRequirements = ReplicatedStorage.Config.AreaRequirements

local function unlockArea(areaName)
	if connections[areaName] then
		return
	end

	CollectionService:GetInstanceAddedSignal(areaName .. "Barrier"):Connect(function(barrier)
		barrier:Destroy()
	end)

	for _, barrier in CollectionService:GetTagged(areaName .. "Barrier") do
		barrier:Destroy()
	end
end

local function unlockAreas(state)
	for _, requirement in areaRequirements:GetChildren() do
		if requirement.Value <= state.Strength then
			unlockArea(requirement.Name)
		end
	end
end

playerStatePromise:andThen(function()
	local playerState = store:getState().Players[player.Name]

	unlockAreas(playerState)

	store.changed:connect(function(newState, oldState)
		if newState.Players[player.Name].Strength == oldState.Players[player.Name].Strength then
			return
		end

		unlockAreas(newState.Players[player.Name])
	end)
end)

return 0
