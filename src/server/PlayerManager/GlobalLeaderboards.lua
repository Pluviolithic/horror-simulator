local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local pets = require(ServerScriptService.Server.Combat.Perks.Pets)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local permissionList = require(ReplicatedStorage.Common.PermissionList)
local profiles = require(ServerScriptService.Server.PlayerManager.Profiles)

local globalLeaderboardStores = {
	Kills = DataStoreService:GetOrderedDataStore "GlobalKills",
	Strength = DataStoreService:GetOrderedDataStore "GlobalStrength",
	Rebirths = DataStoreService:GetOrderedDataStore "Rebirths",
}

local monthlyTopTen = {
	Kills = {},
	Strength = {},
	Rebirths = {},
	KillsLoaded = false,
	StrengthLoaded = false,
	RebirthsLoaded = false,
}

local _, podiums = next(CollectionService:GetTagged "Podiums")
local leaderboardEntry = ServerStorage.Templates.LeaderboardEntry
local playerNameTemplate = ReplicatedStorage.PlayerName:Clone()
local leaderboardPetName = ReplicatedStorage.Config.Misc.LeaderboardPet.Value
local leaderboardWeaponName = ReplicatedStorage.Config.Misc.LeaderboardWeapon.Value

local function awardPetsToPlayer(player: Player, petsDict: { [string]: number }): ()
	store:dispatch(actions.givePlayerPets(player.Name, petsDict))
	store:dispatch(actions.lockPlayerPets(player.Name, petsDict))

	pets.equipBestPets(player)
end

local function updateGlobalLeaderboardDisplays(): ()
	for statName, globalLeaderboardStore in globalLeaderboardStores do
		local globalPodium = podiums:FindFirstChild("AllTime" .. statName .. "Podium")
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

			if rank == 1 then
				globalPodium.Rig.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(score.key))
				playerNameTemplate:Clone().Parent = globalPodium.Rig.Head
				globalPodium.Rig.Head.PlayerName.Frame.PlayerName.Text = if success then playerName else score.key
			end
		end

		task.wait(10)
	end

	local monthlyTimestamp = clockUtils.getMonthlyTimestamp()

	local monthlyGlobalLeaderboardStores = {
		Kills = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalKills"),
		Strength = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalStrength"),
		Rebirths = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyRebirths"),
	}

	for statName, monthlyGlobalLeaderboardStore in monthlyGlobalLeaderboardStores do
		local monthlyPodium = podiums:FindFirstChild("Monthly" .. statName .. "Podium")
		local pages = monthlyGlobalLeaderboardStore:GetSortedAsync(false, 99)
		local leaderboardDisplays = {}

		for _, leaderboardDisplay in CollectionService:GetTagged "MonthlyGlobalLeaderboard" do
			if leaderboardDisplay.Name == statName then
				table.insert(leaderboardDisplays, leaderboardDisplay)
			end
		end

		local newTopTen = {}
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

				if rank < 3 then
					newTopTen[rank] = entry.PlayerName.Text
				end

				if rank == 1 then
					monthlyPodium.Rig.Humanoid:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(score.key))
					playerNameTemplate:Clone().Parent = monthlyPodium.Rig.Head
					monthlyPodium.Rig.Head.PlayerName.Frame.PlayerName.Text = if success then playerName else score.key
				end
			end
		end
		monthlyTopTen[statName .. "Loaded"] = true
		monthlyTopTen[statName] = newTopTen

		task.wait(10)
	end
end

local function updateGlobalLeaderboardStores(): ()
	for _, player in Players:GetPlayers() do
		if not profiles[player.Name] or permissionList.Admins[player.UserId] or player.UserId < 0 then
			continue
		end
		for statName, globalLeaderboard in globalLeaderboardStores do
			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				continue
			end
			pcall(
				globalLeaderboard.SetAsync,
				globalLeaderboard,
				tostring(player.UserId),
				math.floor(selectors.getStat(store:getState(), player.Name, statName))
			)
		end

		local monthlyTimestamp = clockUtils.getMonthlyTimestamp()

		local monthlyGlobalLeaderboardStores = {
			Kills = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalKills"),
			Strength = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalStrength"),
			Rebirths = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyRebirths"),
		}

		for statName, monthlyGlobalLeaderboard in monthlyGlobalLeaderboardStores do
			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				continue
			end
			pcall(
				monthlyGlobalLeaderboard.SetAsync,
				monthlyGlobalLeaderboard,
				tostring(player.UserId),
				math.floor(selectors.getStat(store:getState(), player.Name, statName .. monthlyTimestamp) or 0)
			)
		end
	end
end

task.delay(10, function()
	while true do
		task.spawn(updateGlobalLeaderboardDisplays)
		task.spawn(updateGlobalLeaderboardStores)
		task.wait(120)
	end
end)

local function checkPlayer(player: Player)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		return
	end

	if
		table.find(monthlyTopTen.Kills, player.Name)
		and not selectors.getOwnedPets(store:getState(), player.Name)[leaderboardPetName]
	then
		awardPetsToPlayer(player, { [leaderboardPetName] = 1 })
	elseif
		monthlyTopTen.KillsLoaded
		and not table.find(monthlyTopTen.Kills, player.Name)
		and selectors.getOwnedPets(store:getState(), player.Name)[leaderboardPetName]
	then
		store:dispatch(actions.deletePlayerPets(player.Name, { [leaderboardPetName] = 1 }))
		if selectors.getEquippedPets(store:getState(), player.Name)[leaderboardPetName] then
			store:dispatch(actions.unequipPlayerPets(player.Name, { [leaderboardPetName] = 1 }))
		end
		if selectors.getLockedPets(store:getState(), player.Name)[leaderboardPetName] then
			store:dispatch(actions.unlockPlayerPets(player.Name, { [leaderboardPetName] = 1 }, true))
		end
		pets.equipBestPets(player)
	end

	if
		table.find(monthlyTopTen.Strength, player.Name)
		and not selectors.getOwnedWeapons(store:getState(), player.Name)[leaderboardWeaponName]
	then
		store:dispatch(actions.givePlayerWeapon(player.Name, leaderboardWeaponName))
		store:dispatch(actions.equipWeapon(player.Name, leaderboardWeaponName))
	elseif
		monthlyTopTen.StrengthLoaded
		and not table.find(monthlyTopTen.Strength, player.Name)
		and selectors.getOwnedWeapons(store:getState(), player.Name)[leaderboardWeaponName]
	then
		store:dispatch(actions.takePlayerWeapon(player.Name, leaderboardWeaponName))
	end

	if
		table.find(monthlyTopTen.Rebirths, player.Name)
		and not selectors.achievedMilestone(store:getState(), player.Name, "TopRebirths")
	then
		store:dispatch(actions.achievedMilestone(player.Name, "TopRebirths"))
	elseif
		monthlyTopTen.RebirthsLoaded
		and not table.find(monthlyTopTen.Rebirths, player.Name)
		and selectors.achievedMilestone(store:getState(), player.Name, "TopRebirths")
	then
		store:dispatch(actions.removeMilestone(player.Name, "TopRebirths"))
	end
end

task.spawn(function()
	while true do
		task.wait(15)
		for _, player in Players:GetPlayers() do
			checkPlayer(player)
		end
	end
end)

Players.PlayerAdded:Connect(checkPlayer)

return 0
