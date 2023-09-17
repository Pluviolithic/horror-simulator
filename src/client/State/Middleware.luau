local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer
local Rodux = require(ReplicatedStorage.Common.lib.Rodux)
local displayClientLogs = ReplicatedStorage.Config.Output.DisplayClientLogs.Value

local function updateWalkSpeedMiddleware(nextDispatch)
	return function(action)
		if action.playerName ~= player.Name or action.statName ~= "WalkSpeed" then
			return
		end
		local humanoid = if player.Character then player.Character:FindFirstChild "Humanoid" else nil
		if humanoid then
			humanoid.WalkSpeed = action.value
		end
		nextDispatch(action)
	end
end

return {
	updateWalkSpeedMiddleware,
	if displayClientLogs then Rodux.loggerMiddleware else nil,
}
