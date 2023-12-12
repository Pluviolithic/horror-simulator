local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer
local popupTemplate = ReplicatedStorage.PopupTemplate
local Popups = player.PlayerGui:WaitForChild("ScreenEffects").Popups

local activePopups = {}

local popupGenerator = function(message, textColor)
	if activePopups[message] then
		return
	end
	activePopups[message] = true

	if textColor == Color3.fromRGB(250, 250, 250) then
		playSoundEffect "WhitePopup"
	else
		playSoundEffect "RedPopup"
	end

	local popup = popupTemplate:Clone()
	popup.PopupText.Text = message

	if textColor then
		popup.PopupText.TextColor3 = textColor
	end

	popup.Parent = Popups

	popup.PopupText:TweenPosition(
		UDim2.fromScale(0, 0.074),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.2,
		true,
		function()
			task.wait(5)
			popup:Destroy()
			activePopups[message] = nil
		end
	)
end

Remotes.Client:Get("SendPopupMessage"):Connect(popupGenerator)

return popupGenerator
