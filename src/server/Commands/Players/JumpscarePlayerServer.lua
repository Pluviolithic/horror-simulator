local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

return function(_, player: Player, name: string)
	if workspace.Jumpscares:FindFirstChild(name) then
		store:dispatch(actions.setPlayerStat(player.Name, "LastScaredTimestamp", os.time()))
		Remotes.Server:Get("JumpscarePlayer"):SendToPlayer(player, name)
	end
end
