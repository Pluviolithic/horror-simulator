local HealthBar = {}
HealthBar.__index = HealthBar

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

function HealthBar:connect(humanoid)
	if self._healthBarConnection then
		self._healthBarConnection:Disconnect()
	end
	if humanoid.ClassName == "Humanoid" then
		self._healthBarConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			self:resize(humanoid.Health, humanoid.MaxHealth)
			self:updateText(humanoid.Health, humanoid.MaxHealth)
		end)
		self:resize(humanoid.Health, humanoid.MaxHealth)
		self:updateText(humanoid.Health, humanoid.MaxHealth)
	else
		local humanoidInstance = humanoid:FindFirstChildOfClass "Humanoid"
		local healthValue = humanoid.Configuration.Health
		self._healthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			self:resize(healthValue.Value, humanoidInstance.MaxHealth)
			self:updateText(healthValue.Value, humanoidInstance.MaxHealth)
		end)
		self:resize(healthValue.Value, humanoidInstance.MaxHealth)
		self:updateText(healthValue.Value, humanoidInstance.MaxHealth)
	end
end

return HealthBar
