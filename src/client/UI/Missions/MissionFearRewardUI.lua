local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"

local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local player = Players.LocalPlayer

return CentralUI.new(player.PlayerGui:WaitForChild "MissionFearReward")
