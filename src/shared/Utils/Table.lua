local Table = {}

function Table.ShallowIsEqual(a, b): boolean
	if a == b then
		return true
	end

	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end

	for k, v in a do
		if not Table.ShallowIsEqual(v, b[k]) then
			return false
		end
	end

	for k, v in b do
		if not Table.ShallowIsEqual(v, a[k]) then
			return false
		end
	end

	return true
end

return Table
