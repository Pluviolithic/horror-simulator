local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local CollectionService = game:GetService "CollectionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Client = StarterPlayer.StarterPlayerScripts.Client
local player = Players.LocalPlayer

local playerStatePromise = require(Client.State.PlayerStatePromise)
local formatter = require(ReplicatedStorage.Common.Utils.Formatter)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(Client.State.Store)

local requiredFearUIs = CollectionService:GetTagged "RequiredFear"
CollectionService:GetInstanceAddedSignal("RequiredFear"):Connect(function(newRequiredFearUI)
	table.insert(requiredFearUIs, newRequiredFearUI)
end)

local function updateRequiredFearUIs(state, UIs)
	for _, UI in UIs do
		UI.Text = formatter.formatNumberWithSuffix(selectors.getStat(state, player.Name, "RequiredFear"))
	end
end

playerStatePromise:andThen(function()
	updateRequiredFearUIs(store:getState(), requiredFearUIs)
	store.changed:connect(function(newState)
		updateRequiredFearUIs(newState, requiredFearUIs)
	end)
end)

return 0
