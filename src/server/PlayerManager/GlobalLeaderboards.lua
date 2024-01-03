local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local permissionList = require(ReplicatedStorage.Common.PermissionList)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)

local globalLeaderboardStores = {
	Kills = DataStoreService:GetOrderedDataStore "GlobalKills",
	Strength = DataStoreService:GetOrderedDataStore "GlobalStrength",
	--Rebirths = DataStoreService:GetOrderedDataStore "Rebirths",
}

local leaderboardEntry = ServerStorage.Templates.LeaderboardEntry

local function updateGlobalLeaderboardDisplays(): ()
	for statName, globalLeaderboardStore in globalLeaderboardStores do
		local pages = globalLeaderboardStore:GetSortedAsync(false, 99)
		local leaderboardDisplays = {}

		for _, leaderboardDisplay in CollectionService:GetTagged "GlobalLeaderboard" do
			if leaderboardDisplay.Name == statName then
				table.insert(leaderboardDisplays, leaderboardDisplay)
			end
		end

		for rank, score in pages:GetCurrentPage() do
			local success, playerName = pcall(Players.GetNameFromUserIdAsync, Players, tonumber(score.key))

			for _, leaderboardDisplay in leaderboardDisplays do
				local entry = leaderboardDisplay:FindFirstChild(tostring(rank))
				if not entry then
					entry = leaderboardEntry:Clone()
					entry.Name = tostring(rank)
				end
				entry.PlayerName.Text = if success then playerName else score.key
				entry.Amount.Text = formatter.formatNumberWithSuffix(score.value)
				entry.Rank.Text = "#" .. rank
				entry.Parent = leaderboardDisplay
			end
		end
	end
end

local function updateGlobalLeaderboardStores(): ()
	for _, player in Players:GetPlayers() do
		if
			not profiles[player.Name]
			or permissionList.Admins[player.UserId]
			or not selectors.isPlayerLoaded(store:getState(), player.Name)
			or player.UserId < 0
		then
			continue
		end
		for statName, globalLeaderboard in globalLeaderboardStores do
			pcall(
				globalLeaderboard.SetAsync,
				globalLeaderboard,
				tostring(player.UserId),
				selectors.getStat(store:getState(), player.Name, statName)
			)
			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				continue
			end
		end
	end
end

task.delay(10, function()
	while true do
		task.spawn(updateGlobalLeaderboardDisplays)
		task.spawn(updateGlobalLeaderboardStores)
		task.wait(100)
	end
end)

return 0
