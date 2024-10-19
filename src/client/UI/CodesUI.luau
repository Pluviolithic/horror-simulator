local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer
local CodesUI = CentralUI.new(player.PlayerGui:WaitForChild "Codes")

function CodesUI:_initialize()
	player.PlayerGui:WaitForChild("MainUI").Codes.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(not self._isOpen)
	end)

	self._ui.LeftBackground.Confirm.Activated:Connect(function()
		playSoundEffect "UIButton"
		if self._debounce or #self._ui.LeftBackground.TextBox.Text == 0 then
			return
		end
		self._debounce = true
		Remotes.Client:Get("RedeemCode"):CallServerAsync(self._ui.LeftBackground.TextBox.Text):andThen(function(message)
			self._ui.LeftBackground.TextBox.Text = message
		end)
		task.wait(1)
		self._debounce = nil
	end)
end

function CodesUI:OnOpen()
	self._ui.LeftBackground.TextBox.Text = ""
end

task.spawn(CodesUI._initialize, CodesUI)

interfaces[CodesUI] = true

return CodesUI
