local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local ProfileService = require(ServerScriptService.Server.lib.ProfileService)
local profileTemplate = require(ServerScriptService.Server.PlayerManager.ProfileTemplate)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local PlayerStatusUI = require(ServerScriptService.Server.PlayerManager.PlayerStatusUI)

local profileStore = ProfileService.GetProfileStore("PlayerData", profileTemplate)

local function initializeLeaderboard(player: Player, data)
	local leaderstats = Instance.new "Folder"
	leaderstats.Name = "leaderstats"

	local strength = Instance.new "StringValue"
	strength.Name = "Strength"
	strength.Value = formatter.formatNumberWithSuffix(data.Stats.Strength)
	strength.Parent = leaderstats

	local rank = Instance.new "StringValue"
	rank.Name = "Rank"
	rank.Value = formatter.formatNumberWithSuffix(data.Stats.Rank)
	rank.Parent = leaderstats

	local kills = Instance.new "StringValue"
	kills.Name = "Kills"
	kills.Value = formatter.formatNumberWithSuffix(data.Stats.Kills)
	kills.Parent = leaderstats

	-- local fear = Instance.new "StringValue"
	-- fear.Name = "Fear"
	-- fear.Value = formatter.formatNumberWithSuffix(data.Stats.Fear)
	-- fear.Parent = leaderstats

	local Rebirths = Instance.new "StringValue"
	Rebirths.Name = "Rebirths"
	Rebirths.Value = formatter.formatNumberWithSuffix(data.Stats.Rebirths)
	Rebirths.Parent = leaderstats

	leaderstats.Parent = player
end

local function onPlayerAdded(player: Player)
	local profile = profileStore:LoadProfileAsync("Player_" .. player.UserId)
	if not profile then
		player:Kick "Data failed to load correctly."
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		profiles[player.Name] = nil
		player:Kick()
	end)

	initializeLeaderboard(player, profile.Data)
	PlayerStatusUI.new(player):enable()

	if player:IsDescendantOf(Players) then
		profiles[player.Name] = profile
		store:dispatch(actions.addPlayer(player.Name, profile.Data))

		if os.time() - profile.Data.Stats.LastLogOff > 24 * 60 * 60 then
			store:dispatch(actions.resetGifts(player.Name))
		end

		store:dispatch(actions.setPlayerStat(player.Name, "GiftCycleBeganTimestamp", os.time()))
		store:dispatch(actions.incrementPlayerStat(player.Name, "LogInCount"))
		store:dispatch(actions.setPlayerStat(player.Name, "LastLogOn", os.time()))
	end

	for _, existingPlayer in Players:GetPlayers() do
		if existingPlayer == player then
			continue
		end

		task.spawn(function()
			if existingPlayer:IsFriendsWith(player.UserId) then
				store:dispatch(actions.addFriend(existingPlayer.Name, player.Name))
				store:dispatch(actions.addFriend(player.Name, existingPlayer.Name))
			end
		end)
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player.Name]
	store:dispatch(actions.setPlayerStat(player.Name, "LastLogOff", os.time()))
	store:dispatch(
		actions.incrementPlayerStat(
			player.Name,
			"TimePlayed",
			os.time() - selectors.getStat(store:getState(), player.Name, "LastLogOn")
		)
	)
	if profile ~= nil then
		profile:Release()
	end
	store:dispatch(actions.removePlayer(player.Name))

	for _, existingPlayer in Players:GetPlayers() do
		if existingPlayer == player then
			continue
		end

		task.spawn(function()
			if existingPlayer:IsFriendsWith(player.UserId) then
				store:dispatch(actions.removeFriend(existingPlayer.Name, player.Name))
			end
		end)
	end
end)

Remotes.Server:Get("GetGlobalState"):SetCallback(function()
	return store:getState()
end)

require(script.GlobalLeaderboards)
require(script.SoftShutdown)
require(script.Settings)
require(script.Tutorial)
require(script.Badges)
require(script.Gifts)
--require(script.NoobSpawnFix)

return 0
