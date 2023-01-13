local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Remotes = require(ReplicatedStorage.Common.Remotes)

local HealthBar = require(ReplicatedStorage.Common.Utils.HealthBar)

Remotes.Client:Get("SendNPCHealthBar"):Connect(function(NPCHealthBar: any, enabled: boolean, humanoid: Humanoid)
	if NPCHealthBar and not enabled then
		NPCHealthBar.Enabled = false
	elseif enabled then
		if not NPCHealthBar:FindFirstAncestor "NPCUI" then
			return
		end
		HealthBar.new(NPCHealthBar.Frame.Background.Frame):connect(humanoid)
		NPCHealthBar.Enabled = true
	end
end)

return 0
