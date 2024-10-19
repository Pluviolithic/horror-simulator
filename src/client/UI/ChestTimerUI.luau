local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

playerStatePromise:andThen(function()
	while true do
		local chestTimers = selectors.getChestTimers(store:getState(), player.Name)
		for _, VIPChestTimer in CollectionService:GetTagged "VIPChestTimer" do
			VIPChestTimer.Text = clockUtils.getFormattedChestTimer(chestTimers.VIPChest)
		end
		for _, groupChestTimer in CollectionService:GetTagged "GroupChestTimer" do
			groupChestTimer.Text = clockUtils.getFormattedChestTimer(chestTimers.GroupChest)
		end
		task.wait(1)
	end
end)

return 0
