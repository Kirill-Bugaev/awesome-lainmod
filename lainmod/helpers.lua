--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luca CPZ

--]]

local wibox 	 = require("wibox")

local spawn      = require("awful.spawn")
local timer      = require("gears.timer")
local debug      = require("debug")
local io         = { lines = io.lines,
                     open  = io.open,
	     	     popen = io.popen }
local pairs      = pairs
local rawget     = rawget
local table      = { sort  = table.sort, insert = table.insert }

-- Lain helper functions for internal use
-- lain.helpers
local helpers = {}

helpers.lain_dir    = debug.getinfo(1, 'S').source:match[[^@(.*/).*$]]
helpers.icons_dir   = helpers.lain_dir .. 'icons/'
helpers.scripts_dir = helpers.lain_dir .. 'scripts/'

-- {{{ Modules loader

function helpers.wrequire(table, key)
    local module = rawget(table, key)
    return module or require(table._NAME .. '.' .. key)
end

-- }}}

-- {{{ File operations

-- check if the file exists and is readable
function helpers.file_exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end

-- get a table with all lines from a file
function helpers.lines_from(path)
    local lines = {}
    for line in io.lines(path) do
        lines[#lines + 1] = line
    end
    return lines
end

-- get a table with all lines from a file matching regexp
function helpers.lines_match(regexp, path)
    local lines = {}
    for line in io.lines(path) do
        if string.match(line, regexp) then
            lines[#lines + 1] = line
        end
    end
    return lines
end

-- get first line of a file
function helpers.first_line(path)
    local file, first = io.open(path, "rb"), nil
    if file then
        first = file:read("*l")
        file:close()
    end
    return first
end

-- get first non empty line from a file
function helpers.first_nonempty_line(path)
    for line in io.lines(path) do
        if #line then return line end
    end
    return nil
end

-- get toggle state from file
function helpers.get_toggle_state(path)
    local first = helpers.first_line(path)
    local res = false
    if first and (first ~= "") and (first ~= "0") then res = true end
    return res
end		

-- set toggle state into file
function helpers.set_toggle_state(path, state)
    if state then
	state_str = "1"
    else
	state_str = "0"
    end
    cmd = "echo -n " .. state_str .. " >" .. path .. " 2>/dev/null"
    helpers.async_with_shell(cmd, function() end)
end		

-- rewrite string to file with shell 'echo'
function helpers.rewrite_with_echo(path, str)
    cmd = "echo -n " .. str .. " >" .. path .. " 2>/dev/null"
    helpers.async_with_shell(cmd, function() end)
end		
-- }}}

-- {{{ Timer maker

helpers.timer_table = {}

function helpers.newtimer(name, timeout, fun, nostart, stoppable)
    if not name or #name == 0 then return end
    name = (stoppable and name) or timeout
    if not helpers.timer_table[name] then
        helpers.timer_table[name] = timer({ timeout = timeout })
        helpers.timer_table[name]:start()
    end
    helpers.timer_table[name]:connect_signal("timeout", fun)
    if not nostart then
        helpers.timer_table[name]:emit_signal("timeout")
    end
    return stoppable and helpers.timer_table[name]
end

-- }}}

-- {{{ Pipe operations

-- run a command and execute a function on its output (asynchronous pipe)
-- @param cmd the input command
-- @param callback function to execute on cmd output
-- @return cmd PID
function helpers.async(cmd, callback)
    return spawn.easy_async(cmd,
    function (stdout, stderr, reason, exit_code)
        callback(stdout, exit_code)
    end)
end

-- like above, but call spawn.easy_async with a shell
function helpers.async_with_shell(cmd, callback)
    return spawn.easy_async_with_shell(cmd,
    function (stdout, stderr, reason, exit_code)
        callback(stdout, exit_code)
    end)
end

-- run a command and execute a function on its output line by line
function helpers.line_callback(cmd, callback)
    return spawn.with_line_callback(cmd, {
        stdout = function (line)
            callback(line)
        end,
    })
end

-- }}}

-- {{{ A map utility

helpers.map_table = {}

function helpers.set_map(element, value)
    helpers.map_table[element] = value
end

function helpers.get_map(element)
    return helpers.map_table[element]
end

-- }}}

-- {{{ Misc

-- Make single widget from table of widgets 
-- awesome v4.2 wibox.widget can make single widget from first 3 widgets only in table argument
-- so need to wrap widgets recursively to create single
function helpers.make_single_widget (wt, layout)

    local wt_with_layout = {}

    if #wt <= 3 then
	wt_with_layout = wt
    else

	local wn = math.floor(#wt / 3)
	if #wt % 3 ~= 0 then wn = wn + 1 end

	local new_wt = {}
	for i = 1,wn,1 do
	    table.insert(new_wt, wt[i])
	end
	local w1 = helpers.make_single_widget(new_wt, layout)

	new_wt = {}
	for i = wn+1,wn*2,1 do
	    table.insert(new_wt, wt[i])
	end
	local w2 = helpers.make_single_widget(new_wt, layout)

	new_wt = {}
	for i = 2*wn+1,#wt,1 do
	    table.insert(new_wt, wt[i])
	end
	local w3 = helpers.make_single_widget(new_wt, layout)

	table.insert(wt_with_layout, w1)
	table.insert(wt_with_layout, w2)
	table.insert(wt_with_layout, w3)

    end

--    wt_with_layout.layout = wibox.layout.align.horizontal
    wt_with_layout.layout = layout
    return wibox.widget(wt_with_layout)
    
end

-- shallow table copy
function helpers.shallow_table_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- check if an element exist on a table
function helpers.element_in_table(element, tbl)
    for _, i in pairs(tbl) do
        if i == element then
            return true
        end
    end
    return false
end

-- iterate over table of records sorted by keys
function helpers.spairs(t)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    table.sort(keys)

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- create the partition of singletons of a given set
-- example: the trivial partition set of {a, b, c}, is {{a}, {b}, {c}}
function helpers.trivial_partition_set(set)
    local ss = {}
    for _,e in pairs(set) do
        ss[#ss+1] = {e}
    end
    return ss
end

-- creates the powerset of a given set
function helpers.powerset(s)
    if not s then return {} end
    local t = {{}}
    for i = 1, #s do
        for j = 1, #t do
            t[#t+1] = {s[i],unpack(t[j])}
        end
    end
    return t
end

-- }}}

return helpers
