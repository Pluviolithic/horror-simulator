for _, module in ipairs(script:GetChildren()) do
	require(module)
end

return 0
