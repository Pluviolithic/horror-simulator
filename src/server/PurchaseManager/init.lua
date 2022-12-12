for _, module in ipairs(script:GetChildren()) do
	if module:IsA "ModuleScript" then
		require(module)
	end
end

return 0
