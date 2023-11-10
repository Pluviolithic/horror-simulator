local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)

return function(nextDispatch, store)
	return function(action)
		nextDispatch(action)
		if not action.playerName or not selectors.isPlayerLoaded(store:getState(), action.playerName) then
			return
		end

		local player = Players:FindFirstChild(action.playerName)

		if not player then
			return
		end

		local leaderstats = player:FindFirstChild "leaderstats"

		if leaderstats then
			for _, stat in pairs(leaderstats:GetChildren()) do
				stat.Value =
					formatter.formatNumberWithSuffix(selectors.getStat(store:getState(), player.Name, stat.Name))
			end
		end
	end
end
