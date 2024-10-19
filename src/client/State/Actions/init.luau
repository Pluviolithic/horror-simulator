local actions = {}

for _, actionGroup in script:GetChildren() do
	for actionName, action in require(actionGroup) do
		actions[actionName] = action
	end
end

return actions
