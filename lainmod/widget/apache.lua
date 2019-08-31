--[[

     Licensed under GNU General Public License v2
      * (c) 2019, Kirill Bugaev

--]]

local naughty = require("naughty")
local awful   = require("awful")
local wibox   = require("wibox")
local helpers = require("lainmod.helpers")

-- Apache web server status check
-- lain.widget.apache

local function factory(args)
	local args      = args or {}
	local timeout   = args.timeout or 3
	local showpopup = args.showpopup or "on"
	local settings  = args.settings or function() end

	local apache                   = { widget = wibox.widget.textbox() }
	apache.followtag               = args.followtag or false
	apache.log_notification_preset = args.log_notification_preset or {}
	apache.logfile                 = args.logfile or "/var/log/httpd/access_log"
	apache.loglength               = args.loglength or 20

	function apache.hide_log()
		if not apache.log_notification then return end
		naughty.destroy(apache.log_notification)
		apache.log_notification = nil
	end

	function apache.show_log(scr)
		local text = ""
		local count = 0
		for line in helpers.lines_from_reverse(apache.logfile) do
			if text ~= "" then
				text = "\n" .. text
			end
			text = line .. text
			count = count + 1
			if count > apache.loglength then
				break
			end
		end
		text = "Apache log " .. apache.logfile .. "\n\r" .. text
		apache.log_notification_preset.screen = apache.followtag and awful.screen.focused() or scr or 1
		apache.log_notification = naughty.notify {
			preset = apache.log_notification_preset,
			text = text,
			timeout = 0
		}
	end

	local function update()
		local cmd = "pidof httpd"
		helpers.async(cmd, function(_, exit_code)
			settings(apache.widget, exit_code)
		end)
	end

	if showpopup == "on" then
		apache.widget:connect_signal('mouse::enter', function() apache.show_log(1) end)
		apache.widget:connect_signal('mouse::leave', function() apache.hide_log() end)
	end

	apache.timer = helpers.newtimer("apache status check", timeout, update, true, true)

	return apache
end

return factory
