local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer

local StrengthMeters = CentralUI.new(player.PlayerGui:WaitForChild "StrengthRanks")

local minBarSize = UDim2.fromScale(0.048, 0.88)
local maxBarSize = UDim2.fromScale(0.895, 0.88)

local minMainBarSize = UDim2.fromScale(0.06, 0.88)
local maxMainBarSize = UDim2.fromScale(0.983, 0.88)

local function shouldRefresh(newState, oldState): boolean
	if selectors.isPlayerLoaded(newState, player.Name) and not selectors.isPlayerLoaded(oldState, player.Name) then
		return true
	end
	return selectors.getStat(newState, player.Name, "Strength") ~= selectors.getStat(oldState, player.Name, "Strength")
end

function StrengthMeters:_initialize(): ()
	player.PlayerGui:WaitForChild("Rank").Open.Activated:Connect(function()
		playSoundEffect "UIButton"
		self:setEnabled(not self._isOpen)
	end)

	self._mainRankBar = player.PlayerGui.Rank.Background.BarBackground.Bar

	playerStatePromise:andThen(function()
		self:Refresh()
		self._currentRank = selectors.getStat(store:getState(), player.Name, "Rank")

		store.changed:connect(function(newState, oldState)
			if not shouldRefresh(newState, oldState) then
				return
			end
			self:Refresh()
		end)
	end)
end

function StrengthMeters:Refresh(): ()
	local meters = self._ui.Background.ScrollingFrame:GetChildren()
	local strength = selectors.getStat(store:getState(), player.Name, "Strength")
	local newRank = selectors.getStat(store:getState(), player.Name, "Rank")

	if self._currentRank and newRank ~= self._currentRank then
		PopupUI(`You Leveled Up To Rank {newRank}!`, Color3.fromRGB(250, 250, 250))
		PopupUI(
			`Your Fear Meter Increased To {selectors.getStat(store:getState(), player.Name, "MaxFearMeter")}!`,
			Color3.fromRGB(250, 250, 250)
		)
	end
	self._currentRank = newRank

	for _, meter in meters do
		if not meter:IsA "ImageLabel" then
			continue
		end

		local meterRank = tonumber(meter.Name:match "%d+")
		local percentComplete = math.clamp(strength / rankUtils.getRankRequirement(meterRank), 0, 1)

		meter.Level.Text.Text = newRank
		meter.Background.Bar:TweenSize(
			UDim2.fromScale(
				minBarSize.X.Scale + (maxBarSize.X.Scale - minBarSize.X.Scale) * percentComplete,
				minBarSize.Y.Scale
			),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.5,
			true
		)

		if not meter:FindFirstChild "Locked" then
			continue
		end

		if meterRank > (newRank + 1) then
			meter.Locked.Visible = true
		else
			meter.Locked.Visible = false
		end
	end

	local percentComplete = math.clamp(
		strength
			/ (
				rankUtils.getRankRequirement(rankUtils.getRankFromStrength(strength) + 1)
				or rankUtils.getRankFromStrength(strength)
			),
		0,
		1
	)
	self._mainRankBar:TweenSize(
		UDim2.fromScale(
			minMainBarSize.X.Scale + (maxMainBarSize.X.Scale - minMainBarSize.X.Scale) * percentComplete,
			minMainBarSize.Y.Scale
		),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad,
		0.5,
		true
	)
end

task.spawn(StrengthMeters._initialize, StrengthMeters)

interfaces[StrengthMeters] = true

return StrengthMeters
