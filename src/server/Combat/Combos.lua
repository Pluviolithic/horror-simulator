local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

Remotes.Server:Get("SetComboMeterLevel"):Connect(function(player, level)
	local levelData = ReplicatedStorage.Config.Combat.ComboLevels:FindFirstChild(tostring(level))
	if not levelData then
		return
	end
	store:dispatch(actions.setPlayerMultiplier(player.Name, "ComboMultiplier", levelData.Multiplier.Value))
end)

return 0
