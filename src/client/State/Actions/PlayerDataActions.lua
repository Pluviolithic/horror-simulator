local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local makeActionCreator = Rodux.makeActionCreator

return {
	incrementPlayerStat = makeActionCreator(
		"incrementPlayerStat",
		function(
			playerName: string,
			statName: string,
			incrementAmount: number,
			source: string?,
			skipMultipliers: boolean?
		)
			return {
				incrementAmount = incrementAmount,
				playerName = playerName,
				statName = statName,
				source = source,
				skipMultipliers = skipMultipliers,
				shouldSave = true,
			}
		end
	),
}
