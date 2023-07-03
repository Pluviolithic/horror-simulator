local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local player = Players.LocalPlayer

local StrengthMeters = CentralUI.new(player.PlayerGui:WaitForChild "StrengthRanks")

local minBarSize = UDim2.fromScale(0.048, 0.88)
local maxBarSize = UDim2.fromScale(0.895, 0.88)

local function shouldRefresh(newState, oldState): boolean
	if selectors.isPlayerLoaded(newState, player.Name) and not selectors.isPlayerLoaded(oldState, player.Name) then
		return true
	end
	return selectors.getStat(newState, player.Name, "Strength") ~= selectors.getStat(oldState, player.Name, "Strength")
end

function StrengthMeters:_initialize(): ()
	interfaces[self] = true

	player.PlayerGui:WaitForChild("Rank").Open.Activated:Connect(function()
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

function StrengthMeters:Refresh(): ()
    local meters = self._ui.Background.ScrollingFrame:GetChildren()
    local strength = selectors.getStat(store:getState(), player.Name, "Strength")
    local currentRank = selectors.getStat(store:getState(), player.Name, "Rank")
    for _, meter in meters do
        if not meter:IsA("ImageLabel") then
            continue
        end

        local meterRank = tonumber(meter.Name:match("%d+"))
        local percentComplete = math.clamp(
            strength / rankUtils.getRankRequirement(meterRank),
            0,
            1
        )

        meter.Level.Text.Text = currentRank
        meter.Background.Bar.Size = UDim2.fromScale(
            minBarSize.X.Scale + (maxBarSize.X.Scale - minBarSize.X.Scale) * percentComplete,
            minBarSize.Y.Scale
        )

        if not meter:FindFirstChild("Locked") then
            continue
        end

        if meterRank > (currentRank + 1) then
            meter.Locked.Visible = true
        else
            meter.Locked.Visible = false
        end
    end
end

task.spawn(StrengthMeters._initialize, StrengthMeters)

return StrengthMeters
