local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

Remotes.Server:Get("SwitchSetting"):Connect(function(player, setting)
	if type(selectors.getSetting(store:getState(), player.Name, setting)) ~= "boolean" then
		return
	end
	if setting == "2xSpeed" then
		if not selectors.hasGamepass(store:getState(), player.Name, "2xSpeed") then
			return
		end
	elseif setting:match "Vip" then
		if not selectors.hasGamepass(store:getState(), player.Name, "VIP") then
			return
		end
	end
	store:dispatch(actions.switchSetting(player.Name, setting))
end)

return 0
