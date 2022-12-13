local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local MarketplaceService = game:GetService "MarketplaceService"

local player = Players.LocalPlayer

local Remotes = require(ReplicatedStorage.Common.Remotes)
local Table = require(ReplicatedStorage.Common.Utils.Table)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)
local CentralUI = require(StarterPlayer.StarterPlayerScripts.Client.UI.CentralUI)

local WeaponShop = CentralUI.new(player.PlayerGui:WaitForChild "WeaponShop")
local gamepassPrices = ReplicatedStorage.Config.GamepassPrices

WeaponShop.Trigger = "WeaponShop"
WeaponShop._itemButtons = WeaponShop._ui.LeftBackground.ScrollingFrame:GetChildren()

function WeaponShop:_initialize()
	store.changed:connect(function(newState, oldState)
		if not self._isOpen then
			return
		end
		local newPlayerState = newState.GameState.Players[player.Name]
		local oldPlayerState = oldState.GameState.Players[player.Name]
		if
			newPlayerState.EquippedWeapon ~= oldPlayerState.EquippedWeapon
			or not Table.ShallowIsEqual(newPlayerState.OwnedWeapons, oldPlayerState.OwnedWeapons)
		then
			WeaponShop:Refresh()
		end
	end)

	for _, button in ipairs(WeaponShop._itemButtons) do
		if button:IsA "UIGridLayout" then
			continue
		end

		button.Activated:Connect(function()
			local playerState = store:getState().GameState.Players[player.Name]
			local focusedDisplay = WeaponShop._ui.RightBackground

			if button:FindFirstChild "Locked" and button.Locked.Visible then
				return
			end

			self:ClearFocusedDisplay()

			focusedDisplay.WeaponImage.Image = button.WeaponImage.Image
			focusedDisplay.WeaponImage.Visible = true

			focusedDisplay.WeaponName.Text = button.WeaponName.Text
			focusedDisplay.WeaponName.Visible = true

			focusedDisplay.Damage.Text = button.Damage.Value
			focusedDisplay.Damage.Visible = true
			focusedDisplay.DamageIcon.Visible = true

			if playerState.OwnedWeapons[button.Name] then
				focusedDisplay.GreenButton.Visible = true
				if playerState.EquippedWeapon == button.Name then
					focusedDisplay.GreenButton.Text.Text = "Equipped"
					return
				end

				focusedDisplay.GreenButton.Text.Text = "Equip"
				self._eventConnections["PurchaseButton"] = focusedDisplay.GreenButton.Activated:Connect(function()
					print "equipping weapon"
					Remotes.Client:Get("EquipWeapon"):CallServerAsync(button.Name)
					print "action complete"
				end)
			else
				if button:FindFirstChild "GamepassText" then
					focusedDisplay.RobuxPrice.Text = if button.Name == "Scythe"
						then gamepassPrices.Scythe.Value
						else gamepassPrices.VIP.Value
					focusedDisplay.RobuxPrice.Visible = true
					focusedDisplay.RobuxIcon.Visible = true

					focusedDisplay.GreenButton.Text.Text = "Purchase"
					focusedDisplay.GreenButton.Visible = true

					self._eventConnections["PurchaseButton"] = focusedDisplay.GreenButton.Activated:Connect(function()
						print "purchasing gamepass"
						MarketplaceService:PromptGamePassPurchase(player, button.ID.Value)
					end)
				else
					focusedDisplay.GemPrice.Text = button.GemPrice.Text
					focusedDisplay.GemPrice.Visible = true
					focusedDisplay.GemIcon.Visible = true

					focusedDisplay.GreenButton.Text.Text = "Purchase"
					focusedDisplay.GreenButton.Visible = true
					self._eventConnections["PurchaseButton"] = focusedDisplay.GreenButton.Activated:Connect(function()
						print "purchasing weapon"
						Remotes.Client:Get("PurchaseWeapon"):CallServerAsync(button.Name)
						print "transaction complete"
					end)
				end
			end
		end)
	end
end

function WeaponShop:ClearFocusedDisplay()
	local focusedDisplay = self._ui.RightBackground
	focusedDisplay.WeaponName.Visible = false
	focusedDisplay.WeaponImage.Visible = false

	focusedDisplay.GemPrice.Visible = false
	focusedDisplay.GemIcon.Visible = false

	focusedDisplay.RobuxPrice.Visible = false
	focusedDisplay.RobuxIcon.Visible = false

	focusedDisplay.Damage.Visible = false
	focusedDisplay.DamageIcon.Visible = false

	focusedDisplay.GreenButton.Visible = false

	if self._eventConnections["PurchaseButton"] then
		self._eventConnections["PurchaseButton"]:Disconnect()
	end
end

function WeaponShop:Refresh()
	local playerState = store:getState().GameState.Players[player.Name]
	local restAreLocked = false

	self:ClearFocusedDisplay()

	for _, button in ipairs(self._itemButtons) do
		if button:IsA "UIGridLayout" then
			continue
		end

		if playerState.EquippedWeapon == button.Name then
			button.Equipped.Visible = true
		else
			button.Equipped.Visible = false
		end

		if button:FindFirstChild "GamepassText" then
			if playerState.OwnedWeapons[button.Name] then
				button.GamepassText.Visible = false
			end
			continue
		end

		if playerState.OwnedWeapons[button.Name] then
			-- player owns the weapon
			button.Locked.Visible = false
			button.WeaponImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
			button.Icon.Visible = false
			button.GemPrice.Visible = false
			button.WeaponName.Visible = true
		elseif not restAreLocked then
			-- this item is unowned, but it is unlocked
			button.Locked.Visible = false
			button.WeaponImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
			button.WeaponName.Visible = true
			button.GemPrice.Visible = true
			button.Icon.Visible = true
			restAreLocked = true
		else
			-- this item is not unlocked
			button.Locked.Visible = true
			button.WeaponImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
			button.WeaponName.Visible = false
			button.GemPrice.Visible = false
		end
	end
end

function WeaponShop:OnOpen()
	self:Refresh()
end

WeaponShop:_initialize()

return WeaponShop
