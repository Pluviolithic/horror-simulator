local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"

local player = Players.LocalPlayer
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local function handleUIContainer(uiContainer)
	for _, ui in uiContainer:GetDescendants() do
		if ui:IsA "TextLabel" and ui.RichText == true then
			ui.RichText = false
			ui.RichText = true
		end
	end
end

playerStatePromise:andThen(function()
	handleUIContainer(player.PlayerGui)
end)

for _, uiContainer in CollectionService:GetTagged "richtextfix" do
	handleUIContainer(uiContainer)
end
CollectionService:GetInstanceAddedSignal("richtextfix"):Connect(handleUIContainer)

return 0
