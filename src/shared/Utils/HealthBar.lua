local HealthBar = {}
HealthBar.__index = HealthBar

local robloxHealthGreen = Color3.fromRGB(0, 255, 17)
local robloxHealthRed = Color3.fromRGB(255, 0, 0)

function HealthBar.new(bar)
	local self = setmetatable({}, HealthBar)

	self._healthBar = bar.Health
	self._healthBarText = bar.HP

	return self
end

function HealthBar:resize(health, maxHealth)
	self._healthBar.Size = UDim2.fromScale(health / maxHealth, 1)
end

function HealthBar:updateText(health, maxHealth)
	self._healthBarText.Text = string.format("%d / %d", health, maxHealth)
end

function HealthBar:recolor(health, maxHealth)
	self._healthBar.ImageColor3 = robloxHealthRed:Lerp(robloxHealthGreen, health / maxHealth)
end

function HealthBar:update(health, maxHealth)
	self:resize(health, maxHealth)
	self:updateText(health, maxHealth)
	self:recolor(health, maxHealth)
end

function HealthBar:connect(humanoid)
	if self._healthBarConnection then
		self._healthBarConnection:Disconnect()
	end
	if humanoid.ClassName == "Humanoid" then
		self._healthBarConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			self:update(humanoid.Health, humanoid.MaxHealth)
		end)
		self:update(humanoid.Health, humanoid.MaxHealth)
	else
		local humanoidInstance = humanoid:FindFirstChildOfClass "Humanoid"
		local healthValue = humanoid.Configuration.Health
		self._healthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			self:update(healthValue.Value, humanoidInstance.MaxHealth)
		end)
		self:update(healthValue.Value, humanoidInstance.MaxHealth)
	end
end

return HealthBar
