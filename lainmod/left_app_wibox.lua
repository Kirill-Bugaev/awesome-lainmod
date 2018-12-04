
local gears         = require("gears")
local awful         = require("awful")
local wibox         = require("wibox")
local cairo 	    = require("lgi").cairo

local function factory(args)
    local left_app_wibox_path = (debug.getinfo(1,"S").source:sub(2)):match("(.*/)")

    local left_app_wibox = { }

    left_app_wibox.confdir                         = left_app_wibox_path 
    -- Left wibox icon file paths
    left_app_wibox.taskman                         = left_app_wibox.confdir .. "icons/leftwibox/system-monitor.png"
    left_app_wibox.term                            = left_app_wibox.confdir .. "icons/leftwibox/terminal.png"
    left_app_wibox.mc                              = left_app_wibox.confdir .. "icons/leftwibox/mc.png"
    left_app_wibox.Thunar                          = left_app_wibox.confdir .. "icons/leftwibox/Thunar.png"
    left_app_wibox.firefox                         = left_app_wibox.confdir .. "icons/leftwibox/firefox.png"
    left_app_wibox.midori                          = left_app_wibox.confdir .. "icons/leftwibox/midori.png"
    left_app_wibox.qutebrowser                     = left_app_wibox.confdir .. "icons/leftwibox/qutebrowser.png"
    left_app_wibox.viber                           = left_app_wibox.confdir .. "icons/leftwibox/viber.png"
    left_app_wibox.deluge                          = left_app_wibox.confdir .. "icons/leftwibox/deluge.png"
    left_app_wibox.vim                             = left_app_wibox.confdir .. "icons/leftwibox/vim.png"
    left_app_wibox.notes                           = left_app_wibox.confdir .. "icons/leftwibox/notes.png"
    left_app_wibox.gimp                            = left_app_wibox.confdir .. "icons/leftwibox/gimp.png"
    left_app_wibox.screenshot                      = left_app_wibox.confdir .. "icons/leftwibox/screenshot.png"
    left_app_wibox.calc                            = left_app_wibox.confdir .. "icons/leftwibox/calc.png"
    left_app_wibox.zbstudio                        = left_app_wibox.confdir .. "icons/leftwibox/zbstudio.png"
    left_app_wibox.dfeet                           = left_app_wibox.confdir .. "icons/leftwibox/dfeet.png"

    local args      = args or {}

    left_app_wibox.fg_normal 	 	= args.fg_normal 		or "#ffffff"
    left_app_wibox.bg_normal 	 	= args.bg_normal 		or "#000000"
    left_app_wibox.iconsel_color 	= args.iconsel_color    	or "#ff0000"
    left_app_wibox.iconrun_color 	= args.iconrun_color    	or "#00ff00"
    left_app_wibox.separator_height 	= args.separator_height		or 3

    -- Create widget from corresponding *.png files
    local function create_leftwibox_widget (widget_args)
        local widget_args 	= widget_args 			or {}
        local icon 	  	= widget_args.icon 		or ""
        local app 	  	= widget_args.app		or ""

	-- Icon widget
        local widget = wibox.widget.imagebox()
        widget.app_icon = icon
	-- Separator
	local spacer = wibox.widget.textbox()
    	spacer.forced_height = left_app_wibox.separator_height

	-- Make selected icon 
	local function icon_sel (source_icon, sel_color)
--	    local img = cairo.ImageSurface.create(cairo.Format.ARGB32, 16, 16)
	    local img = cairo.ImageSurface.create_from_png(source_icon)
	    local cr  = cairo.Context(img)
	    cr:set_source(gears.color(sel_color))
	    cr:rectangle(0, 0, 5, 5)
	    cr:fill()
	    return img
	end

        -- Signals
	-- for icon widget
        widget:connect_signal('mouse::enter', function ()
            widget:set_image(icon_sel(icon, left_app_wibox.iconsel_color))
        end)
        widget:connect_signal('mouse::leave', function ()
            widget:set_image(icon)
        end)
        -- for separator
        spacer:connect_signal('mouse::enter', function ()
            widget:set_image(icon_sel(icon, left_app_wibox.iconsel_color))
        end)
        spacer:connect_signal('mouse::leave', function ()
            widget:set_image(icon)
        end)

        -- Application launch on mouse click
	-- for icon widget
        widget:buttons(awful.util.table.join (
            awful.button({}, 1, function()
                widget:set_image(icon_sel(icon, left_app_wibox.iconrun_color))
                awful.spawn(app)
            end)
        ))
	-- for separator
	spacer:buttons(awful.util.table.join (
            awful.button({}, 1, function()
                widget:set_image(icon_sel(icon, left_app_wibox.iconrun_color))
                awful.spawn(app)
            end)
        ))

        return { widget = widget, spacer = spacer }
    end

    left_app_wibox.widgets = { 
        -- terminal
    	mytermicon = create_leftwibox_widget({
            icon = left_app_wibox.term,
--            app = "/usr/bin/urxvtc" 
            app = awful.util.terminal .. " -e /usr/bin/tmux"
        }),
        -- midnight commander
    	mymcicon = create_leftwibox_widget({
            icon = left_app_wibox.mc,
            app = awful.util.terminal .. " -e /usr/bin/mc"
        }),
        -- vim
        myvimicon = create_leftwibox_widget({
            icon = left_app_wibox.vim,
--            app = "/usr/bin/urxvtc -e vim" 
            app = awful.util.terminal .. " -e vim"
    	}),
        -- ZeroBrane Studio
        myzbstudioicon = create_leftwibox_widget({
            icon = left_app_wibox.zbstudio,
            app = "/usr/bin/bash -c /home/user1/bin/zbstudio"
    	}),
        -- d-feet
        mydfeeticon = create_leftwibox_widget({
            icon = left_app_wibox.dfeet,
            app = "/usr/bin/d-feet"
    	}),
    	-- xfce4 notes
    	mynotesicon = create_leftwibox_widget({
            icon = left_app_wibox.notes,
            app = "/usr/bin/bash -c /usr/bin/xfce4-notes" 
    	}),
    	-- xfce4 task manager
   	mytaskmanicon = create_leftwibox_widget({
            icon = left_app_wibox.taskman,
            app = "/usr/bin/xfce4-taskmanager" 
    	}),
    	-- Thunar
    	myThunaricon = create_leftwibox_widget({
            icon = left_app_wibox.Thunar,
            app = "/usr/bin/thunar" 
    	}),
    	-- firefox 
    	myfirefoxicon = create_leftwibox_widget({
            icon = left_app_wibox.firefox,
            app = "/usr/bin/firefox" 
    	}),
    	-- midori 
    	mymidoriicon = create_leftwibox_widget({
            icon = left_app_wibox.midori,
            app = "/usr/bin/midori" 
    	}),
    	-- qutebrowser 
    	myqutebrowsericon = create_leftwibox_widget({
            icon = left_app_wibox.qutebrowser,
            app = "/usr/bin/qutebrowser" 
    	}),
    	-- viber 
    	myvibericon = create_leftwibox_widget({
            icon = left_app_wibox.viber,
            app = "/usr/bin/viber" 
    	}),
    	-- deluge 
    	mydelugeicon = create_leftwibox_widget({
            icon = left_app_wibox.deluge,
            app = "/usr/bin/deluge" 
    	}),
    	-- gimp 
    	mygimpicon = create_leftwibox_widget({
            icon = left_app_wibox.gimp,
            app = "/usr/bin/gimp" 
    	}),
    	-- xfce screenshooter 
    	myscreenshoticon = create_leftwibox_widget({
            icon = left_app_wibox.screenshot,
            app = "/usr/bin/xfce4-screenshooter"
    	}),
    	-- galculator calc
    	mycalcicon = create_leftwibox_widget({
            icon = left_app_wibox.calc,
            app = "/usr/bin/galculator"
    	})
    }

    function left_app_wibox.vertical_wibox(s)
    	-- Create the vertical wibox
    	s.dockheight = (39 *  s.workarea.height)/100	-- change first number to set wibox height

    	s.myleftwibox = wibox({ screen = s, x=0, y=s.workarea.height/2 - s.dockheight/2, width = 1, height = s.dockheight, fg = left_app_wibox.fg_normal, bg = left_app_wibox.bg_normal, ontop = true, visible = true, type = "dock" })

        if s.index > 1 and s.myleftwibox.y == 0 then
            s.myleftwibox.y = screen[1].myleftwibox.y
    	end

    	-- Add widgets to the vertical wibox
    	s.myleftwibox:setup {
            layout = wibox.layout.align.vertical,
            {
            	layout = wibox.layout.fixed.vertical,
            	left_app_wibox.widgets.mytermicon.widget,
            	left_app_wibox.widgets.mytermicon.spacer,
            	left_app_wibox.widgets.mymcicon.widget,
            	left_app_wibox.widgets.mymcicon.spacer,
           	left_app_wibox.widgets.myThunaricon.widget,
           	left_app_wibox.widgets.myThunaricon.spacer,
            	left_app_wibox.widgets.myvimicon.widget,
            	left_app_wibox.widgets.myvimicon.spacer,
            	left_app_wibox.widgets.myzbstudioicon.widget,
            	left_app_wibox.widgets.myzbstudioicon.spacer,
            	left_app_wibox.widgets.mydfeeticon.widget,
            	left_app_wibox.widgets.mydfeeticon.spacer,
            	left_app_wibox.widgets.mynotesicon.widget,
            	left_app_wibox.widgets.mynotesicon.spacer,
            	left_app_wibox.widgets.mycalcicon.widget,
            	left_app_wibox.widgets.mycalcicon.spacer,
            	left_app_wibox.widgets.myfirefoxicon.widget,
            	left_app_wibox.widgets.myfirefoxicon.spacer,
            	left_app_wibox.widgets.mymidoriicon.widget,
            	left_app_wibox.widgets.mymidoriicon.spacer,
            	left_app_wibox.widgets.myqutebrowsericon.widget,
            	left_app_wibox.widgets.myqutebrowsericon.spacer,
            	left_app_wibox.widgets.mydelugeicon.widget,
            	left_app_wibox.widgets.mydelugeicon.spacer,
            	left_app_wibox.widgets.myvibericon.widget,
            	left_app_wibox.widgets.myvibericon.spacer,
            	left_app_wibox.widgets.mygimpicon.widget,
            	left_app_wibox.widgets.mygimpicon.spacer,
            	left_app_wibox.widgets.myscreenshoticon.widget,
            	left_app_wibox.widgets.myscreenshoticon.spacer,
            	left_app_wibox.widgets.mytaskmanicon.widget,
            	left_app_wibox.widgets.mytaskmanicon.spacer
            }
    	}

        s.myleftwibox:connect_signal("mouse::leave", function()
            for k,v in pairs(left_app_wibox.widgets) do
                v.widget:set_image(nil)
            end    
            local s = awful.screen.focused()
            s.myleftwibox.width = 1
        end)
        s.myleftwibox:connect_signal("mouse::enter", function()
            for k,v in pairs(left_app_wibox.widgets) do
                v.widget:set_image(v.widget.app_icon)
            end    
            local s = awful.screen.focused()
            s.myleftwibox.width = 16
        end)
    end
	
    return left_app_wibox
end

return factory
