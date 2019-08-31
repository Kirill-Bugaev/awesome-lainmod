--[[

     Licensed under GNU General Public License v2
      * (c) 2019, Kirill Bugaev

--]]

local helpers = require("lainmod.helpers")
local wibox   = require("wibox")

-- php-fpm status check
-- lain.widget.phpfpm

local function factory(args)
	local phpfpm    = { widget = wibox.widget.textbox() }
	local args      = args or {}
	local timeout   = args.timeout or 3
	local settings  = args.settings or function() end

	local function update()
		local cmd = "pidof php-fpm"
		helpers.async(cmd, function(_, exit_code)
			settings(phpfpm.widget, exit_code)
		end)
	end

	phpfpm.timer = helpers.newtimer("php-fpm status check", timeout, update, true, true)

	return phpfpm
end

return factory
