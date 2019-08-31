--[[

     Licensed under GNU General Public License v2
      * (c) 2019, Kirill Bugaev

--]]

local naughty = require("naughty")
local awful   = require("awful")
local wibox   = require("wibox")
local helpers = require("lainmod.helpers")

-- MariaDB status check
-- lain.widget.mariadb

local function factory(args)
	local args      = args or {}
	local timeout   = args.timeout or 3
	local showpopup = args.showpopup or "on"
	local settings  = args.settings or function() end

	local mariadb                   = { widget = wibox.widget.textbox() }
	mariadb.followtag               = args.followtag or false
	mariadb.log_notification_preset = args.log_notification_preset or {}
	mariadb.logfile                 = args.logfile or "/var/log/mysql/mariadb.log"
	mariadb.loglength               = args.loglength or 20

	function mariadb.hide_log()
		if not mariadb.log_notification then return end
		naughty.destroy(mariadb.log_notification)
		mariadb.log_notification = nil
	end

	function mariadb.show_log(scr)
		local text = ""
		local count = 0
		for line in helpers.lines_from_reverse(mariadb.logfile) do
			if text ~= "" then
				text = "\n" .. text
			end
			text = line .. text
			count = count + 1
			if count > mariadb.loglength then
				break
			end
		end
		text = "MariaDB log " .. mariadb.logfile .. "\n\r" .. text
		mariadb.log_notification_preset.screen = mariadb.followtag and awful.screen.focused() or scr or 1
		mariadb.log_notification = naughty.notify {
			preset = mariadb.log_notification_preset,
			text = text,
			timeout = 0
		}
	end

	local function update()
		local cmd = "pidof mysqld"
		helpers.async(cmd, function(_, exit_code)
			settings(mariadb.widget, exit_code)
		end)
	end

	if showpopup == "on" then
		mariadb.widget:connect_signal('mouse::enter', function() mariadb.show_log(1) end)
		mariadb.widget:connect_signal('mouse::leave', function() mariadb.hide_log() end)
	end

	mariadb.timer = helpers.newtimer("mariadb status check", timeout, update, true, true)

	return mariadb
end

return factory
