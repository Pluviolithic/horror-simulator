local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"
local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Janitor = require(ReplicatedStorage.Common.lib.Janitor)
local Promise = require(ReplicatedStorage.Common.lib.Promise)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local playerStatePromise = require(StarterPlayer.StarterPlayerScripts.Client.State.PlayerStatePromise)

local autoHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["AutoHatch"].Value
local tripleHatchGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3xHatch"].Value
local doubleLuckGamepassID = ReplicatedStorage.Config.GamepassData.IDs["2xLuck"].Value
local tripleLuckGamepassID = ReplicatedStorage.Config.GamepassData.IDs["3xLuck"].Value

local hatchingUI = player.PlayerGui:WaitForChild "Hatching"

-- eventually add most of these to a config folder
--local hatchTime = 3
local hatching = false
local hatchDisplayTime = 4
local maxActivationDistance = 15
local movementConnection = nil
local hatchingTweensJanitor = Janitor.new()

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

local tweens = {
	darkBackgroundOnTween = TweenService:Create(hatchingUI.DarkScreen, TweenInfo.new(0.5), {
		BackgroundTransparency = 0.75,
	}),
	darkBackgroundOffTween = TweenService:Create(hatchingUI.DarkScreen, TweenInfo.new(0.5), {
		BackgroundTransparency = 1,
	}),
	whiteScreenFlashTween = TweenService:Create(
		hatchingUI.Flash,
		TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true, 0),
		{
			BackgroundTransparency = 0,
		}
	),
}

local function createEggShakeTween(egg: GuiObject, rotation): Tween
	return TweenService:Create(egg, TweenInfo.new(0.1), {
		Rotation = rotation,
	})
end

local function enableAndSpinRarityBackground(petUI: GuiObject, rarity: string)
	for _, rarityBackground in petUI:GetChildren() do
		if not rarityBackground.Name:match "Background" then
			continue
		end

		if not rarityBackground.Name:match(rarity) then
			rarityBackground.Visible = false
		else
			rarityBackground.Rotation = 0
			rarityBackground.Visible = true
			local tween = TweenService:Create(
				rarityBackground,
				TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0),
				{
					Rotation = 360,
				}
			)
			hatchingTweensJanitor:Add(tween)
			tween:Play()
		end
	end
end

local function displayAreaSubUI(ui, areaName)
	for _, subUI in ui:GetChildren() do
		if subUI.Name ~= areaName then
			subUI.Visible = false
		end
	end
end

local function createAndStartShakes(eggImages: { GuiObject }): ()
	for _, eggImage in eggImages do
		local onTween = createEggShakeTween(eggImage, 20)
		local offTween = createEggShakeTween(eggImage, -10)
		hatchingTweensJanitor:Add(onTween)
		hatchingTweensJanitor:Add(offTween)
		hatchingTweensJanitor:Add(onTween.Completed:Connect(function()
			offTween:Play()
		end))
		hatchingTweensJanitor:Add(offTween.Completed:Connect(function()
			onTween:Play()
		end))
		onTween:Play()
		eggImage.Visible = true
	end
end

local function createSizeTween(constraint: UISizeConstraint, size: number, tweenTime: number): Tween
	return TweenService:Create(constraint, TweenInfo.new(tweenTime), {
		MinSize = size,
	})
end

local function configureHatchUI(asyncResults, single: boolean, areaName: string): typeof(Promise.new())
	return Promise.new(function(resolve)
		local currentPrimaryRegion = selectors.getAudioData(store:getState(), player.Name).PrimarySoundRegion
		local modifiedHatchDisplayTime = if selectors.hasGamepass(store:getState(), player.Name, "FasterHatch")
			then hatchDisplayTime / 2.4651
			else hatchDisplayTime

		hatchingUI.Enabled = true

		displayAreaSubUI(hatchingUI.Single, currentPrimaryRegion)
		displayAreaSubUI(hatchingUI.Triple, currentPrimaryRegion)

		tweens.darkBackgroundOnTween:Play()

		local uiToShow
		if single then
			uiToShow = hatchingUI.Single
			hatchingUI.Triple.Visible = false
			hatchingUI.Single.Visible = true
		else
			uiToShow = hatchingUI.Triple
			hatchingUI.Triple.Visible = true
			hatchingUI.Single.Visible = false
		end

		task.wait(0.5)
		uiToShow[currentPrimaryRegion].Visible = true
		createAndStartShakes(uiToShow[currentPrimaryRegion]:GetChildren())
		task.wait(modifiedHatchDisplayTime)
		hatchingTweensJanitor:Cleanup()

		for _, eggImage in uiToShow[currentPrimaryRegion]:GetChildren() do
			eggImage.Rotation = 0
			eggImage.Visible = false
		end

		tweens.whiteScreenFlashTween:Play()
		task.wait(0.25)

		local oldMinSize = uiToShow["Pet" .. 1].UISizeConstraint.MinSize
		asyncResults:andThen(function(results)
			if not results then
				resolve(true)
				return
			end
			local detailedResults = {}

			for _, petName in results do
				table.insert(detailedResults, ReplicatedStorage.Pets[areaName][petName])
			end

			for i, pet in detailedResults do
				uiToShow["Pet" .. i].PetImage.Image = pet.ImageID.Value
				uiToShow["Pet" .. i].PetName.Text = pet.Name
				uiToShow["Pet" .. i].Rarity.Text = pet.RarityName.Value
				uiToShow["Pet" .. i].Rarity.TextColor3 = rarityColorConfig[pet.RarityName.Value].Value

				uiToShow["Pet" .. i].Visible = true

				local sizeTween = createSizeTween(
					uiToShow["Pet" .. i].UISizeConstraint,
					uiToShow["Pet" .. i].UISizeConstraint.MaxSize,
					0.5
				)
				sizeTween:Play()
				enableAndSpinRarityBackground(uiToShow["Pet" .. i], pet.RarityName.Value)
				hatchingTweensJanitor:Add(sizeTween)
			end

			task.wait(modifiedHatchDisplayTime)

			local lastSizeTween
			for i in detailedResults do
				local sizeTween = createSizeTween(uiToShow["Pet" .. i].UISizeConstraint, oldMinSize, 0.25)
				sizeTween:Play()
				lastSizeTween = sizeTween
				hatchingTweensJanitor:Add(sizeTween)
			end

			lastSizeTween.Completed:Wait()
			hatchingTweensJanitor:Cleanup()
			hatchingUI.Enabled = false

			resolve()
		end)
	end)
end

function displayPurchaseResults(asyncResults, areaName: string, count: number, auto: boolean): ()
	if
		not asyncResults
		or (selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + count)
			> selectors.getStat(store:getState(), player.Name, "MaxPetCount")
	then
		warn "Failed to purchase eggs"
		return
	end

	local eggGemPrice = eggGemPricesConfig[areaName].Value
	local canAffordThree = selectors.getStat(store:getState(), player.Name, "Gems") >= eggGemPrice * 3

	configureHatchUI(asyncResults, count == 1 or not canAffordThree, areaName):andThen(function(failed: boolean?)
		if failed then
			hatching = false
			return
		end
		if auto and autoLastEnabled > autoLastDisabled then
			if
				selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + count
					> selectors.getStat(store:getState(), player.Name, "MaxPetCount")
				or selectors.getStat(store:getState(), player.Name, "Gems") < count * eggGemPrice
			then
				hatching = false
				return
			end
			displayPurchaseResults(
				Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName),
				areaName,
				count,
				auto
			)
		else
			hatching = false
		end
	end)
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
		elseif autoLastEnabled > autoLastDisabled then
			autoLastDisabled = os.time()
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
			displayPurchaseResults(Remotes.Client:Get("HatchEggs"):CallServerAsync(1, areaName), areaName, count, auto)
			return
		end

		if count == 3 and not selectors.hasGamepass(store:getState(), player.Name, "3xHatch") then
			MarketplaceService:PromptGamePassPurchase(player, tripleHatchGamepassID)
			hatching = false
			return
		end

		if auto and not selectors.hasGamepass(store:getState(), player.Name, "AutoHatch") then
			MarketplaceService:PromptGamePassPurchase(player, autoHatchGamepassID)
			hatching = false
			return
		end

		if auto then
			if
				selectors.hasGamepass(store:getState(), player.Name, "3xHatch")
				and (selectors.getStat(store:getState(), player.Name, "CurrentPetCount") + 3)
					<= selectors.getStat(store:getState(), player.Name, "MaxPetCount")
			then
				count = 3
			else
				count = 1
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
		displayPurchaseResults(Remotes.Client:Get("HatchEggs"):CallServerAsync(count, areaName), areaName, count, auto)
	end

	table.insert(rarityListeners, function(luck: number): ()
		if luck == 0 then
			for _, petUI in shop.Background.Pets:GetChildren() do
				petUI.RarityText.Text =
					string.format("%.1f%%", ReplicatedStorage.Pets[areaName][petUI.Name].Rarity.Value)
			end
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
		if petName:match "Evolved" then
			continue
		end

		local eggUI = player.PlayerGui:FindFirstChild(petAreas[petName] .. "EggUI")

		if not eggUI then
			continue
		end

		local petUI = eggUI.Background.Pets[petName]
		petUI.PetName.Text = petName
		petUI.PetImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
		petUI.PetImage.ImageTransparency = 0
	end
end

local function updateRarityListeners(luck: number): ()
	if selectors.getActiveBoosts(store:getState(), player.Name)["LuckBoost"] then
		luck += 5
	end
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

		if
			selectors.getStat(newState, player.Name, "Luck") ~= selectors.getStat(oldState, player.Name, "Luck")
			or selectors.getActiveBoosts(newState, player.Name)["LuckBoost"]
				~= selectors.getActiveBoosts(oldState, player.Name)["LuckBoost"]
		then
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

return 0
