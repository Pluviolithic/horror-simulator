local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

Remotes.Server:Get("SwitchSetting"):Connect(function(player, setting)
	store:dispatch(actions.switchSetting(player.Name, setting))
end)

return 0
