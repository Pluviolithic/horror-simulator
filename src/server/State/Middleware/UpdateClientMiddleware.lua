local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Enum = require(ReplicatedStorage.Common.Utils.Enum)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local replicationRules = require(ServerScriptService.Server.State.ReplicationRules)

return function(nextDispatch)
	return function(action)
		local replicationRule = replicationRules[action.type]
		if replicationRule == Enum.ReplicationRules.All or not action.playerName then
			Remotes.Server:Get("SendRoduxAction"):SendToAllPlayers(action)
		elseif replicationRule ~= Enum.ReplicationRules.None then
			if Players:FindFirstChild(action.playerName) then
				Remotes.Server:Get("SendRoduxAction"):SendToPlayer(Players[action.playerName], action)
			end
		end
		nextDispatch(action)
	end
end
