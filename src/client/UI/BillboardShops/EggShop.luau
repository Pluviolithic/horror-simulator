local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local autoHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["Auto"].Value
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3X"].Value

local hatchingUI = player.PlayerGui:WaitForChild "Hatching"

local hatching: boolean = false
local eggGemPrice: number = 50
local hatchDisplayTime: number = 4
-- eventually add to config folder
local maxActivationDistance: number = 15

local rarityColorConfig = ReplicatedStorage.Config.RarityColors

local petAreas: { [string]: string } = {}
local listeners: { [BillboardGui]: (Enum.KeyCode) -> () } = {}
local validInputs: { [Enum.KeyCode]: boolean } = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.R] = true,
	[Enum.KeyCode.T] = true,
}

local function configureHatchUI(detailedResults: { [string]: any }, single: boolean): ()
	task.wait(3)

	if single then
		local petName: string = next(detailedResults) :: string
		hatchingUI.Single.Pet.PetImage.Image = detailedResults[petName].ImageID.Value
		hatchingUI.Single.Pet.PetName.Text = petName
		hatchingUI.Single.Pet.Rarity.Text = detailedResults[petName].RarityName.Value
		hatchingUI.Single.Pet.Rarity.TextColor3 = rarityColorConfig[detailedResults[petName].RarityName.Value].Value

		hatchingUI.Single.Visible = true
		hatchingUI.Triple.Visible = false

		hatchingUI.Enabled = true
		task.wait(hatchDisplayTime)
		hatchingUI.Enabled = false
		hatching = false
		return
	end

	local i: number = 1
	for petName, pet in detailedResults do
		hatchingUI.Triple["Pet" .. i].PetImage.Image = pet.ImageID.Value
		hatchingUI.Triple["Pet" .. i].PetName.Text = petName
		hatchingUI.Triple["Pet" .. i].Rarity.Text = pet.RarityName.Value
		hatchingUI.Triple["Pet" .. i].Rarity.TextColor3 = rarityColorConfig[pet.RarityName.Value].Value

		hatchingUI.Triple.Visible = true
		hatchingUI.Single.Visible = false
		i += 1
	end

	hatchingUI.Enabled = true
	task.wait(hatchDisplayTime)
	hatchingUI.Enabled = false
	hatching = false
end

function displayPurchaseResults(results: { string }?, areaName: string?, count: number?, auto: boolean?): ()
	if not results then
		warn "Failed to purchase eggs"
		return
	end

	local detailedResults = {}

	for _, petName in results :: { string } do
		detailedResults[petName] = ReplicatedStorage.Pets[areaName][petName]
	end

	if #results :: { string } == 1 then
		configureHatchUI(detailedResults, true)
	elseif #results :: { string } == 3 then
		configureHatchUI(detailedResults, false)
	end

	if auto then
		Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName):andThen(function(newResults: { string }?)
			displayPurchaseResults(newResults, areaName, count, auto)
		end)
	end
end

local function handleShop(shop): ()
	local areaName: string = shop.Name:sub(1, -6)
	local debounce: boolean = true
	local function buyEgg(count: number, auto: boolean): ()
		if not debounce or hatching then
			return
		end
		hatching = true
		debounce = false
		task.delay(0.5, function()
			debounce = true
		end)

		local playerState = store:getState().Players[player.Name]

		if playerState.Gems < eggGemPrice * count then
			hatching = false
			return
		end

		if (count == 1 or playerState.Gems < eggGemPrice * 3) and not auto then
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

		Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName):andThen(function(results: { string }?)
			displayPurchaseResults(results, areaName, count, auto)
		end)
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
	if gameProcessed or not validInputs[input.KeyCode] or hatchingUI.Enabled then
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
	end
end

for _, shop in CollectionService:GetTagged "EggShop" do
	handleShop(shop)
end
CollectionService:GetInstanceAddedSignal("EggShop"):Connect(handleShop)

local function updateFoundsDisplay(foundPets): ()
	for petName in foundPets do
		local petUI = player.PlayerGui[petAreas[petName] .. "EggUI"].Background.Pets[petName]
		petUI.PetName.Text = petName
		petUI.PetImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
		petUI.PetImage.ImageTransparency = 0
	end
end

playerStatePromise:andThen(function()
	updateFoundsDisplay(store:getState().Players[player.Name].FoundPets)
	store.changed:connect(function(newState, oldState)
		if newState.Players[player.Name].FoundPets == oldState.Players[player.Name].FoundPets then
			return
		end
		task.delay(3.5, function()
			updateFoundsDisplay(newState.Players[player.Name].FoundPets)
		end)
	end)
end)

return 0
