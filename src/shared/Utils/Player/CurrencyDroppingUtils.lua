local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local TweenService = game:GetService "TweenService"
local StarterPlayer = game:GetService "StarterPlayer"

if RunService:IsServer() then
	warn "Attempted to load client-only module on server."
	return 0
end

local playSoundEffect = require(StarterPlayer.StarterPlayerScripts.Client.GameAtmosphere.SoundEffects)

local random = Random.new()
local player = Players.LocalPlayer

return {
	dropCurrency = function(origin, currencyObject, amount)
		local currencyObjects = {}
		for _ = 1, amount do
			local currencyObjectCopy = currencyObject:Clone()

			table.insert(currencyObjects, currencyObjectCopy)

			currencyObjectCopy.CFrame = origin

			local randomX = { random:NextNumber(-10, -5), random:NextNumber(5, 10) }
			local randomZ = { random:NextNumber(-10, -5), random:NextNumber(5, 10) }

			local randomVelocity = Vector3.new(
				randomX[random:NextInteger(1, 2)],
				random:NextNumber(30, 60),
				randomZ[random:NextInteger(1, 2)]
			)

			currencyObjectCopy.Parent = workspace
			currencyObjectCopy.AssemblyLinearVelocity = randomVelocity
		end

		task.wait(1)

		for _, currencyObjectCopy in currencyObjects do
			task.delay(random:NextNumber(0.05, 0.5), function()
				currencyObjectCopy.Anchored = true
				local tween = TweenService:Create(currencyObjectCopy, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
					CFrame = player.Character.HumanoidRootPart.CFrame,
				})
				tween:Play()
				tween.Completed:Wait()
				tween:Destroy()
				currencyObjectCopy:Destroy()
				playSoundEffect "Gems"
			end)
		end
	end,
}
