local suffixes = require(script.Suffixes)
local Formatter = {}

local function getPower(n: number): number
	return math.floor(math.log(math.abs(n) + 1) / math.log(10))
end

function Formatter.formatNumberWithSuffix(n: number): string
	local power = math.floor(getPower(n) / 3)

	if power < 1 then
		return tostring(math.round(n))
	end

	local nString = tostring(n / 10 ^ (power * 3))
	local truncatedString = nString:match "%." and nString:sub(1, 4) or nString:sub(1, 3)

	return truncatedString:gsub("%.0*$", "") .. (suffixes[power] or "")
end

function Formatter.formatCash(n: number): string
	return "$" .. Formatter.formatNumberWithSuffix(n)
end

function Formatter.truncateMultiplier(n: number): string
	return string.format("%.2f", n):gsub("%.?0+$", "")
end

-- taken from https://stackoverflow.com/questions/10989788/format-integer-in-lua
function Formatter.formatNumberWithCommas(n: number): string
	local _, _, minus, int, fraction = tostring(n):find "([-]?)(%d+)([.]?%d*)"
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction
end

local tweenBuffers = {}
function Formatter.tweenFormattedTextNumber(textLabel, startNumber, endNumber, duration)
	if tweenBuffers[textLabel] then
		tweenBuffers[textLabel] = { startNumber, endNumber, duration }
		return
	end
	tweenBuffers[textLabel] = true

	local startTime = os.clock()
	local difference = endNumber - startNumber

	task.spawn(function()
		repeat
			local timePassed = os.clock() - startTime
			local progress = timePassed / duration
			local currentNumber = startNumber + difference * progress

			textLabel.Text = Formatter.formatNumberWithSuffix(currentNumber)
			task.wait()
		until timePassed >= duration

		textLabel.Text = Formatter.formatNumberWithSuffix(endNumber)

		local bufferData = if type(tweenBuffers[textLabel]) == "table"
			then table.unpack(tweenBuffers[textLabel])
			else nil
		tweenBuffers[textLabel] = nil
		if bufferData then
			Formatter.tweenFormattedTextNumber(textLabel, bufferData)
		end
	end)
end

return Formatter
