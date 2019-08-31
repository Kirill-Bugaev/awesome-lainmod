--[[

     Licensed under GNU General Public License v2
      * (c) 2018, Kirill Bugaev

--]]

local helpers  = require("lainmod.helpers")
local wibox    = require("wibox")

-- Samba server status check
-- lain.widget.smb

local function factory(args)
	local smb       = { widget = wibox.widget.textbox() }
	local args      = args or {}
	local timeout   = args.timeout or 3
	local settings  = args.settings or function() end

	local function update()
		local cmd = "pidof smbd"
		helpers.async(cmd, function(_, exit_code)
			settings(smb.widget, exit_code)
		end)
	end

	smb.timer = helpers.newtimer("smb server check", timeout, update, true, true)

	return smb
end

return factory
