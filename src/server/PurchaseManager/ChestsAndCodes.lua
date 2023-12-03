local ServerStorage = game:GetService "ServerStorage"
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local zoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local productRewarders = require(ServerScriptService.Server.PurchaseManager.DeveloperProducts.Products.Rewarders)

local codes = ServerStorage.Codes
local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs
local packIDs = ReplicatedStorage.Config.DevProductData.Packs

local success, expiredCodes
local expiredCodeDataStore = DataStoreService:GetDataStore "ExpiredCodes"
local VIPChestZone = Zone.new(zoneUtils.getTaggedForZone "VIPChestHitbox")
local groupChestZone = Zone.new(zoneUtils.getTaggedForZone "GroupChestHitbox")
local chestTimerLength = ReplicatedStorage.Config.DevProductData.Chests.ChestTimerLength.Value

VIPChestZone:relocate()
groupChestZone:relocate()

local function awardItem(player, item)
	if item:match "Boost" then
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, item))

		local multiplierAmount = "2x "
		if item:match "Luck" then
			multiplierAmount = "5x "
		elseif item:match "Fearless" then
			multiplierAmount = ""
		end
		Remotes.Server
			:Get("SendPopupMessage")
			:SendToPlayer(player, `You Have Received A {multiplierAmount}{item:match "(%u.+)%u"} Boost!`)
	else
		productRewarders[packIDs:FindFirstChild(item, true).Value](player)
	end
end

local vipChestAwards = {
	"FearBoost15",
	"SmallGemPack",
	"DamageBoost15",
	"GemsBoost15",
	"TinyFearPack",
	"FearlessBoost15",
}

local groupChestAwards = {
	"GemsBoost15",
	"TinyFearPack",
	"DamageBoost15",
	"FearBoost15",
	"SmallGemPack",
	"FearlessBoost15",
}

VIPChestZone.playerEntered:Connect(function(player)
	if not selectors.hasGamepass(store:getState(), player.Name, "VIP") then
		Remotes.Server:Get("SendPopupMessage"):SendToPlayer(player, "You Need VIP To Open This Chest!")
		MarketplaceService:PromptGamePassPurchase(player, gamepassIDs.VIP.Value)
		return
	end
	local chestTimers = selectors.getChestTimers(store:getState(), player.Name)
	if not clockUtils.hasTimeLeft(chestTimers.VIPChest, chestTimerLength) then
		local currentAwardIndex = selectors.getStat(store:getState(), player.Name, "VIPChestAwardIndex")
		store:dispatch(actions.startChestTimer(player.Name, "VIPChest"))
		awardItem(player, vipChestAwards[currentAwardIndex])
		store:dispatch(
			actions.setPlayerStat(player.Name, "VIPChestAwardIndex", (currentAwardIndex % #vipChestAwards) + 1)
		)
	else
		Remotes.Server:Get("SendPopupMessage"):SendToPlayer(player, "You Can Not Claim This Yet!")
	end
end)

groupChestZone.playerEntered:Connect(function(player)
	if not player:IsInGroup(2855772) then
		Remotes.Server:Get("SendPopupMessage"):SendToPlayer(player, "Join Prodigy Studios For Free Rewards!")
		return
	end
	local chestTimers = selectors.getChestTimers(store:getState(), player.Name)
	if not clockUtils.hasTimeLeft(chestTimers.GroupChest, chestTimerLength) then
		store:dispatch(actions.startChestTimer(player.Name, "GroupChest"))
		local currentAwardIndex = selectors.getStat(store:getState(), player.Name, "GroupChestAwardIndex")
		awardItem(player, groupChestAwards[currentAwardIndex])
		store:dispatch(
			actions.setPlayerStat(player.Name, "GroupChestAwardIndex", (currentAwardIndex % #groupChestAwards) + 1)
		)
	else
		Remotes.Server:Get("SendPopupMessage"):SendToPlayer(player, "You Can Not Claim This Yet!")
	end
end)

Remotes.Server:Get("RedeemCode"):SetCallback(function(player, code)
	local codeReward = if codes:FindFirstChild(code) then codes[code].Value else nil
	if not codeReward then
		if expiredCodes and expiredCodes[code] then
			return "Code expired"
		end
		return "Invalid code"
	end
	if not selectors.hasRedeemedCode(store:getState(), player.Name, code) then
		awardItem(player, codeReward)
		store:dispatch(actions.redeemCode(player.Name, code))
		return "Code redeemed"
	end
	return "Code already redeemed"
end)

task.spawn(function()
	success, expiredCodes = pcall(expiredCodeDataStore.GetAsync, expiredCodeDataStore, "ExpiredCodes")
	while not success do
		task.wait(30)
		success, expiredCodes = pcall(expiredCodeDataStore.GetAsync, expiredCodeDataStore, "ExpiredCodes")
	end

	local foundMissingCode = false
	if not expiredCodes then
		expiredCodes = {}
	end

	for _, code in codes:GetChildren() do
		if not expiredCodes[code.Name] then
			expiredCodes[code.Name] = code.Value
			foundMissingCode = true
		end
	end

	if not foundMissingCode then
		return
	end

	success = pcall(expiredCodeDataStore.SetAsync, expiredCodeDataStore, "ExpiredCodes", expiredCodes)
	while not success do
		task.wait(30)
		success = pcall(expiredCodeDataStore.SetAsync, expiredCodeDataStore, "ExpiredCodes", expiredCodes)
	end
end)

return 0
