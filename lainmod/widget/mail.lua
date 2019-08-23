--[[

     Licensed under GNU General Public License v2
      * (c) 2019, Kirill Bugaev
      * (c) 2013, Luca CPZ

--]]

local helpers   = require("lainmod.helpers")
local naughty   = require("naughty")
local wibox     = require("wibox")
local focused   = require("awful.screen").focused
local type      = type
local tonumber  = tonumber

-- Mail IMAP check
-- lainmod.widget.mail

local function factory(args)
	local args      = args or {}
	local host      = args.host
	local port      = tostring(args.port) or "993"
	local tls       = args.tls or false
	local client_to = tostring(args.client_to) or "5"
	local account   = args.account
	local password  = args.password
	local mailbox   = args.mailbox or "INBOX"
	local msg_count = tostring(args.get_message_count) or "0"
	local timeout   = args.timeout or 60
	local is_plain  = args.is_plain or false
	local notify    = args.notify or "on"
	local showpopup = args.showpopup or "on"
	local icon      = args.icon or ""
	local settings  = args.settings or function() end

	local mail = { widget = wibox.widget.textbox() }
	mail.account              = args.account
	mail.unseen_messages      = ""
	mail.followtag            = args.followtag or false
	mail.notification_preset  = args.notification_preset or { }

	local script_location  = (debug.getinfo(1,"S").source:sub(2)):match("(.*/)")
	local lainmod_location = script_location:sub(1, script_location:find("/[^/]+/$"))
	local util_location    = lainmod_location .. "util/"
	local client_location  = util_location .. "mailclient.lua"

	if tls then
		tls = "1"
	else
		tls = "0"
	end

	function mail.hide_hint_notify()
		if not mail.hint_notification then return end
		naughty.destroy(mail.hint_notification)
		mail.hint_notification = nil
	end

	function mail.show_hint_notify(scr)
		if mail.unseen_messages ~= "" then
			local hint_notification_preset = helpers.shallow_table_copy(
				mail.notification_preset
			)
			hint_notification_preset.icon = icon
			hint_notification_preset.screen = mail.followtag and focused() or scr or 1
			mail.hint_notification = naughty.notify {
				preset = hint_notification_preset,
				text = mail.account .. "\n\r" .. mail.unseen_messages,
				timeout = 0
			}
		end
	end

	if not host or not account or not password then return end

	helpers.set_map(account, 0)

	if not is_plain then
		if type(password) == "string" or type(password) == "table" then
			helpers.async(password, function(f) password = f:gsub("\n", "") end)
		end
	end

	local function update()
		local mail_notification_preset = helpers.shallow_table_copy(mail.notification_preset)
		mail_notification_preset.icon = icon
		mail_notification_preset.position = "top_left"

		-- get mail
		local cmd = {
			"lua",
			client_location,
			host,
			port,
			tls,
			client_to,
			account,
			password,
			mailbox,
			msg_count
		}
		helpers.async(cmd, function(stdout, exit_code)
			local mailcount
			if exit_code == 0 then
				local s,e = stdout:find("^%d+")
				mailcount = tonumber(stdout:sub(s,e))
				mail.unseen_messages = stdout:sub(e + 2)
			else
				mailcount = "N/A"
				mail.unseen_messages = ""
			end
			settings(mail.widget, mailcount)

			if mailcount ~= "N/A" then
				local previous_mailcount = helpers.get_map(account)
				if previous_mailcount == "N/A" then
					previous_mailcount = 0
				end
				if notify == "on" and mailcount >= 1 and mailcount > previous_mailcount then
					local nt
					if mailcount == 1 then
						nt = account .. " has one new message"
					else
						nt = account .. " has <b>" .. mailcount .. "</b> new messages"
					end
					naughty.notify { preset = mail_notification_preset, text = nt }
				end
			end

			helpers.set_map(account, mailcount)
		end )
	end

	if showpopup == "on" then
		mail.widget:connect_signal('mouse::enter', function() mail.show_hint_notify(0) end)
		mail.widget:connect_signal('mouse::leave', function() mail.hide_hint_notify() end)
	end

	mail.timer = helpers.newtimer(account, timeout, update)

	return mail
end

return factory
