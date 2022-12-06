local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"

local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local ZoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)

local function playerTriggeredShop(shop, enable)
	shop:setEnabled(enable)
end

for _, module in ipairs(script:GetChildren()) do
	local shop = require(module)
	local zone = Zone.new(ZoneUtils.getTaggedForZone(shop.Trigger))

	zone:relocate()

	zone.localPlayerEntered:Connect(function()
		playerTriggeredShop(shop, true)
	end)

	zone.localPlayerExited:Connect(function()
		playerTriggeredShop(shop, false)
	end)

	interfaces[shop] = true
end

return 0
