local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

Remotes.Server:Get("ClaimGift"):Connect(function(player, giftName)
	local giftTimer = ReplicatedStorage.Config.Gifts:FindFirstChild(giftName)
	if not giftTimer then
		return
	end

	if os.time() - selectors.getStat(store:getState(), player.Name, "LastLogOn") < giftTimer.Value then
		return
	end

	if selectors.hasClaimedGift(store:getState(), player.Name, giftName) then
		return
	end

	store:dispatch(actions.claimGift(player.Name, giftName))
end)

return 0
