local UserInputService = game:GetService "UserInputService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local CollectionService = game:GetService "CollectionService"

local Remotes = require(ReplicatedStorage.Common.Remotes)

local listeners: { [BillboardGui]: (Enum.KeyCode) -> () } = {}
local validInputs: { [Enum.KeyCode]: boolean } = {
	[Enum.KeyCode.E] = true,
	[Enum.KeyCode.R] = true,
	[Enum.KeyCode.T] = true,
}

local function handleShop(shop): ()

	local function buyEgg(count: number, auto: boolean): ()
		print("buying " .. tostring(count) .. " eggs; isauto: " .. tostring(auto))
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
		if shop.CurrentDistance <= shop.MaxDistance then
			listeners[shop](input.KeyCode)
			break
		end
	end
end)

for _, shop in CollectionService:GetTagged "EggShop" do
	handleShop(shop)
end
CollectionService:GetInstanceAddedSignal("EggShop"):Connect(handleShop)

return 0
