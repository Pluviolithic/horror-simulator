local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local SettingsUI = CentralUI.new(player.PlayerGui:WaitForChild "Settings")

local function shouldRefresh(newState, oldState)
	return selectors.getTempSettings(newState, player.Name) ~= selectors.getTempSettings(oldState, player.Name)
		or selectors.getSavedSettings(newState, player.Name) ~= selectors.getSavedSettings(oldState, player.Name)
		or selectors.hasGamepass(newState, player.Name, "2xSpeed") and not selectors.hasGamepass(
			oldState,
			player.Name,
			"2xSpeed"
		)
		or selectors.hasGamepass(newState, player.Name, "AutoClicker")
			and not selectors.hasGamepass(oldState, player.Name, "AutoClicker")
end

function SettingsUI:_initialize(): ()
	for _, settingSwitch in self._ui.Background.ScrollingFrame:GetChildren() do
		if not settingSwitch:FindFirstChild "On" then
			continue
		end
		settingSwitch.On.Activated:Connect(function()
			playSoundEffect "UIButton"
			Remotes.Client:Get("SwitchSetting"):SendToServer(settingSwitch.Name)
		end)
		settingSwitch.Off.Activated:Connect(function()
			playSoundEffect "UIButton"
			if settingSwitch.Name:match "Vip" and not selectors.hasGamepass(store:getState(), player.Name, "VIP") then
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDs.VIP.Value)
				return
			end
			if
				settingSwitch.Name:match "Speed" and not selectors.hasGamepass(store:getState(), player.Name, "2xSpeed")
			then
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xSpeed"].Value)
				return
			end
			if
				settingSwitch.Name:match "AutoClicker"
				and not selectors.hasGamepass(store:getState(), player.Name, "AutoClicker")
			then
				MarketplaceService:PromptGamePassPurchase(player, gamepassIDs.AutoClicker.Value)
				return
			end
			Remotes.Client:Get("SwitchSetting"):SendToServer(settingSwitch.Name)
		end)
	end

	player.PlayerGui:WaitForChild("MainUI").Settings.Activated:Connect(function()
		playSoundEffect "UIButton"
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
		if settingSwitch.Name == "2xSpeed" and not selectors.hasGamepass(store:getState(), player.Name, "2xSpeed") then
			settingSwitch.On.Visible = false
			settingSwitch.Off.Visible = true
			continue
		end
		if
			settingSwitch.Name:match "AutoClicker"
			and not selectors.hasGamepass(store:getState(), player.Name, "AutoClicker")
		then
			settingSwitch.On.Visible = false
			settingSwitch.Off.Visible = true
			continue
		end
		settingSwitch.On.Visible = settingValue
		settingSwitch.Off.Visible = not settingValue
	end
end

task.spawn(SettingsUI._initialize, SettingsUI)

interfaces[SettingsUI] = true

return SettingsUI
