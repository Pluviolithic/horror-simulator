local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Common.Remotes)

local function resizeHealthBar(healthBar, health, maxHealth)
    healthBar.Size = UDim2.fromScale(health / maxHealth, 1)
end

local currentHealthBarConnection

Remotes.Client:Get("SendNPCHealthBar"):Connect(function(NPCHealthBar, enabled, healthValue, maxHealth)
    if NPCHealthBar and not enabled then
        NPCHealthBar.Enabled = false
        currentHealthBarConnection:Disconnect()
        return
    elseif not enabled then
        return
    end

    if healthValue then
        local healthBar = NPCHealthBar.Frame.Background.Frame.Health
        resizeHealthBar(healthBar, healthValue.Value, maxHealth)
        currentHealthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
            resizeHealthBar(healthBar, healthValue.Value, maxHealth)
        end)
    else
        NPCHealthBar.Enabled = true
    end
end)

return 0