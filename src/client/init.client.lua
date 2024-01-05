local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local client = StarterPlayer.StarterPlayerScripts.Client

require(client.GameAtmosphere.Shutdowns)
require(client.MobileBehavior)
require(client.State.Store)
require(client.UI)
require(client.Cmdr)
require(client.Controls)
require(client.Areas)
require(client.Jumpscare)
require(client.GameAtmosphere.Soundscape)
require(client.GameAtmosphere.Lighting)
require(client.ChatModifiersHandler)
require(client.Pets)

local interfaces = require(client.UI.CollidableInterfaces)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local ZoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)

for interface in interfaces do
	if interface.Trigger then
		task.spawn(function()
			local zone = Zone.new(ZoneUtils.getTaggedForZone(interface.Trigger))

			zone:relocate()

			zone.localPlayerEntered:Connect(function()
				interface:setEnabled(true)
			end)

			zone.localPlayerExited:Connect(function()
				interface:setEnabled(false)
			end)
		end)
	end
end
