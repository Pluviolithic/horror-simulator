local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Remotes = require(ReplicatedStorage.Common.Remotes)

local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)

Remotes.Client:Get("SendNPCHealthBar"):Connect(function(NPCHealthBar, enabled, humanoid)
	if NPCHealthBar and not enabled then
		NPCHealthBar.Enabled = false
	elseif enabled then
		HealthBar.new(NPCHealthBar.Frame.Background.Frame):connect(humanoid)
		NPCHealthBar.Enabled = true
	end
end)

return 0
