local function utf8_strlen(t)
	local i = 1;
	local num_chars = 0;
	while i <= #t do
		num_chars = num_chars + 1
		if ( t[i] & 128) == 0 then
			-- 1 byte code point, ASCII
			i = i + 1
		elseif (t[i] & 224) == 192 then
			-- 2 byte code point
			i = i + 2
		elseif (t[i] & 240) == 224 then
			-- 3 byte code point
			i = i + 3
		else
			-- 4 byte code point
			i = i + 4
		end
	end
	return num_chars;
end

local function utf8_to_utf32(t)
	local num_chars = utf8_strlen(t)
	local c = {}
	local i = 1
	for n = 1, num_chars, 1 do
		if (t[i] & 128) == 0 then
			-- 1 byte code point, ASCII
			c[n] = t[i] & 127
			i = i + 1
		elseif (t[i] & 224) == 192 then
			-- 2 byte code point
			c[n] = (t[i] & 31) << 6 | (t[i + 1] & 63)
			i = i + 2
		elseif (t[i] & 240) == 224 then
			-- 3 byte code point
			c[n] = (t[i] & 15) << 12 | (t[i + 1] & 63) << 6 | (t[i + 2] & 63)
			i = i + 3
		else
			-- 4 byte code point
			c[n] = (t[i] & 7) << 18 | (t[i + 1] & 63) << 12 | (t[i + 2] & 63) << 6 | (t[i + 3] & 63)
			i = i + 4
		end
	end
	return c;
end

return { utf8_strlen = utf8_strlen, utf8_to_utf32 = utf8_to_utf32 }
