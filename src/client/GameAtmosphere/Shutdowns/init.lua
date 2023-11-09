local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local shutdownUI = ReplicatedFirst:WaitForChild "ShutdownMessage"
local PlayerGui = Players.LocalPlayer:WaitForChild "PlayerGui"
local Remotes = require(ReplicatedStorage.Common.Remotes)

shutdownUI.Parent = PlayerGui
Remotes.Client:Get("NotifyOfShutdown"):Connect(function()
	shutdownUI.Enabled = true
end)

return 0
