local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Zone = require(ReplicatedStorage.Common.lib.ZonePlus)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local zoneUtils = require(ReplicatedStorage.Common.Utils.ZoneUtils)
local clockUtils = require(ReplicatedStorage.Common.Utils.ClockUtils)
local productRewarders = require(ServerScriptService.Server.PurchaseManager.DeveloperProducts.Products.Rewarders)

local packIDs = ReplicatedStorage.Config.DevProductData.Packs
local chestTimerLength = ReplicatedStorage.Config.DevProductData.Chests.ChestTimerLength.Value
local VIPChestZone = Zone.new(zoneUtils.getTaggedForZone "VIPChestHitbox")
local groupChestZone = Zone.new(zoneUtils.getTaggedForZone "GroupChestHitbox")

VIPChestZone:relocate()
groupChestZone:relocate()

-- Award order for group chests: GemBoost > TinyFearPack > DamageBoost > FearBoost > SmallGemPack > FearlessBoost
-- Award order for vip chests: FearBoost > SmallGemPack > DamageBoost > GemBoost > TinyFearPack > FearlessBoost

local vipChestAwards = {
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "FearBoost15"))
	end,
	function(player)
		productRewarders[packIDs.Gems["SmallGemPack"].Value](player)
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "DamageBoost15"))
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "GemsBoost15"))
	end,
	function(player)
		productRewarders[packIDs.Fear["TinyFearPack"].Value](player)
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "FearlessBoost15"))
	end,
}

local groupChestAwards = {
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "GemsBoost15"))
	end,
	function(player)
		productRewarders[packIDs.Fear["TinyFearPack"].Value](player)
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "DamageBoost15"))
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "FearBoost15"))
	end,
	function(player)
		productRewarders[packIDs.Gems["SmallGemPack"].Value](player)
	end,
	function(player)
		Remotes.Server:Get("OpenRobuxShopOnClient"):SendToPlayer(player, "Boosts")
		store:dispatch(actions.incrementPlayerBoostCount(player.Name, "FearlessBoost15"))
	end,
}

VIPChestZone.playerEntered:Connect(function(player)
	if not selectors.hasGamepass(store:getState(), player.Name, "VIP") then
		return
	end
	local chestTimers = selectors.getChestTimers(store:getState(), player.Name)
	if not clockUtils.hasTimeLeft(chestTimers.VIPChest, chestTimerLength) then
		local currentAwardIndex = selectors.getStat(store:getState(), player.Name, "VIPChestAwardIndex")
		store:dispatch(actions.startChestTimer(player.Name, "VIPChest"))
		vipChestAwards[currentAwardIndex](player)
		store:dispatch(
			actions.setPlayerStat(player.Name, "VIPChestAwardIndex", (currentAwardIndex % #vipChestAwards) + 1)
		)
	end
end)

groupChestZone.playerEntered:Connect(function(player)
	if not player:IsInGroup(2855772) then
		return
	end
	local chestTimers = selectors.getChestTimers(store:getState(), player.Name)
	if not clockUtils.hasTimeLeft(chestTimers.GroupChest, chestTimerLength) then
		store:dispatch(actions.startChestTimer(player.Name, "GroupChest"))
		local currentAwardIndex = selectors.getStat(store:getState(), player.Name, "GroupChestAwardIndex")
		groupChestAwards[currentAwardIndex](player)
		store:dispatch(
			actions.setPlayerStat(player.Name, "GroupChestAwardIndex", (currentAwardIndex % #groupChestAwards) + 1)
		)
	end
end)

return 0
