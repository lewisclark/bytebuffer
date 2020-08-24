local BYTEBUFFER_VERSION = "0.1.0"

local bytebuffer = {}
bytebuffer.__index = bytebuffer

function bytebuffer.new(str_bytes)
	local t = {}
	setmetatable(t, bytebuffer)

	t:initialize(str_bytes)

	return t
end

function bytebuffer:initialize(str_bytes)
	self.pos = 1
	self.bytes = {}

	for i = 1, #str_bytes do
		self.bytes[i] = string.byte(str_bytes[i])
	end
end

function bytebuffer:set_pos(pos)
	assert(pos <= #self.bytes)
	self.pos = pos
end

function bytebuffer:get_pos()
	return self.pos
end

function bytebuffer:eof()
	return self.pos > #self.bytes
end

function bytebuffer:peek_byte()
	return self.bytes[self.pos]
end

function bytebuffer:read_bytes(num)
	assert(self.pos + num - 1 <= #self.bytes)

	local bytes = {}

	for i = 1, num do
		bytes[i] = self.bytes[self.pos + (i - 1)]
	end

	self.pos = self.pos + num

	return bytes
end

function bytebuffer:read_string(num_bytes)
	local t = {}

	for k, b in ipairs(self:read_bytes(num_bytes)) do
		table.insert(t, string.char(b))
	end

	return table.concat(t, "")
end

function bytebuffer.unsigned_to_signed(n, nbits)
	local sign = bit.rshift(n, nbits - 1)

	if sign == 0 then
		return n
	else
		return -(bit.bxor(n, math.pow(2, nbits) - 1) + 1)
	end
end

function bytebuffer:uint8()
	return self:read_bytes(1)[1]
end

function bytebuffer:int8()
	return self.unsigned_to_signed(self:uint8(), 8)
end

function bytebuffer:uint16()
	local bytes = self:read_bytes(2)
	local num = bytes[1] + bit.lshift(bytes[2], 8)

	return num
end

function bytebuffer:int16()
	return self.unsigned_to_signed(self:uint16(), 16)
end

function bytebuffer:uint32()
	local bytes = self:read_bytes(4)
	local num = bytes[1]
		+ bit.lshift(bytes[2], 8)
		+ bit.lshift(bytes[3], 16)
		+ bit.lshift(bytes[4], 24)

	return num
end

function bytebuffer:int32()
	return self.unsigned_to_signed(self:uint32(), 32)
end

function bytebuffer:uleb128()
	local result, shift = 0, 0

	while true do
		local byte = self:uint8()
		local low = bit.band(byte, 0x7f)
		result = bit.bor(result, bit.lshift(low, shift))

		-- Is the continuation bit == 0?
		if bit.band(byte, 128) == 0 then
			break
		end

		shift = shift + 7
	end

	return result
end

function bytebuffer:uleb128_33()
	local result, shift = 0, -1

	while true do
		local byte = self:uint8()

		if shift == -1 then
			result = bit.band(bit.rshift(byte, 1), 0x3f)
		end

		local low = bit.band(byte, 0x7f)
		result = bit.bor(result, bit.lshift(low, shift))

		if bit.band(byte, 128) == 0 then
			break
		end

		shift = shift + 7
	end

	return result
end

function bytebuffer.lo_hi_to_double(lo, hi)
	local sign = bit.rshift(hi, 31)

	-- Shift by 20 to skip the mantissa portion
	-- & 2^11-1 to obtain the exponent without the sign
	-- - 2^10-1 to remove the exponent bias
	local exponent = bit.band(bit.rshift(hi, 20), math.pow(2, 11) - 1) - math.pow(2, 10) - 1

	local mantissa_hi = bit.band(hi, math.pow(2, 20) - 1)
	local mantissa_lo = lo

	-- FIXME: Normalized vs denormalized?
	-- local is_normalized = bit.band(bit.rshift(mantissa_hi, 19), 1) == 1

	local f = 4
	for i = 1, 52 do
		local m = i <= 32 and mantissa_lo or mantissa_hi
		local b = bit.band(m, 1)

		if b == 1 then
			f = f + (1 / math.pow(2, 52 - i - 1))
		end

		if i <= 32 then
			mantissa_lo = bit.rshift(m, 1)
		else
			mantissa_hi = bit.rshift(m, 1)
		end
	end

	local d = f * math.pow(2, exponent)

	return sign == 1 and -d or d
end

function bytebuffer.double_to_lo(d)
	local m, e = math.frexp(d)
	local lo = math.floor((m * 2 - 1) * 2 ^ 52 + 0.5)

	return (lo % 2 ^ 32) - 2 ^ 31
end

return bytebuffer
