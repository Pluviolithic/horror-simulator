for _, module in script:GetChildren() do
	require(module)
end

return 0
