local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local playerControls = require(player.PlayerScripts:WaitForChild "PlayerControls"):GetControls()

Remotes.Client:Get("SetControlsEnabled"):Connect(function(enabled)
	if enabled then
		playerControls:Enable()
	else
		playerControls:Disable()
	end
end)
