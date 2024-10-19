local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)

-- https://zerowidthspace.me/
local zeroWidthSpace = "​"

return function(nextDispatch, store)
	return function(action)
		nextDispatch(action)
		if not action.playerName or not selectors.isPlayerLoaded(store:getState(), action.playerName) then
			return
		end

		local actionPlayer = Players:FindFirstChild(action.playerName)

		if not actionPlayer then
			return
		end

		local leaderstats = actionPlayer:FindFirstChild "leaderstats"

		if leaderstats then
			for _, stat in leaderstats:GetChildren() do
				stat.Value =
					formatter.formatNumberWithSuffix(selectors.getStat(store:getState(), actionPlayer.Name, stat.Name))
			end

			local playerStrengthInfo = {}
			for _, player in Players:GetPlayers() do
				if not player:FindFirstChild "leaderstats" then
					continue
				end

				local strength = selectors.getStat(store:getState(), player.Name, "Strength")
				table.insert(playerStrengthInfo, {
					Strength = strength,
					StrengthStat = player.leaderstats.Strength,
					FormattedStrength = formatter.formatNumberWithSuffix(strength),
				})
			end
			table.sort(playerStrengthInfo, function(a, b)
				return a.Strength < b.Strength
			end)
			for index, info in ipairs(playerStrengthInfo) do
				info.StrengthStat.Value = `{zeroWidthSpace:rep(index - 1)}{info.FormattedStrength}`
			end
		end
	end
end
