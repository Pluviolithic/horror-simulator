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
function Formatter.formatNumberWithCommas(n: number, decimalDigits: number?): string
	local _, _, minus, int, fraction = tostring(n):find "([-]?)(%d+)([.]?%d*)"
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction:sub(1, if decimalDigits then decimalDigits + 1 else 2)
end

local tweenBuffers = {}
function Formatter.tweenFormattedTextNumber(textLabel, config)
	if tweenBuffers[textLabel] then
		tweenBuffers[textLabel] = table.clone(config)
		return
	end
	tweenBuffers[textLabel] = true

	local startTime = os.clock()
	local startNumber, endNumber, duration, customFormatter = table.unpack(config)
	local difference = endNumber - startNumber

	task.spawn(function()
		repeat
			local timePassed = os.clock() - startTime
			local progress = timePassed / duration
			local currentNumber = startNumber + difference * progress

			if startNumber > endNumber then
				currentNumber = math.clamp(currentNumber, endNumber, startNumber)
			else
				currentNumber = math.clamp(currentNumber, startNumber, endNumber)
			end
			if customFormatter then
				textLabel.Text = customFormatter(currentNumber)
			else
				textLabel.Text = Formatter.formatNumberWithSuffix(currentNumber)
			end
			task.wait()
		until timePassed >= duration

		if customFormatter then
			textLabel.Text = customFormatter(endNumber)
		else
			textLabel.Text = Formatter.formatNumberWithSuffix(endNumber)
		end

		local bufferData = tweenBuffers[textLabel]
		tweenBuffers[textLabel] = nil
		if type(bufferData) == "table" then
			Formatter.tweenFormattedTextNumber(textLabel, bufferData)
		end
	end)
end

return Formatter
