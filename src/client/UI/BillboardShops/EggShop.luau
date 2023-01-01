local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value

local eggGemPrice: number = 50
-- eventually add to config folder
local maxActivationDistance: number = 15

local listeners: { [BillboardGui]: (Enum.KeyCode) -> () } = {}
local validInputs: { [Enum.KeyCode]: boolean } = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.R] = true,
	[Enum.KeyCode.T] = true,
}

local function handlePurchaseResults(rewards: { string }?): ()
	if not rewards then
		return
	end
end

local function handleShop(shop): ()
	local areaName: string = shop.Name:sub(1, -5)
	local debounce: boolean = true
	local function buyEgg(count: number, auto: boolean): ()
		if not debounce then
			return
		end
		debounce = false
		task.delay(0.5, function()
			debounce = true
		end)

		local playerState = store:getState().Players[player.Name]

		if playerState.Gems < eggGemPrice * count then
			return
		end

		if count == 1 then
			print("buying " .. tostring(count) .. " eggs; isauto: " .. tostring(auto))
			handlePurchaseResults(Remotes.Client:Get("HatchEggs"):CallServerAsync(count, auto, areaName))
			return
		end

		local success, message = pcall(MarketplaceService.HasPass, MarketplaceService, tripleHatchGamepassID)
		if not success then
			warn("Failed to verify 3x gamepass ownership: " .. message)
			return
		end

		local realCount: number = count
		if count == 3 then
			if not message then
				MarketplaceService:PromptGamePassPurchase(player, tripleHatchGamepassID)
			end
		elseif auto then
			-- verify user has the auto gamepass here
			if message then
				realCount = 3
			end
		end

		print("buying " .. tostring(realCount) .. " eggs; isauto: " .. tostring(auto))

		handlePurchaseResults(Remotes.Client:Get("HatchEggs"):CallServerAsync(realCount, auto, areaName))
	end

	shop.Background.Open1.Activated:Connect(function()
		buyEgg(1, false)
	end)

	shop.Background.Open3.Activated:Connect(function()
		buyEgg(3, false)
	end)

	shop.Background.Auto.Activated:Connect(function()
		buyEgg(1, true)
	end)

	listeners[shop] = function(keyCode: Enum.KeyCode): ()
		print("Egg shop interacted with via the " .. tostring(keyCode) .. " key")
		if keyCode == Enum.KeyCode.E then
			buyEgg(1, false)
		elseif keyCode == Enum.KeyCode.R then
			buyEgg(3, false)
		else
			buyEgg(1, true)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not validInputs[input.KeyCode] then
		return
	end

	for shop in listeners do
		if shop.CurrentDistance <= maxActivationDistance then
			listeners[shop](input.KeyCode)
			break
		end
	end
end)

Remotes.Client:Get("AutoHatchResponse"):Connect(function(rewards: { string })
	handlePurchaseResults(rewards)
end)

for _, shop in CollectionService:GetTagged "EggShop" do
	handleShop(shop)
end
CollectionService:GetInstanceAddedSignal("EggShop"):Connect(handleShop)

return 0
