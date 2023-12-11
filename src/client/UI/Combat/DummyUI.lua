local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local DescriptionUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.DescriptionUI)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local preAFKFear = 0
local player = Players.LocalPlayer
local DummyUI = player.PlayerGui:WaitForChild "AFKUI"

local gamepassIDs = ReplicatedStorage.Config.GamepassData.IDs

Remotes.Client:Get("SendFightInfo"):Connect(function(info)
	if not info.IsDummy or not selectors.getCurrentTarget(store:getState(), player.Name) then
		return
	end

	DummyUI.Counter.Text = 'Fear Gained: <font color= "rgb(255, 207, 56)">0</font>'
	DummyUI.Enabled = true
end)

playerStatePromise:andThen(function()
	local lastFearGained = 0
	store.changed:connect(function(newState)
		if selectors.hasGamepass(newState, player.Name, "2xFear") then
			DummyUI.Passes["2xFear"].Visible = false
		end

		if selectors.hasGamepass(newState, player.Name, "2xAttackSpeed") then
			DummyUI.Passes["2xAttackSpeed"].Visible = false
		end

		local currentEnemy = selectors.getCurrentTarget(newState, player.Name)
		if not currentEnemy and DummyUI.Enabled then
			DummyUI.Enabled = false
			DummyUI.Counter.Text = ""
			preAFKFear = selectors.getStat(newState, player.Name, "Fear")
			return
		elseif not currentEnemy then
			preAFKFear = selectors.getStat(newState, player.Name, "Fear")
			return
		end

		if not CollectionService:HasTag(currentEnemy, "Dummy") then
			return
		end

		local fearGained = selectors.getStat(newState, player.Name, "Fear") - preAFKFear
		formatter.tweenFormattedTextNumber(DummyUI.Counter, {
			lastFearGained,
			fearGained,
			0.5,
			function(n)
				return `Fear Gained: <font color="rgb(255, 207, 56)">{formatter.formatNumberWithSuffix(n)}</font>`
			end,
		})
		lastFearGained = fearGained
	end)
end)

DummyUI.Passes["2xFear"].Activated:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xFear"].Value)
end)

DummyUI.Passes["2xAttackSpeed"].Activated:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, gamepassIDs["2xAttackSpeed"].Value)
end)

DescriptionUI(DummyUI.Passes["2xFear"], DummyUI.Passes["2xFear"].Frame)
DescriptionUI(DummyUI.Passes["2xAttackSpeed"], DummyUI.Passes["2xAttackSpeed"].Frame)

return 0
