local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local ServerScriptService = game:GetService "ServerScriptService"

local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local permissionList = require(ReplicatedStorage.Common.PermissionList)
local petUtils = require(ReplicatedStorage.Common.Utils.Player.PetUtils)
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
}

local leaderboardEntry = ServerStorage.Templates.LeaderboardEntry
local leaderboardPetName = ReplicatedStorage.Config.Misc.LeaderboardPet.Value
local leaderboardWeaponName = ReplicatedStorage.Config.Misc.LeaderboardWeapon.Value

local function awardPetsToPlayer(player: Player, petsDict: { [string]: number }): ()
	store:dispatch(actions.givePlayerPets(player.Name, petsDict))
	store:dispatch(actions.lockPlayerPets(player.Name, petsDict))

	local petsToEquip, counter = {}, 0
	local equippedPetsCount = petUtils.countPetsInDict(selectors.getEquippedPets(store:getState(), player.Name))
	for _, petName in petUtils.getBestPetNames(petsDict, petUtils.countPetsInDict(petsDict)) do
		if equippedPetsCount + counter >= selectors.getStat(store:getState(), player.Name, "MaxPetEquipCount") then
			break
		end
		counter += 1
		petsToEquip[petName] = if petsToEquip[petName] then petsToEquip[petName] + 1 else 1
	end
	if counter > 0 then
		store:dispatch(actions.equipPlayerPets(player.Name, petsToEquip))
	end
end

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

		task.wait(10)
	end

	local monthlyTimestamp = os.date("*t").month .. os.date("*t").year

	local monthlyGlobalLeaderboardStores = {
		Kills = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalKills"),
		Strength = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyGlobalStrength"),
		Rebirths = DataStoreService:GetOrderedDataStore(monthlyTimestamp .. "MonthlyRebirths"),
	}

	for statName, monthlyGlobalLeaderboardStore in monthlyGlobalLeaderboardStores do
		local pages = monthlyGlobalLeaderboardStore:GetSortedAsync(false, 99)
		local leaderboardDisplays = {}

		for _, leaderboardDisplay in CollectionService:GetTagged "MonthlyGlobalLeaderboard" do
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

				print("monthlyTopTen", statName, rank, entry.PlayerName.Text)
				if rank < 3 then
					monthlyTopTen[statName][rank] = entry.PlayerName.Text
					print("monthlyTopTen", statName, rank, entry.PlayerName.Text)
				end

				if rank == 1 then
					-- update podium
				end
			end
		end

		task.wait(10)
	end
end

local function updateGlobalLeaderboardStores(): ()
	for _, player in Players:GetPlayers() do
		if not profiles[player.Name] or player.UserId < 0 then -- permissionList.Admins[player.UserId]
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

		local monthlyTimestamp = os.date("*t").month .. os.date("*t").year

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

		for _, player in Players:GetPlayers() do
			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				continue
			end

			if
				table.find(monthlyTopTen.Kills, player.Name)
				and not selectors.getOwnedPets(store:getState(), player.Name)[leaderboardPetName]
			then
				print "awarding leaderboard pet"
				awardPetsToPlayer(player, { [leaderboardPetName] = 1 })
			elseif
				not table.find(monthlyTopTen.Kills, player.Name)
				and selectors.getOwnedPets(store:getState(), player.Name)[leaderboardPetName]
			then
				print "removing leaderboard pet"
				store:dispatch(actions.deletePlayerPets(player.Name, { [leaderboardPetName] = 1 }))
				if selectors.getEquippedPets(store:getState(), player.Name)[leaderboardPetName] then
					store:dispatch(actions.unequipPlayerPets(player.Name, { [leaderboardPetName] = 1 }))
				end
				if selectors.getLockedPets(store:getState(), player.Name)[leaderboardPetName] then
					store:dispatch(actions.unlockPlayerPets(player.Name, { [leaderboardPetName] = 1 }, true))
				end
			end

			if
				table.find(monthlyTopTen.Strength, player.Name)
				and not selectors.getOwnedWeapons(store:getState(), player.Name)[leaderboardWeaponName]
			then
				print "awarding leaderboard weapon"
				store:dispatch(actions.givePlayerWeapon(player.Name, leaderboardWeaponName))
				store:dispatch(actions.equipWeapon(player.Name, leaderboardWeaponName))
			elseif
				not table.find(monthlyTopTen.Strength, player.Name)
				and selectors.getOwnedWeapons(store:getState(), player.Name)[leaderboardWeaponName]
			then
				print "removing leaderboard weapon"
				store:dispatch(actions.unequipWeapon(player.Name, leaderboardWeaponName))
				store:dispatch(actions.takePlayerWeapon(player.Name, leaderboardWeaponName))
			end
		end

		task.wait(120)
	end
end)

return function(playerName: string, statName: string)
	return table.find(monthlyTopTen[statName], playerName)
end
