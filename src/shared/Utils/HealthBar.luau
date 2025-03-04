local ReplicatedStorage = game:GetService "ReplicatedStorage"

local HealthBar = {}
HealthBar.__index = HealthBar

local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local robloxHealthGreen = Color3.fromRGB(0, 255, 17)
local robloxHealthRed = Color3.fromRGB(255, 0, 0)

function HealthBar.new(bar: Frame)
	return setmetatable({
		_healthBar = bar:FindFirstChild "Health",
		_healthBarText = bar:FindFirstChild "HP",
		_healthBarConnection = nil,
	}, HealthBar)
end

function HealthBar:resize(health: number, maxHealth: number)
	self._healthBar:TweenSize(
		UDim2.fromScale(health / maxHealth, 1),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Linear,
		0.5,
		true
	)
end

function HealthBar:updateText(health: number, maxHealth: number)
	self._healthBarText.Text = formatter.formatNumberWithSuffix(health)
		.. "/"
		.. formatter.formatNumberWithSuffix(maxHealth)
	-- local appendText = "/" .. formatter.formatNumberWithSuffix(maxHealth)
	-- formatter.tweenFormattedTextNumber(self._healthBarText, {
	-- 	self._oldHealth or health,
	-- 	health,
	-- 	0.5,
	-- 	appendText,
	-- })
end

function HealthBar:recolor(health: number, maxHealth: number)
	self._healthBar.ImageColor3 = robloxHealthRed:Lerp(robloxHealthGreen, health / maxHealth)
end

function HealthBar:update(health: number, maxHealth: number)
	self:resize(health, maxHealth)
	self:updateText(health, maxHealth)
	self:recolor(health, maxHealth)
end

function HealthBar:connect(humanoid: any)
	if self._healthBarConnection then
		self._healthBarConnection:Disconnect()
	end
	if humanoid:IsA "Humanoid" then
		self._healthBarConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			self:update(humanoid.Health, humanoid.MaxHealth)
			self._oldHealth = humanoid.Health
		end)
		self:update(humanoid.Health, humanoid.MaxHealth)
		self._oldHealth = humanoid.Health
	else
		local humanoidInstance = humanoid:FindFirstChildOfClass "Humanoid"

		if not humanoidInstance then
			warn "HealthBar:connect() - NPC does not have a humanoid instance"
			return
		elseif not humanoid:FindFirstChild "Configuration" then
			warn "HealthBar:connect() - NPC does not have a configuration folder"
			return
		end

		local healthValue = humanoid.Configuration.FearHealth
		local maxHealth = healthValue.Value
		self._healthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			self:update(healthValue.Value, maxHealth)
			self._oldHealth = healthValue.Value
		end)
		self:update(healthValue.Value, maxHealth)
		self._oldHealth = healthValue.Value
	end
end

return HealthBar
