local suffixes = require(script.Suffixes)
local Formatter = {}

local function getPower(n)
	return math.floor(math.log(math.abs(n) + 1) / math.log(10))
end

function Formatter.formatNumberWithSuffix(n)
	local power = math.floor(getPower(n) / 3)

	if power < 1 then
		return tostring(n)
	end

	local nString = tostring(n / 10 ^ (power * 3))
	local truncatedString = nString:match "%." and nString:sub(1, 4) or nString:sub(1, 3)

	return truncatedString:gsub("%.?0+$", "") .. (suffixes[power] or "")
end

function Formatter.formatCash(n)
	return "$" .. Formatter.formatNumberWithSuffix(n)
end

return Formatter
