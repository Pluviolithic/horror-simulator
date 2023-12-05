local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"

local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)

local player = Players.LocalPlayer
local mainUI = player.PlayerGui:WaitForChild "MainUI"

local RebirthShop = {}

function RebirthShop:_initialize()
	mainUI.Rebirth.Activated:Connect(function()
		PopupUI "Rebirth Update Coming Soon!"
	end)
end

function RebirthShop:setEnabled(enabled)
	if enabled then
		PopupUI "Rebirth Update Coming Soon!"
	end
end

task.spawn(RebirthShop._initialize, RebirthShop)

RebirthShop.Trigger = "RebirthShop"
interfaces[RebirthShop] = true

return RebirthShop
