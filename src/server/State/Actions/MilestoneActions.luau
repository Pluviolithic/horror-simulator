local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	achievedMilestone = makeActionCreator("achievedMilestone", function(playerName: string, milestone: string)
		return {
			playerName = playerName,
			milestone = milestone,
			shouldSave = true,
		}
	end),
	removeMilestone = makeActionCreator("removeMilestone", function(playerName: string, milestone: string)
		return {
			playerName = playerName,
			milestone = milestone,
			shouldSave = true,
		}
	end),
}
