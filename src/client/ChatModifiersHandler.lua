local Players = game:GetService "Players"
local StarterPlayer = game:GetService "StarterPlayer"
local TextChatService = game:GetService "TextChatService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local Remotes = require(ReplicatedStorage.Common.Remotes)
local selectors = require(ReplicatedStorage.Common.State.selectors)
local store = require(StarterPlayer.StarterPlayerScripts.Client.State.Store)

local random = Random.new()
local player = Players.LocalPlayer
local tips = {
	"Don't forget to open and evolve pets for more fear!",
	"Fight weaker enemies for easy gems!",
	"Missions and bosses are the best way to get gems!",
	"Stronger areas give more strength when you workout!",
	"You can wait 2 minutes to reset your fear meter while scared!",
	"Deal more damage by buying stronger weapons!",
	"Bosses are strong, so fight them with other players!",
	"Follow _ProdigyStudios for codes!",
	"Jump Scares can be turned off in settings!",
}

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new "TextChatMessageProperties"

	if message.TextSource then
		local sendingPlayer = Players:GetPlayerByUserId(message.TextSource.UserId)

		if sendingPlayer:GetAttribute "isVIP" == true then
			props.PrefixText = '<font color="rgb(255, 176, 0)">[VIP]</font> ' .. message.PrefixText
		end
	end

	return props
end

Remotes.Client:Get("LegendaryUnboxed"):Connect(function(playerName, petName)
	TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(
		`<font color= 'rgb(255, 176, 0)'>{playerName} hatched a Legendary {petName} Pet!</font>`
	)
end)

task.delay(120, function()
	while #tips > 0 do
		if selectors.getSetting(store:getState(), player.Name, "Tips") then
			local tip = table.remove(tips, random:NextInteger(1, #tips))
			TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(
				`<font color= 'rgb(255, 255, 255)'>Tip: {tip}</font>`
			)
		end
		task.wait(60 * 8)
	end
end)

return 0
