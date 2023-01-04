-- deprecated
local RunService = game:GetService "RunService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Sift = require(ReplicatedStorage.Common.lib.Sift)

local store
if RunService:IsServer() then
	store = require(ServerScriptService.Server.State.Store)
else
	store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
end

local StateChecks = {}

function StateChecks:SumValues(player, category)
	local playerState = store:getState().Players[player.Name]
	return Sift.Array.reduce(Sift.Dictionary.values(playerState[category]), function(acc, ownedCount)
		return acc + ownedCount
	end, 0)
end

function StateChecks:HasSpace(player, category, amount, max)
	return self:SumValues(player, category) + amount <= max
end

return StateChecks
