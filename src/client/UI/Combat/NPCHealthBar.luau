local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Remotes = require(ReplicatedStorage.Common.Remotes)

local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)

Remotes.Client:Get("SendNPCHealthBar"):Connect(function(NPCHealthBar: any, enabled: boolean, humanoid: Humanoid)
	if NPCHealthBar and not enabled then
		NPCHealthBar.Enabled = false
	elseif enabled then
		NPCHealthBar.Enabled = true
		if NPCHealthBar:FindFirstAncestor "Dummy" then
			return
		end
		HealthBar.new(NPCHealthBar.Frame.Background.Frame):connect(humanoid)
	end
end)

return 0
