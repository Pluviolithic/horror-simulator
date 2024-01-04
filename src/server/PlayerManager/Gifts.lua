local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local rankUtils = require(ReplicatedStorage.Common.Utils.RankUtils)
local count = require(ReplicatedStorage.Common.lib.Sift).Dictionary.count
local productRewarders = require(ServerScriptService.Server.PurchaseManager.DeveloperProducts.Products.Rewarders)

local packIDs = ReplicatedStorage.Config.DevProductData.Packs
local giftTimers = ReplicatedStorage.Config.Gifts.Timers
local giftCount = #giftTimers:GetChildren()

Remotes.Server:Get("ClaimGift"):Connect(function(player, giftName)
	local giftTimer = giftTimers:FindFirstChild(giftName)
	if not giftTimer then
		return
	end

	if
		os.time() - selectors.getStat(store:getState(), player.Name, "GiftCycleBeganTimestamp")
			< giftTimer.Value * 60
		and not selectors.skippedGiftTimers(store:getState(), player.Name)
	then
		return
	end

	if selectors.hasClaimedGift(store:getState(), player.Name, giftName) then
		return
	end

	store:dispatch(actions.claimGift(player.Name, giftName))
	store:dispatch(actions.setPlayerStat(player.Name, "LastClaimedAGiftTimestamp", os.time()))

	if giftName:match "Pack" then
		productRewarders[packIDs:FindFirstChild(giftName, true).Value](player)
	elseif giftName:match "Boost" then
		store:dispatch(actions.applyBoostToPlayer(player.Name, giftName))
		Remotes.Server
			:Get("SendPopupMessage")
			:SendToPlayer(
				player,
				`You Have Received A {giftName:match "(%u.+)%u"} Boost!`,
				Color3.fromRGB(250, 250, 250)
			)
	elseif giftName:match "Pet" then
		local petValue = ReplicatedStorage.Config.Gifts[giftName]
		local areaName = rankUtils.getBestUnlockedArea(selectors.getStat(store:getState(), player.Name, "Strength"))
		areaName = areaName:gsub(" ", "_")
		store:dispatch(actions.givePlayerPets(player.Name, { [petValue:GetAttribute(areaName)] = 1 }))

		Remotes.Server:Get("SendPopupMessage"):SendToPlayer(
			player,
			`You Have Received The {petValue:GetAttribute(areaName)} Pet!`,
			Color3.fromRGB(250, 250, 250)
		)
	end
end)

task.spawn(function()
	while true do
		for _, player in Players:GetPlayers() do
			if not selectors.isPlayerLoaded(store:getState(), player.Name) then
				continue
			end
			local redeemedGiftCount = count(selectors.getClaimedGifts(store:getState(), player.Name))
			if
				redeemedGiftCount == giftCount
				and os.time() - selectors.getStat(store:getState(), player.Name, "LastClaimedAGiftTimestamp")
					> 16 * 60 * 60
			then
				store:dispatch(actions.resetGifts(player.Name))
				store:dispatch(actions.setPlayerStat(player.Name, "GiftCycleBeganTimestamp", os.time()))
			end
		end
		task.wait(1)
	end
end)

return 0
