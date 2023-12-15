local UserInputService = game:GetService "UserInputService"

local activeDescriptions = {}

local function handleDescription(description, text)
	if not text then
		text = description.TextLabel.Text
	end

	if activeDescriptions[description.TextLabel] then
		activeDescriptions[description.TextLabel] = os.time()
		if description.TextLabel.Text ~= text then
			description.TextLabel.Text = text
		end
		return
	end

	activeDescriptions[description.TextLabel] = os.time()
	description.TextLabel.Text = text
	description.Visible = true

	while os.time() - activeDescriptions[description.TextLabel] < 10 do
		task.wait(0.25)
	end

	description.Visible = false
	activeDescriptions[description.TextLabel] = false
end

return function(button, description, text)
	if not text then
		text = description.TextLabel.Text
	end

	button.MouseEnter:Connect(function()
		if not UserInputService.MouseEnabled then
			return
		end
		description.TextLabel.Text = text
		description.Visible = true
	end)

	button.MouseLeave:Connect(function()
		if not UserInputService.MouseEnabled then
			return
		end
		description.Visible = false
	end)

	button.Activated:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		handleDescription(description, text)
	end)
end
