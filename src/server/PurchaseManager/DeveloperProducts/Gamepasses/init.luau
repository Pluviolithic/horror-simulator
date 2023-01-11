local Players = game:GetService "Players"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rewarders = require(script.Rewarders)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)

local function checkIfObtainedRewards(player: Player)
	local playerState = store:getState().Players[player.Name]
	if not playerState or not playerState.AwardedGamepasses then
		local connection
		local thread = coroutine.running()
		connection = store.changed:connect(function(newState)
			if newState.Players[player.Name].AwardedGamepasses then
				connection:disconnect()
				coroutine.resume(thread)
			end
		end)
		coroutine.yield()
		playerState = store:getState().Players[player.Name]
	end

	for gamepassID, rewarder in rewarders do
		if not playerState.AwardedGamepasses[gamepassID] then
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
	if not rewarders[gamepassID] then
		return false
	end

	return pcall(rewarders[gamepassID], player)
end
