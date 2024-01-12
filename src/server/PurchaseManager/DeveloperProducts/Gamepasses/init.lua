local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"
local ServerScriptService = game:GetService "ServerScriptService"

local rewarders = require(script.Rewarders)
local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(ServerScriptService.Server.State.Store)
local actions = require(ServerScriptService.Server.State.Actions)
local selectors = require(ReplicatedStorage.Common.State.selectors)

local gamepassNames = ReplicatedStorage.Config.GamepassData.GamepassNames

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
			if not err then
				continue
			end
			if typeof(rewarder) == "function" then
				if pcall(rewarder, player) then
					store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
				end
			else
				store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
			end
			Remotes.Server
				:Get("SendPopupMessage")
				:SendToPlayer(
					player,
					`You have Received {gamepassNames[gamepassID].Value}!`,
					Color3.fromRGB(250, 250, 250)
				)
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

	Remotes.Server
		:Get("SendPopupMessage")
		:SendToPlayer(player, `You have Received {gamepassNames[gamepassID].Value}!`, Color3.fromRGB(250, 250, 250))

	if typeof(rewarders[gamepassID]) == "function" then
		store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
		return pcall(rewarders[gamepassID], player)
	else
		store:dispatch(actions.awardGamepassToPlayer(player.Name, gamepassID))
		return true
	end
end
