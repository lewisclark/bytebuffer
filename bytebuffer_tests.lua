local bytebuffer = include("bytebuffer.lua")

-- ByteBuffer tests
local function assert(b, msg)
	if not b then
		error(string.format("Test assertion failed! %s\n%s", msg or "", debug.traceback()))
	end
end

local function assert_eq(x, y)
	assert(x == y)
end

-- UInt8
assert_eq(bytebuffer.new("\xfe"):uint8(), 0xfe)

-- Int8
assert_eq(bytebuffer.new("\xcc"):int8(), -52)
assert_eq(bytebuffer.new("\x4b"):int8(), 75)

-- UInt16
assert_eq(bytebuffer.new("\x4b\x5e"):uint16(), 0x5e4b)

-- Int16
assert_eq(bytebuffer.new("\xb2\x8b"):int16(), -29774)
assert_eq(bytebuffer.new("\x90\x7c"):int16(), 31888)

-- UInt32
assert_eq(string.format("%x", bytebuffer.new("\x91\x1c\xfe\xff"):uint32()), "fffe1c91")

-- Int32
assert_eq(bytebuffer.new("\x6d\x45\x71\xa7"):int32(), -1485748883)
assert_eq(bytebuffer.new("\x12\x3f\x14\x74"):int32(), 0x74143f12)

-- ULEB128
assert_eq(bytebuffer.new("\xe5\x8e\x26"):uleb128(), 624485)

-- TODO: ULEB128_33() tests
-- TODO: lo_hi_to_double() tests
-- TODO: decode_ins() tests

print("All byte buffer tests passed")
