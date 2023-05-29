local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rewarders = require(script.Rewarders)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local function checkIfObtainedRewards(player: Player)
	if not selectors.isPlayerLoaded(store:getState(), player.Name) then
		local connection
		local thread = coroutine.running()
		connection = store.changed:connect(function(newState)
			if selectors.isPlayerLoaded(newState, player.Name) then
				connection:disconnect()
				coroutine.resume(thread)
			end
		end)
		coroutine.yield()
	end

	for gamepassID, rewarder in rewarders do
		if not selectors.hasGamepass(store:getState(), player.Name, gamepassID) then
			local success, err =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, tonumber(gamepassID))
			if not success then
				warn(err)
				continue
			end
			if err then
				if pcall(rewarder, player) then
					store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
				end
			end
		end
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(function()
		checkIfObtainedRewards(player)
	end)
end
Players.PlayerAdded:Connect(checkIfObtainedRewards)

return function(player: Player, gamepassID: number): (boolean, string?)
	if not rewarders[tostring(gamepassID)] then
		return false
	end

	return pcall(rewarders[tostring(gamepassID)], player)
end
