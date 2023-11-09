local Players = game:GetService "Players"
local TextChatService = game:GetService "TextChatService"

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new "TextChatMessageProperties"

	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)

		if player:GetAttribute "isVIP" == true then
			props.PrefixText = '<font color="rgb(255, 176, 0)">[VIP]</font> ' .. message.PrefixText
		end
	end

	return props
end

return 0
