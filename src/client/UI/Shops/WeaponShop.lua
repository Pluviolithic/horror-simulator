local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"

local player = Players.LocalPlayer
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)

local WeaponShop = CentralUI.new(player.PlayerGui:WaitForChild "WeaponShop")

WeaponShop.Trigger = "WeaponShop"

return WeaponShop
