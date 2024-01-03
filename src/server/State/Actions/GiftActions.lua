local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	claimGift = makeActionCreator("claimGift", function(playerName: string, giftName: string)
		return {
			playerName = playerName,
			giftName = giftName,
			shouldSave = true,
		}
	end),
}
