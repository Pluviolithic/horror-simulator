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
local PlayerStatusUI = require(ServerScriptService.Server.PlayerManager.PlayerStatusUI)

local profileStore = ProfileService.GetProfileStore("PlayerData", profileTemplate)

local function initializeLeaderboard(player: Player, data: typeof(profileTemplate))
	local leaderstats = Instance.new "Folder"
	leaderstats.Name = "leaderstats"

	local strength = Instance.new "StringValue"
	strength.Name = "Strength"
	strength.Value = formatter.formatNumberWithSuffix(data.Stats.Strength)
	strength.Parent = leaderstats

	local fear = Instance.new "StringValue"
	fear.Name = "Fear"
	fear.Value = formatter.formatNumberWithSuffix(data.Stats.Fear)
	fear.Parent = leaderstats

	local Kills = Instance.new "StringValue"
	Kills.Name = "Kills"
	Kills.Value = formatter.formatNumberWithSuffix(data.Stats.Kills)
	Kills.Parent = leaderstats

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
		store:dispatch(actions.incrementPlayerStat(player.Name, "LogInCount"))
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = profiles[player.Name]
	if profile ~= nil then
		profile:Release()
	end
end)

Remotes.Server:Get("GetGlobalState"):SetCallback(function()
	return store:getState()
end)

require(script.GlobalLeaderboards)

return 0
