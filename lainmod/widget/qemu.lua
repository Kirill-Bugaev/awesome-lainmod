
--[[

     Licensed under GNU General Public License v2
      * (c) 2018, Kirill Bugaev

--]]

local helpers  = require("lainmod.helpers")
local wibox    = require("wibox")

-- QEMU vm status check
-- lain.widget.qemu

local function factory(args)
	local qemu      = { widget = wibox.widget.textbox() }
	local args      = args or {}
	local timeout   = args.timeout or 3
	local settings  = args.settings or function() end

	local function update()
		local cmd = "pidof qemu-system-x86_64"
		helpers.async(cmd, function(_, exit_code)
			settings(qemu.widget, exit_code)
		end)
	end

	qemu.timer = helpers.newtimer("qemu vm check", timeout, update, true, true)

	return qemu
end

return factory
