local suffixes = require(script.Suffixes)
local Formatter: { [string]: (...any) -> any } = {}

local function getPower(n: number): number
	return math.floor(math.log(math.abs(n) + 1) / math.log(10))
end

function Formatter.formatNumberWithSuffix(n: number): string
	local power: number = math.floor(getPower(n) / 3)

	if power < 1 then
		return tostring(math.round(n))
	end

	local nString: string = tostring(n / 10 ^ (power * 3))
	local truncatedString: string = nString:match "%." and nString:sub(1, 4) or nString:sub(1, 3)

	return truncatedString:gsub("%.0*$", "") .. (suffixes[power] or "")
end

function Formatter.formatCash(n: number): string
	return "$" .. Formatter.formatNumberWithSuffix(n)
end

function Formatter.truncateMultiplier(n: number): string
	return string.format("%.2f", n):gsub("%.?0+$", "")
end

return Formatter
