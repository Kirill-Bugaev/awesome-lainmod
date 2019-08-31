--[[
     Imap module
     Retrives DATE, FROM and SUBJECT fields of UNSEEN messages
     Tested on imap.gmail.com:993
     (c) 2019, Kirill Bugaev
]]

local socket    = require "socket"
local base64    = require "ee5_base64"
local utfhelper = require "utfhelper"

-- generates tokens for IMAP conversations
local function tokgen()
	local pref = math.random()
	local n = 0
	return function()
		n = n + 1
		return pref .. n
	end
end

-- check response (last string in table)
local function chkresp(resp, token)
	return resp[#resp]:match("^" .. token .. " OK")
end

-- split string to table in reverse order
local function split(inp, sep)
	sep = sep or "%s"

	local t = {}
	for s in string.gmatch(inp:reverse(), "([^" .. sep .. "]+)") do
		table.insert(t, s:reverse())
	end
	return t
end

local function parsebase64(inp)
	local b64pre  = "=?UTF-8?B?"
	local b64post = "?="
	local pat     = "=%?[uU][tT][fF]%-8%?[Bb]%?[^%?]*[^=]*%?="

	local out = ""
	local b   = false
	for b64 in inp:gmatch(pat) do
		b = true
		local s,e = inp:find(pat)
		b64 = b64:sub(b64pre:len() + 1, b64:len() - b64post:len())
		out = out .. inp:sub(1, s - 1) .. base64.decode(b64)
		inp = inp:sub(e + 1)
	end
	out = out .. inp
	return out, b
end

-- decode Q-words string
local function decodeqw(inp)
	local t = {}
	local qw = ""
	local ci = 0
	for c in inp:gmatch(".") do
		if c == "=" then
			qw = ""
			ci = 1
		elseif ci == 1 then
			qw = c
			ci = ci + 1
		elseif ci == 2 then
			qw = qw .. c
			table.insert(t, tonumber(qw, 16))
			ci = 0
		else
			table.insert(t, c:byte())
		end
	end
	t = utfhelper.utf8_to_utf32(t)
	local out = ""
	for _,v in pairs(t) do
		out = out .. utf8.char(v)
	end
	return out
end

local function parseqwords(inp)
	local qpre  = "=?UTF-8?Q?"
	local qpost = "?="
	local pat   = "=%?[uU][tT][fF]%-8%?[Qq]%?[^%?]*[^=]*%?="
	local out = ""
	local q   = false
	for qline in inp:gmatch(pat) do
		q = true
		local s,e = inp:find(pat)
		qline = qline:sub(qpre:len() + 1, qline:len() - qpost:len())
		out = out .. inp:sub(1, s - 1) .. decodeqw(qline)
		inp = inp:sub(e + 1)
	end
	out = out .. inp
	return out, q
end

-- parse FETCH response
local function parsefetch(inp)
	local out = {}
	local i = 0
	while i <= #inp - 1 do
		i = i + 1
		local head = inp[i]:match("^* %d+")
		if head then
			local msg = {}
			msg.Num = head:sub(3)
			while i <= #inp - 1 and inp[i + 1]:sub(1, 1) ~= ")" do
				i = i + 1
				local field = inp[i]:match("%a+:")
				if field then
					field = field:sub(1, field:len() - 1)
					msg[field] = parseqwords(parsebase64(inp[i]:sub(field:len() + 3)))
					while i <= #inp - 1 and inp[i + 1]:sub(1, 1) == " " do
						i = i + 1
						local s, b = parsebase64(inp[i]:sub(2))
						local q
						s, q = parseqwords(s)
						if not b or not q then
							msg[field] = msg[field] .. " "
						end
						msg[field] = msg[field] .. s
					end
				end
			end
			table.insert(out, msg)
		end
	end
	return out
end

local IMAP = {}
IMAP.__index = IMAP

function IMAP:_send(cmd, ...)
	local token = self:next_token()
	assert(self.socket:send(token .. " " .. cmd:format(...) .. "\r\n"))
	return token
end

function IMAP:_receive(token)
	local resp = {}
	while true do
		local data = assert(self.socket:receive())
--		print(data)
		table.insert(resp, data)
		if data:match("^" .. token) then
			break
		end
	end
	return resp
end

function IMAP:_docmd(errmsg, cmd, ...)
	local token = self:_send(cmd, ...)
	local resp = self:_receive(token)
	-- check response
	if not chkresp(resp, token) then
		assert(nil, errmsg)
	end
	return resp
end

-- constructor
function IMAP.new(host, port, tls_params, timeout)
	port = tonumber(port) or 993
	timeout = timeout or 5

	local conn = assert(
		socket.connect(host, port),
		("Can't connect to %s:%s"):format(host, port)
	)
	conn:settimeout(timeout)

	local imap = setmetatable({
		host       = host,
		port       = port,
		socket     = conn,
		_logon     = false,
		next_token = tokgen(),
	}, IMAP)

	if tls_params then
		imap:tls(tls_params, timeout)
	end

	-- check the server greeting
	if not chkresp(imap:_receive("%*"), "%*") then
		assert(nil, host .. " not greet")
	end

	return imap
end

function IMAP:tls(tls_params, timeout)
	tls_params          = tls_params          or {}
	tls_params.mode     = tls_params.mode     or "client"
	tls_params.protocol = tls_params.protocol or "tlsv1"
	tls_params.verify   = tls_params.verify   or "none"
	tls_params.options  = tls_params.options  or "all"
	timeout             = timeout             or 5

	local ssl = require 'ssl'
	local ssl_conn = assert(ssl.wrap(self.socket, tls_params))
	ssl_conn:settimeout(timeout)
	assert(ssl_conn:dohandshake(), "Can't do handshake")
	self.socket = ssl_conn
end

function IMAP:close()
	if self._logon then
		self:logout()
	end
	self.socket:close()
end

function IMAP:login(user, pass)
	self:_docmd("Authentication failed", "LOGIN %s %s", user, pass)
	self._logon = true
end

function IMAP:logout()
	self:_docmd("Logout failed", "LOGOUT")
	self._logon = false
end

function IMAP:examine(box)
	self:_docmd("Examine " .. box .. " failed", "EXAMINE %s", box)
end

function IMAP:getunseen(count)
	local spref = "* SEARCH "

	-- get count of unseen messages
	local nums = split(
		self:_docmd("Can't get count of unseen messages", "SEARCH (UNSEEN)")
			[1]:sub(spref:len() + 1)
	)
	if #nums == 0 then
		return {}, 0
	end
	if count == 0 then
		return {}, #nums
	end
	if not count then
		count = #nums
	end

	-- format fetch request
	local fetch = "FETCH " .. nums[1]
	for i=2,math.min(#nums, count),1 do
		fetch = fetch .. "," .. nums[i]
	end
	fetch = fetch .. " BODY.PEEK[HEADER.FIELDS (DATE FROM SUBJECT)]"
	local resp = self:_docmd("Can't fetch unseen messages", fetch)

	return parsefetch(resp), #nums
end

return setmetatable(IMAP, {__call = function(_, ...) return IMAP.new(...) end})
