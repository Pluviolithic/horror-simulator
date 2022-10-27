local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Promise = require(ReplicatedStorage.Common.lib.Promise)

Promise.new(function(resolve)
	resolve(require(player.PlayerScripts:WaitForChild "PlayerModule"):GetControls())
end):andThen(function(playerControls)
	Remotes.Client:Get("SetControlsEnabled"):Connect(function(enabled)
		if enabled then
			playerControls:Enable()
		else
			playerControls:Disable()
		end
	end)
end)

return 0
