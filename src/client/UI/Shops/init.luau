local ReplicatedStorage = game:GetService "ReplicatedStorage"
local StarterPlayer = game:GetService "StarterPlayer"

local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local ZoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local interfaces =
	require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces) :: { [typeof(setmetatable({}, CentralUI))]: boolean }

for _, module in script:GetChildren() do
	task.spawn(function()
		local shop = require(module)
		local zone = Zone.new(ZoneUtils.getTaggedForZone(shop.Trigger))

		zone:relocate()

		zone.localPlayerEntered:Connect(function()
			shop:setEnabled(true)
		end)

		zone.localPlayerExited:Connect(function()
			shop:setEnabled(false)
		end)

		interfaces[shop] = true
	end)
end

return 0
