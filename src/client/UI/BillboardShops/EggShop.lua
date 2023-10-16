local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local autoHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["Auto"].Value
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value
local fasterHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["FasterHatch"].Value
local doubleLuckGamepassID = ReplicatedStorage.Config.GamepassData.IDs["2XLuck"].Value
local tripleLuckGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3XLuck"].Value

local hatchingUI = player.PlayerGui:WaitForChild "Hatching"

-- eventually add most of these to a config folder
local hatchTime: number = 3
local hatching: boolean = false
local hatchDisplayTime: number = 4
local maxActivationDistance: number = 15
local movementConnection: RBXScriptConnection = nil

local autoLastEnabled = -1
local autoLastDisabled = 0

local rarityColorConfig = ReplicatedStorage.Config.RarityColors
local eggGemPricesConfig = ReplicatedStorage.Config.Pets.Prices

local petAreas = {}
local rarityListeners = {}
local listeners = {}
local validInputs = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.R] = true,
	[Enum.KeyCode.T] = true,
}
local luckBoostedRarities = {
	Rare = true,
	Epic = true,
	Legendary = true,
}

local function configureHatchUI(detailedResults: { any }, single: boolean): ()
	task.wait(hatchTime)

	if single then
		local pet = detailedResults[1]
		hatchingUI.Single.Pet.PetImage.Image = pet.ImageID.Value
		hatchingUI.Single.Pet.PetName.Text = pet.Name
		hatchingUI.Single.Pet.Rarity.Text = pet.RarityName.Value
		hatchingUI.Single.Pet.Rarity.TextColor3 = rarityColorConfig[pet.RarityName.Value].Value

		hatchingUI.Single.Visible = true
		hatchingUI.Triple.Visible = false

		hatchingUI.Enabled = true
		task.wait(hatchDisplayTime)
		hatchingUI.Enabled = false
		hatching = false
		return
	end

	for i, pet in detailedResults do
		hatchingUI.Triple["Pet" .. i].PetImage.Image = pet.ImageID.Value
		hatchingUI.Triple["Pet" .. i].PetName.Text = pet.Name
		hatchingUI.Triple["Pet" .. i].Rarity.Text = pet.RarityName.Value
		hatchingUI.Triple["Pet" .. i].Rarity.TextColor3 = rarityColorConfig[pet.RarityName.Value].Value

		hatchingUI.Triple.Visible = true
		hatchingUI.Single.Visible = false
	end

	hatchingUI.Enabled = true
	task.wait(hatchDisplayTime)
	hatchingUI.Enabled = false
end

function displayPurchaseResults(results: { string }?, areaName: string, count: number, auto: boolean): ()
	if not results then
		warn "Failed to purchase eggs"
		return
	end

	local detailedResults = {}

	for _, petName in results do
		table.insert(detailedResults, ReplicatedStorage.Pets[areaName][petName])
	end

	if #results == 1 then
		configureHatchUI(detailedResults, true)
	elseif #results == 3 then
		configureHatchUI(detailedResults, false)
	end

	if auto and autoLastEnabled > autoLastDisabled then
		local eggGemPrice = eggGemPricesConfig[areaName].Value
		if
			selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + count
				> selectors.getStat(store:getState(), player.Name, "MaxPetCount")
			or selectors.getStat(store:getState(), player.Name, "Gems") < count * eggGemPrice
		then
			hatching = false
			return
		end
		Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName):andThen(function(newResults: { string }?)
			displayPurchaseResults(newResults, areaName, count, auto)
		end)
	else
		hatching = false
	end
end

local function handleShop(shop): ()
	local areaName = shop.Name:sub(1, -6)
	local debounce = true
	local eggGemPrice = eggGemPricesConfig[areaName].Value
	local function buyEgg(count: number, auto: boolean): ()
		if not debounce then
			return
		end
		debounce = false
		task.delay(0.5, function()
			debounce = true
		end)

		if auto then
			if autoLastEnabled > autoLastDisabled then
				if movementConnection then
					movementConnection:Disconnect()
				end
				autoLastDisabled = os.time()
				return
			else
				autoLastEnabled = os.time()
			end
		end

		if hatching then
			return
		end

		if selectors.getStat(store:getState(), player.Name, "Gems") < eggGemPrice * count then
			hatching = false
			return
		end

		hatching = true

		if
			selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + count
			> selectors.getStat(store:getState(), player.Name, "MaxPetCount")
		then
			hatching = false
			return
		end

		if (count == 1 or selectors.getStat(store:getState(), player.Name, "Gems") < eggGemPrice * 3) and not auto then
			Remotes.Client:Get("HatchEggs"):CallServerAsync(1, areaName):andThen(function(results)
				displayPurchaseResults(results, areaName, count, auto)
			end)
			return
		end

		local success, message =
			pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, tripleHatchGamepassID)
		if not success then
			warn("Failed to verify 3x gamepass ownership: " .. message)
			hatching = false
			return
		end

		if count == 3 then
			if not message then
				MarketplaceService:PromptGamePassPurchase(player, tripleHatchGamepassID)
				hatching = false
				return
			end
		end

		if auto then
			count = if success and message then 3 else 1
			success, message =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, autoHatchGamepassID)
			if not success then
				warn("Failed to verify auto hatch gamepass ownership: " .. message)
				hatching = false
				return
			elseif success and not message then
				MarketplaceService:PromptGamePassPurchase(player, autoHatchGamepassID)
				hatching = false
				return
			end
		end

		local t = 0
		movementConnection = RunService.RenderStepped:Connect(function(delta)
			t += delta
			if t < 1 then
				return
			end
			t = 0
			if player:DistanceFromCharacter(shop.Adornee.Position) > maxActivationDistance then
				if auto then
					if autoLastEnabled > autoLastDisabled then
						autoLastDisabled = os.time()
					else
						autoLastEnabled = os.time()
					end
				end
				movementConnection:Disconnect()
				hatching = false
			end
		end)

		Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName):andThen(function(results: { string }?)
			displayPurchaseResults(results, areaName, count, auto)
		end)
	end

	table.insert(rarityListeners, function(luck: number): ()
		if luck == 0 then
			return
		end

		local petUIs = shop.Background.Pets:GetChildren()
		local petFolder = ReplicatedStorage.Pets[areaName]
		local normalRarity = 0
		local boostedRarity = 0
		local boostedPetCount = 0

		for _, petUI in petUIs do
			local rarity = petFolder[petUI.Name].Rarity.Value

			if not luckBoostedRarities[petFolder[petUI.Name].RarityName.Value] then
				continue
			end

			normalRarity += rarity
			boostedPetCount += 1
			boostedRarity += rarity * luck

			petUI.RarityText.Text = string.format("%.1f%%", rarity * luck):gsub("%.0", "")
		end

		local rarityReduceAmount = (boostedRarity - normalRarity) / (#petUIs - boostedPetCount)
		for _, petUI in shop.Background.Pets:GetChildren() do
			if luckBoostedRarities[petFolder[petUI.Name].RarityName.Value] then
				continue
			end

			petUI.RarityText.Text =
				string.format("%.1f%%", petFolder[petUI.Name].Rarity.Value - rarityReduceAmount):gsub("%.0", "")
		end
	end)

	shop.Background.Open1.Activated:Connect(function()
		buyEgg(1, false)
	end)

	shop.Background.Open3.Activated:Connect(function()
		buyEgg(3, false)
	end)

	shop.Background.Auto.Activated:Connect(function()
		buyEgg(1, true)
	end)

	shop.Background["2xLuck"].Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, doubleLuckGamepassID)
	end)

	shop.Background["3xLuck"].Activated:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, tripleLuckGamepassID)
	end)

	listeners[shop] = function(keyCode: Enum.KeyCode): ()
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
		if player:DistanceFromCharacter(shop.Adornee.Position) <= maxActivationDistance then
			listeners[shop](input.KeyCode)
			break
		end
	end
end)

for _, petArea in ReplicatedStorage.Pets:GetChildren() do
	for _, pet in petArea:GetChildren() do
		petAreas[pet.Name] = petArea.Name
		petAreas["Evolved " .. pet.Name] = petArea.Name
	end
end

for _, shop in CollectionService:GetTagged "EggShop" do
	handleShop(shop)
end
CollectionService:GetInstanceAddedSignal("EggShop"):Connect(handleShop)

local function updateFoundsDisplay(foundPets): ()
	for petName in foundPets do
		local petUI = player.PlayerGui:WaitForChild(petAreas[petName] .. "EggUI").Background.Pets[petName]
		petUI.PetName.Text = petName
		petUI.PetImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
		petUI.PetImage.ImageTransparency = 0
	end
end

local function updateRarityListeners(luck: number): ()
	for _, listener in rarityListeners do
		listener(luck)
	end
end

playerStatePromise:andThen(function()
	updateRarityListeners(selectors.getStat(store:getState(), player.Name, "Luck"))
	updateFoundsDisplay(selectors.getFoundPets(store:getState(), player.Name))

	store.changed:connect(function(newState, oldState)
		if not selectors.isPlayerLoaded(oldState, player.Name) then
			return
		end

		if selectors.getStat(newState, player.Name, "Luck") ~= selectors.getStat(oldState, player.Name, "Luck") then
			updateRarityListeners(selectors.getStat(newState, player.Name, "Luck"))
		end

		if selectors.getFoundPets(newState, player.Name) == selectors.getFoundPets(oldState, player.Name) then
			return
		end

		task.delay(3.5, function()
			updateFoundsDisplay(selectors.getFoundPets(newState, player.Name))
		end)
	end)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(
	function(purchasingPlayer: Player, gamePassID: number, purchased: boolean)
		if purchasingPlayer ~= player then
			return
		end
		if gamePassID == fasterHatchGamepassID and purchased then
			hatchTime = 1.5
		end
	end
)

task.spawn(function()
	local success, err =
		pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, fasterHatchGamepassID)
	if success and err then
		hatchTime = 1.5
	end
end)

return 0
