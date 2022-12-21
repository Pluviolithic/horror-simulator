local HealthBar = {}
HealthBar.__index = HealthBar

local robloxHealthGreen: Color3 = Color3.fromRGB(0, 255, 17)
local robloxHealthRed: Color3 = Color3.fromRGB(255, 0, 0)

type HealthBar = typeof(setmetatable(
	{} :: {
		_healthBar: ImageLabel,
		_healthBarText: TextLabel,
		_healthBarConnection: RBXScriptConnection?,
	},
	HealthBar
))

function HealthBar.new(bar: Frame): HealthBar
	return setmetatable({
		_healthBar = bar:FindFirstChild "Health",
		_healthBarText = bar:FindFirstChild "HP",
		_healthBarConnection = nil,
	}, HealthBar)
end

function HealthBar:resize(health: number, maxHealth: number)
	self._healthBar.Size = UDim2.fromScale(health / maxHealth, 1)
end

function HealthBar:updateText(health: number, maxHealth: number)
	self._healthBarText.Text = string.format("%d / %d", health, maxHealth)
end

function HealthBar:recolor(health: number, maxHealth: number)
	self._healthBar.ImageColor3 = robloxHealthRed:Lerp(robloxHealthGreen, health / maxHealth)
end

function HealthBar:update(health: number, maxHealth: number)
	self:resize(health, maxHealth)
	self:updateText(health, maxHealth)
	self:recolor(health, maxHealth)
end

function HealthBar:connect(humanoid: Humanoid | Model)
	if self._healthBarConnection then
		self._healthBarConnection:Disconnect()
	end
	if typeof(humanoid) == "Humanoid" then
		self._healthBarConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
			self:update(humanoid.Health, humanoid.MaxHealth)
		end)
		self:update(humanoid.Health, humanoid.MaxHealth)
	else
		local humanoidInstance: Humanoid = humanoid:FindFirstChildOfClass "Humanoid"
		local healthValue: IntValue | NumberValue = humanoid:FindFirstChild("Configuration").Health
		self._healthBarConnection = healthValue:GetPropertyChangedSignal("Value"):Connect(function()
			self:update(healthValue.Value, humanoidInstance.MaxHealth)
		end)
		self:update(healthValue.Value, humanoidInstance.MaxHealth)
	end
end

return HealthBar
