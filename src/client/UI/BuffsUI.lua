local Players = game:GetService "Players"
local SocialService = game:GetService "SocialService"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local Count = require(ReplicatedStorage.Common.lib.Sift).Dictionary.count
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local PopupUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.PopupUI)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)
local RobuxShop = require(StarterPlayer.StarterPlayerScripts.Client.UI.Shops.RobuxShop)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local interfaces = require(StarterPlayer.StarterPlayerScripts.Client.UI.CollidableInterfaces)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)
local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local player = Players.LocalPlayer

local buffTray = player.PlayerGui:WaitForChild "Buffs"
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local InviteUI = CentralUI.new(player.PlayerGui:WaitForChild "InvitePrompt")

local monthlyLeaderboards = CollectionService:GetTagged "MonthlyGlobalLeaderboard"

local function isScared(state)
	if selectors.getActiveBoosts(state, player.Name)["FearlessBoost"] then
		return false
	end
	return selectors.getStat(state, player.Name, "CurrentFearMeter")
			== selectors.getStat(state, player.Name, "MaxFearMeter")
		and (os.time() - selectors.getStat(state, player.Name, "LastScaredTimestamp")) < 121
end

-- taken from the docs: https://create.roblox.com/docs/reference/engine/classes/SocialService#CanSendGameInviteAsync
local function canSendGameInvite(sendingPlayer)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer)
	end)

	return success and canSend
end

local function updateBuffTray(state)
	local activeBoosts = selectors.getActiveBoosts(state, player.Name)
	for _, buffDisplay in buffTray.Frame:GetChildren() do
		if not buffDisplay.Name:match "Boost" then
			if not buffDisplay:IsA "GuiButton" then
				continue
			end
			if buffDisplay.Name == "FriendBuff" then
				local friendCount = Count(selectors.getActiveFriendsWhoJoined(state, player.Name))
				buffDisplay.Visible = friendCount > 0
				buffDisplay.Amount.Text = `{15 * friendCount}%`
			elseif buffDisplay.Name == "LeaderboardLuck" then
				buffTray.Frame.LeaderboardLuck.Visible =
					selectors.achievedMilestone(store:getState(), player.Name, "TopRebirths")
			else
				buffDisplay.Visible = isScared(state)
				buffDisplay.Timer.Text = clockUtils.getFormattedRemainingTime(
					selectors.getStat(state, player.Name, "LastScaredTimestamp"),
					120
				)
			end
			continue
		end
		if activeBoosts[buffDisplay.Name] then
			buffDisplay.Timer.Text = clockUtils.getFormattedRemainingTime(
				activeBoosts[buffDisplay.Name].StartTime,
				activeBoosts[buffDisplay.Name].Duration
			)
			buffDisplay.Visible = true
		elseif buffDisplay.Visible then
			buffDisplay.Visible = false

			local multiplierAmount = "2x "
			if buffDisplay.Name:match "Luck" then
				multiplierAmount = "5x "
			elseif buffDisplay.Name:match "Fearless" then
				multiplierAmount = ""
			elseif buffDisplay.Name:match "Workout" then
				multiplierAmount = "3x "
			end

			PopupUI(`{multiplierAmount}{buffDisplay.Name:match "(%u.+)%u"} Boost Has Expired!`)
		end
	end
end

for _, buffDisplay in buffTray.Frame:GetChildren() do
	if not buffDisplay:IsA "GuiButton" then
		continue
	end

	DescriptionUI(buffDisplay, buffDisplay.Frame)

	if not buffDisplay.Name:match "Boost" then
		continue
	end
	buffDisplay.Activated:Connect(function()
		playSoundEffect "UIButton"
		RobuxShop:OpenSubShop "Boosts"
	end)
end

buffTray.Frame.DamageDebuff.Activated:Connect(function()
	playSoundEffect "UIButton"
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xAttackSpeed"].Value)
end)

buffTray.Frame.SpeedDebuff.Activated:Connect(function()
	playSoundEffect "UIButton"
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xSpeed"].Value)
end)

buffTray.Frame.FriendBuff.Activated:Connect(function()
	playSoundEffect "UIButton"
	if canSendGameInvite(player) then
		pcall(SocialService.PromptGameInvite, SocialService, player)
	end
end)

buffTray.Frame.LeaderboardLuck.Activated:Connect(function()
	playSoundEffect "UIButton"
	RobuxShop:OpenSubShop "Boosts"
end)

interfaces[InviteUI] = true

playerStatePromise:andThen(function()
	player.PlayerGui:WaitForChild("MainUI").Invite.Activated:Connect(function()
		playSoundEffect "UIButton"
		InviteUI:setEnabled(not InviteUI._isOpen)
	end)

	InviteUI._ui.Background.Invite.Activated:Connect(function()
		playSoundEffect "UIButton"
		if canSendGameInvite(player) then
			pcall(SocialService.PromptGameInvite, SocialService, player)
		end
	end)

	buffTray:WaitForChild "Frame"
	updateBuffTray(store:getState())
	store.changed:connect(updateBuffTray)
	while true do
		task.wait(1)
		updateBuffTray(store:getState())
	end
end)

return 0
