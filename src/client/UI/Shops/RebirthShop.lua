local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer
local mainUI = player.PlayerGui:WaitForChild "MainUI"

local upgrades = ReplicatedStorage.Config.Rebirth.Upgrades
local RebirthShop = CentralUI.new(player.PlayerGui:WaitForChild "RebirthShop")

local function shouldRefresh(newState, oldState)
	return selectors.isPlayerLoaded(oldState, player.Name)
		and selectors.getPurchaseData(newState, player.Name).RebirthUpgrades
			~= selectors.getPurchaseData(oldState, player.Name).RebirthUpgrades
end

function RebirthShop:_initialize()
	mainUI.Rebirth.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(true)
	end)

	playerStatePromise:andThen(function()
		self:Refresh()
		store.changed:connect(function(newState, oldState)
			if shouldRefresh(newState, oldState) then
				self:Refresh()
			end
		end)
	end)
end

local setEnabled = RebirthShop.setEnabled
function RebirthShop:setEnabled(enabled)
	if enabled and selectors.getStat(store:getState(), player.Name, "Rebirths") < 1 then
		PopupUI "Rebirth First To Access The Rebirth Shop!"
		return
	end
	setEnabled(self, enabled)
end

function RebirthShop:Refresh()
	for _, upgradeDisplay in self._ui.Background.ScrollingFrame:GetChildren() do
		if not upgradeDisplay:IsA "ImageLabel" then
			continue
		end

		local upgradeLevel = selectors.getRebirthUpgradeLevel(store:getState(), player.Name, upgradeDisplay.Name)

		upgradeDisplay.Level.Text = upgradeLevel .. "/" .. #upgrades[upgradeDisplay.Name]:GetChildren()

		if upgrades[upgradeDisplay.Name]:FindFirstChild(upgradeLevel + 1) then
			upgradeDisplay.Price.Text = upgrades[upgradeDisplay.Name][upgradeLevel + 1].Value .. " Tokens"
		else
			upgradeDisplay.Price.Text = "MAX"
		end
	end
end

task.spawn(RebirthShop._initialize, RebirthShop)

RebirthShop.Trigger = "RebirthShop"
interfaces[RebirthShop] = true

return RebirthShop
