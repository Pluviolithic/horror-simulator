local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Remotes = require(ReplicatedStorage.Common.Remotes)

local function resizeHealthBar(healthBar, health, maxHealth)
	healthBar.Size = UDim2.fromScale(health / maxHealth, 1)
end

local function updateHealthBarText(healthBarText, health, maxHealth)
	healthBarText.Text = string.format("%d / %d", health, maxHealth)
end

local currentHealthBarConnection

Remotes.Client:Get("SendNPCHealthBar"):Connect(function(NPCHealthBar, enabled, healthValue, maxHealth)
	print("SendNPCHealthBar", NPCHealthBar, enabled, healthValue, maxHealth)
	if NPCHealthBar and not enabled then
		NPCHealthBar.Enabled = false
		if currentHealthBarConnection then
			currentHealthBarConnection:Disconnect()
		end
		return
	elseif not enabled then
		return
	end

	if healthValue then
		local healthBar = NPCHealthBar.Frame.Background.Frame.Health
		local healthBarText = NPCHealthBar.Frame.Background.Frame.HP

		resizeHealthBar(healthBar, healthValue.Value, maxHealth)
		updateHealthBarText(healthBarText, healthValue.Value, maxHealth)
		currentHealthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			resizeHealthBar(healthBar, healthValue.Value, maxHealth)
			updateHealthBarText(healthBarText, healthValue.Value, maxHealth)
		end)
	end

	NPCHealthBar.Enabled = true
end)

return 0
