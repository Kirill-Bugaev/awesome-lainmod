--[[
     Simple mail client
     Returns count of UNSEEN messages and DATE, FROM and SUBJECT fields of each
     usage:
     $ lua mailclient <host> <port> <enable tls: 0 or 1> <timeout> <user> <password> <mailbox> <message count>
     (c) 2019, Kirill Bugaev
]]
local lfs = require "lfs"
local script_location = (debug.getinfo(1,"S").source:sub(2)):match("(.*/)")
--local script_location = "/home/user1/.config/awesome/lainmod/util/"
lfs.chdir(script_location)

local imap = require "imap"

local host       = arg[1]
local port       = arg[2]
local tls_params = arg[3]
if tls_params == 0 then
	tls_params     = nil
else
	tls_params     = {
		mode     = "client",
		protocol = "tlsv1",
		verify   = "none",
		options  = "all",
	}
end
local timeout   = arg[4]
local user      = arg[5]
local pass      = arg[6]
local mailbox   = arg[7]
local count     = arg[8]

local datepat = "^[%a]+,%s+[%d]+%s+[%a]+%s+[%d]+%s+[%d]+:[%d]+"

local conn = imap(host, port, tls_params, tonumber(timeout))
conn:login(user, pass)
conn:examine(mailbox)
local msgs, total_unseen = conn:getunseen(tonumber(count))
conn:close()

print(total_unseen)
for i=#msgs,1,-1 do
	local date = msgs[i].Date:sub(msgs[i].Date:find(datepat))
	print(string.format("%s | %s | %s", date, msgs[i].From, msgs[i].Subject))
end
