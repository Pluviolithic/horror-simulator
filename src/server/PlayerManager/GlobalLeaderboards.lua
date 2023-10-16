local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)

local globalLeaderboardStores = {
	Kills = DataStoreService:GetOrderedDataStore "Kills",
	Strength = DataStoreService:GetOrderedDataStore "Strength",
	Rebirths = DataStoreService:GetOrderedDataStore "Rebirths",
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
		if not profiles[player.Name] then
			continue
		end
		for statName, globalLeaderboard in globalLeaderboardStores do
			pcall(
				globalLeaderboard.SetAsync,
				globalLeaderboard,
				tostring(player.UserId),
				profiles[player.Name].Data[statName]
			)
		end
	end
end

task.spawn(function()
	while true do
		task.spawn(updateGlobalLeaderboardDisplays)
		task.wait(180)
		task.spawn(updateGlobalLeaderboardStores)
	end
end)

return 0
