local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
--local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
--local Table = require(ReplicatedStorage.Common.Utils.Table)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local SettingsUI = CentralUI.new(player.PlayerGui:WaitForChild "Settings")

local function shouldRefresh(newState, oldState)
	return selectors.getTempSettings(newState, player.Name) ~= selectors.getTempSettings(oldState, player.Name)
		or selectors.getSavedSettings(newState, player.Name) ~= selectors.getSavedSettings(oldState, player.Name)
end

function SettingsUI:_initialize(): ()
	for _, settingSwitch in self._ui.Background.ScrollingFrame:GetChildren() do
		if not settingSwitch:FindFirstChild "On" then
			continue
		end
		settingSwitch.On.Activated:Connect(function()
			Remotes.Client:Get("SwitchSetting"):SendToServer(settingSwitch.Name)
		end)
		settingSwitch.Off.Activated:Connect(function()
			Remotes.Client:Get("SwitchSetting"):SendToServer(settingSwitch.Name)
		end)
	end

	player.PlayerGui:WaitForChild("MainUI").Settings.Activated:Connect(function()
		self:setEnabled(not self._isOpen)
	end)

	playerStatePromise:andThen(function()
		self:Refresh()

		store.changed:connect(function(newState, oldState)
			if not shouldRefresh(newState, oldState) then
				return
			end
			self:Refresh()
		end)
	end)
end

function SettingsUI:Refresh(): ()
	for _, settingSwitch in self._ui.Background.ScrollingFrame:GetChildren() do
		if not settingSwitch:FindFirstChild "On" then
			continue
		end
		local settingValue = selectors.getSetting(store:getState(), player.Name, settingSwitch.Name)
		settingSwitch.On.Visible = settingValue
		settingSwitch.Off.Visible = not settingValue
	end
end

task.spawn(SettingsUI._initialize, SettingsUI)

return SettingsUI
