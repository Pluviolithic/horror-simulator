local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	switchSetting = makeActionCreator("switchSetting", function(playerName: string, setting: string)
		return {
			setting = setting,
			playerName = playerName,
			shouldSave = true,
		}
	end),
}
