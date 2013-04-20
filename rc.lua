-- Custom Awesome Config
gears 	        = require("gears")
awful           = require("awful")
awful.rules     = require("awful.rules")
awful.autofocus = require("awful.autofocus")
wibox           = require("wibox")
beautiful       = require("beautiful")
naughty         = require("naughty")
vicious         = require("vicious")

home = os.getenv("HOME")
os.setlocale(os.getenv("LANG"))

beautiful.init(home .. "/.config/awesome/theme/theme.lua")

-- Program Preferences
terminal 	= "urxvt"
editor 		= "vim"
editor_cmd 	= terminal .. " -e " .. editor
gui_editor 	= "subl"
browser 	= "chromium"
tasks 		= terminal .. " -e htop"
musicplr 	= terminal .. " -g 130x34-320+16 -e ncmpcpp"

modkey = "Mod4" -- Windows key
altkey = "Mod1"

-- Error Handling, fallback to preset
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical, text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
	in_error = false
	awesome.connect_signal("debug::error", function (err)
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
			title = "Oops, an error happened!", text = err })
		in_error = false
	end)
end

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts = {
	awful.layout.suit.floating,			-- 1
	awful.layout.suit.tile,				-- 2
	awful.layout.suit.tile.left,		-- 3
	awful.layout.suit.tile.bottom,		-- 4
	awful.layout.suit.tile.top,			-- 5
	awful.layout.suit.fair,				-- 6
	awful.layout.suit.fair.horizontal,	-- 7
	awful.layout.suit.spiral,			-- 8
	awful.layout.suit.spiral.dwindle,	-- 9
	awful.layout.suit.max,				-- 10
}

-- Wallpaper
if beautiful.wallpaper then
	for s = 1, screen.count() do
		gears.wallpaper.maximized(beautiful.wallpaper, s, true)
	end
end
					
-- Tags
tags = {
	names = {
		"Chrome",
		"Skype",
		"SpaceFM",
		"Code",
		"GIMP",
		"Servers",
		"IRC"},

	layout = {
		layouts[10],	-- Chrome [Max]
		layouts[1],		-- Skype [Floating]
		layouts[1],		-- SpaceFM [Floating]
		layouts[6],		-- Code [Fair]
		layouts[1],		-- GIMP [Floating]
		layouts[6], 	-- Servers [Fair]
		layouts[2]} 	-- IRC [Tiling]
}

for s = 1, screen.count() do
	tags[s] = awful.tag(tags.names, s, tags.layout)
end

---- Start of Widgets

-- Colours
spanStart = '<span '
spanEnd = '</span>'
font = 'font="Terminus 9"'
white = 'color="#b2b2b2"'
red = 'color="#e54c62"'
blue = 'color="#00aeff"'
green = 'color="#1dff00"'

-- Clock
iconClock = wibox.widget.imagebox()
iconClock:set_image(beautiful.widget_clock)

widgetClock = awful.widget.textclock(spanStart .. font .. blue .. "> %a %d %b  %H:%M" .. spanEnd)

-- Music widget
iconMPD = wibox.widget.imagebox()
iconMPD:set_image(beautiful.widget_music)
iconMPD:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.util.spawn_with_shell(musicplr) end)))

widgetMPD = wibox.widget.textbox()
vicious.register(widgetMPD, vicious.widgets.mpd,
	function(widget, args)
		if (args["{state}"] == "Play") then
			iconMPD:set_image(beautiful.widget_music_on)
			return spanStart .. font .. red .. '>' ..  args["{Title}"] .. spanStart .. white .. "> - " .. spanEnd .. spanStart .. green .. '>'  .. args["{Artist}"] .. spanEnd .. spanEnd
		elseif (args["{state}"] == "Pause") then
			iconMPD:set_image(beautiful.widget_music)
			return spanStart .. font .. white .. '>' .. "paused" .. spanEnd
		else
			iconMPD:set_image(beautiful.widget_music)
			return ""
		end
	end, 1)

-- MEM widget
iconMem = wibox.widget.imagebox()
iconMem:set_image(beautiful.widget_mem)

widgetMem = wibox.widget.textbox()
vicious.register(widgetMem, vicious.widgets.mem, spanStart .. font .. blue .. '>$1% [$2MB/$3MB] ' .. spanEnd, 13)

-- CPU widget
iconCPU = wibox.widget.imagebox()
iconCPU:set_image(beautiful.widget_cpu)
iconCPU:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.util.spawn(tasks, false) end)))

widgetCPU = wibox.widget.textbox()
vicious.register(widgetCPU, vicious.widgets.cpu, spanStart .. font .. green .. '>1%' .. spanEnd, 3)

-- Temp widget
iconTemp = wibox.widget.imagebox()
iconTemp:set_image(beautiful.widget_temp)

widgetTemp = wibox.widget.textbox()
vicious.register(widgetTemp, vicious.widgets.thermal, spanStart .. font .. green .. '>$1°C' .. spanEnd, 9, {"coretemp.0", "core"} )

-- FS Widget
iconFS = wibox.widget.imagebox()
iconFS:set_image(beautiful.widget_hdd)

widgetFS = wibox.widget.textbox()
vicious.register(widgetFS, vicious.widgets.fs,
	function (widget, args)
		if args["{/home used_p}"] >= 95 and args["{/home used_p}"] < 99 then
			return spanStart .. font .. white .. '>' .. args["{/home used_p}"] .. '%' .. spanEnd 
		elseif args["{/home used_p}"] >= 99 and args["{/home used_p}"] <= 100 then
			naughty.notify({ title = "Attenzione", text = "Partizione /home esaurita!\nFa' un po' di spazio.",
			timeout = 10,
			position = "top_right",
			fg = beautiful.fg_urgent,
			bg = beautiful.bg_urgent })
			return spanStart .. font .. white .. '>' .. args["{/home used_p}"] .. '%' .. spanEnd 
		else
			return spanStart .. font .. white .. '>' .. args["{/home used_p}"] .. '%' .. spanEnd
		end
	end, 600)


local infos = nil

function remove_info()
	if infos ~= nil then 
		naughty.destroy(infos)
		infos = nil
	end
end

function add_info()
	remove_info()
	local capi = {
	mouse = mouse,
	screen = screen
	}
	local cal = awful.util.pread(home .. "/.config/awesome/scripts/dfs")
	cal = string.gsub(cal, "          ^%s*(.-)%s*$", "%1")
	infos = naughty.notify({
		text = string.format('<span font_desc="%s">%s</span>', "Terminus", cal),
		timeout = 0,
		position = "top_right",
		margin = 10,
		height = 170,
		width = 585,
		screen	= capi.mouse.screen
	})
end

iconFS:connect_signal('mouse::enter', function () add_info() end)
iconFS:connect_signal('mouse::leave', function () remove_info() end)

-- Volume widget
iconVol = wibox.widget.imagebox()
iconVol:set_image(beautiful.widget_vol)

widgetVol = wibox.widget.textbox()
vicious.register(widgetVol, vicious.widgets.volume,  
	function (widget, args)
		if (args[2] ~= "♩" ) then 
			if (args[1] == 0) then iconVol:set_image(beautiful.widget_vol_no)
			elseif (args[1] <= 50) then  iconVol:set_image(beautiful.widget_vol_low)
			else iconVol:set_image(beautiful.widget_vol)
			end
		else iconVol:set_image(beautiful.widget_vol_mute) 
		end
		return spanStart .. font .. green .. '>' .. args[1] .. '%' .. spanEnd
	end, 1, "Master")

-- Separators
decoSpace = wibox.widget.textbox(' ')
arrl = wibox.widget.imagebox()
arrl:set_image(beautiful.arrl)
arrl_dl = wibox.widget.imagebox()
arrl_dl:set_image(beautiful.arrl_dl)
arrl_ld = wibox.widget.imagebox()
arrl_ld:set_image(beautiful.arrl_ld)

-- Set up layout
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
	awful.button({ }, 1, awful.tag.viewonly), 											-- View tag
	awful.button({ modkey }, 1, awful.client.movetotag), 								-- Move client to tag
	awful.button({ }, 3, awful.tag.viewtoggle), 										-- View tag with current
	awful.button({ modkey }, 3, awful.client.toggletag), 								-- Add client to tag (toggle)
	awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end), 	-- Scrollwheel tag nav
	awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end))

mytasklist = {}
mytasklist.buttons = awful.util.table.join(

	-- Window max/minimize on title click
	awful.button({ }, 1,
		function (c)
			if c == client.focus then
				c.minimized = true
			else
				c.minimized = false
				if not c:isvisible() then
					awful.tag.viewonly(c:tags()[1])
				end
				client.focus = c
				c:raise()
			end
		end),

	-- Scrollwheel nav between open windows
	awful.button({ }, 4,
		function ()
			awful.client.focus.byidx(1)
			if client.focus then client.focus:raise() end
		end),
	awful.button({ }, 5,
		function ()
			awful.client.focus.byidx(-1)
			if client.focus then client.focus:raise() end
		end))

for s = 1, screen.count() do
		
	-- Create a promptbox for each screen
	mypromptbox[s] = awful.widget.prompt()

	-- We need one layoutbox per screen.
	mylayoutbox[s] = awful.widget.layoutbox(s)
	mylayoutbox[s]:buttons(awful.util.table.join(

		-- Layout selection by clicks and scrollwheel
		awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
		awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
		awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
		awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

	-- Create a taglist widget
	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

	-- Create a tasklist widget
	mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

	-- Create the upper wibox
	mywibox[s] = awful.wibox({ position = "top", screen = s, height = 18 }) 
			
	-- Widgets that are aligned to the upper left
	local left_layout = wibox.layout.fixed.horizontal()
	left_layout:add(decoSpace)
	left_layout:add(mytaglist[s])
	left_layout:add(mypromptbox[s])
	left_layout:add(decoSpace)

	-- Widgets that are aligned to the upper right
	local right_layout = wibox.layout.fixed.horizontal()
	if s == 1 then right_layout:add(wibox.widget.systray()) end

	right_layout:add(decoSpace)

	right_layout:add(iconMPD)
	right_layout:add(widgetMPD)

	right_layout:add(decoSpace)

	right_layout:add(iconVol)
	right_layout:add(widgetVol)

	right_layout:add(decoSpace)

	right_layout:add(iconMem)
	right_layout:add(widgetMem)

	right_layout:add(decoSpace)

	right_layout:add(iconCPU)
	right_layout:add(widgetCPU)    

	right_layout:add(decoSpace)

	right_layout:add(iconTemp)
	right_layout:add(widgetTemp)

	right_layout:add(decoSpace)

	right_layout:add(iconFS)
	right_layout:add(widgetFS)

	right_layout:add(decoSpace)

	right_layout:add(widgetClock)

	right_layout:add(decoSpace)

	right_layout:add(mylayoutbox[s])

	-- Now bring it all together (with the tasklist in the middle)
	local layout = wibox.layout.align.horizontal()
	layout:set_left(left_layout)
	layout:set_middle(mytasklist[s])
	layout:set_right(right_layout)    
	mywibox[s]:set_widget(layout)

end

-- Key bindings
globalkeys = awful.util.table.join(

	-- Print screen
	awful.key({ altkey }, "p", function() awful.util.spawn("screenshot",false) end),

	-- Move between tags
	awful.key({ modkey }, "Left",   awful.tag.viewprev),
	awful.key({ modkey }, "Right",  awful.tag.viewnext),

	-- Move between windows on screen
	awful.key({ modkey }, "k", function () awful.client.focus.byidx( 1) if client.focus then client.focus:raise() end end),
	awful.key({ modkey }, "j", function () awful.client.focus.byidx(-1) if client.focus then client.focus:raise() end end),

	-- Show/Hide Wibox
	awful.key({ modkey }, "b", function () mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible end),

	-- Dropdown terminal
	awful.key({ modkey }, "z", function () scratch.drop(terminal) end),

	-- Volume control
	awful.key({ "Control" }, "Up", function () awful.util.spawn("amixer set Master playback 1%+", false ) vicious.force({ volumewidget }) end),
	awful.key({ "Control" }, "Down", function () awful.util.spawn("amixer set Master playback 1%-", false ) vicious.force({ volumewidget }) end),
	awful.key({ "Control" }, "m", function () awful.util.spawn("amixer set Master playback mute", false ) vicious.force({ volumewidget }) end),
	awful.key({ "Control" }, "u", function () awful.util.spawn("amixer set Master playback unmute", false ) vicious.force({ volumewidget }) end),

	-- Music control
	awful.key({ altkey, "Control" }, "Up", function () awful.util.spawn( "mpc toggle", false )  vicious.force({ mpdwidget } ) end),
	awful.key({ altkey, "Control" }, "Down", function () awful.util.spawn( "mpc stop", false )  vicious.force({ mpdwidget } ) end ),
	awful.key({ altkey, "Control" }, "Left", function () awful.util.spawn( "mpc prev", false ) vicious.force({ mpdwidget } ) end ),
	awful.key({ altkey, "Control" }, "Right", function () awful.util.spawn( "mpc next", false ) vicious.force({ mpdwidget } ) end ),

	-- User programs
	awful.key({ modkey }, "g", function () awful.util.spawn( "gimp", false ) end),
	awful.key({ modkey }, "d", function () awful.util.spawn( "spacefm", false ) end),

	-- Open new terminals
	awful.key({ modkey }, "Return", function() awful.util.spawn( terminal, false) end),
	
	-- Prompt
	awful.key({ modkey }, "p", function () mypromptbox[mouse.screen]:run() end),

	-- Awesome control
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	awful.key({ modkey, "Shift" }, "q", awesome.quit)
)

clientkeys = awful.util.table.join(

	-- Make fullscreen
	awful.key({ modkey }, "f", function (c) c.fullscreen = not c.fullscreen  end),

	-- Close
	awful.key({ modkey, "Shift"}, "c", function (c) c:kill() end),

	-- Toggle floating
	awful.key({ modkey, "Control"}, "space",  awful.client.floating.toggle ),

	awful.key({ modkey, "Control"}, "Return", function (c) c:swap(awful.client.getmaster()) end),
	awful.key({ modkey }, "o", awful.client.movetoscreen ),
	awful.key({ modkey }, "t", function (c) c.ontop = not c.ontop end)
)

-- Compute the maximum number of digit we need, limited to 9
tagCount = 0
for s = 1, screen.count() do
	 tagCount = math.min(9, math.max(#tags[s], tagCount));
end

-- Bind numbers to tags
for i = 1, tagCount do
	globalkeys = awful.util.table.join(globalkeys,
		awful.key({ modkey }, "#" .. i + 9,
			function ()
						screen = mouse.screen
						if tags[screen][i] then
								awful.tag.viewonly(tags[screen][i])
						end
			end),
		awful.key({ modkey, "Control" }, "#" .. i + 9,
			function ()
					screen = mouse.screen
					if tags[screen][i] then
							awful.tag.viewtoggle(tags[screen][i])
					end
			end),
		awful.key({ modkey, "Shift" }, "#" .. i + 9,
			function ()
					if client.focus and tags[client.focus.screen][i] then
							awful.client.movetotag(tags[client.focus.screen][i])
					end
			end),
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
			function ()
					if client.focus and tags[client.focus.screen][i] then
							awful.client.toggletag(tags[client.focus.screen][i])
					end
			end))
end

-- Mouse window manipulation
mouseWindowManipulation = awful.util.table.join(
	awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
	awful.button({ modkey }, 1, awful.mouse.client.move),
	awful.button({ modkey }, 3, awful.mouse.client.resize))

root.keys(globalkeys)

-- Rules

awful.rules.rules = {
	{ rule = { }, properties = {
		border_width = beautiful.border_width,
		border_color = beautiful.border_focus,
		focus = true,
		keys = clientkeys,
		buttons = mouseWindowManipulation,
		size_hints_honor = false }},

	{ rule = { class = "Skype" }, callback = function (c) awful.client.movetotag(tags[mouse.screen][2], c) end },
	{ rule = { class = "SpaceFM" }, callback = function (c) awful.client.movetotag(tags[mouse.screen][3], c) end },
	{ rule = { class = "GIMP" }, callback = function (c) awful.client.movetotag(tags[mouse.screen][5], c) end },

	{ rule = { name = ". - Chromium" },
		properties = { border_width = "0" },
		callback = function (c) awful.client.movetotag(tags[mouse.screen][1], c) end },

	{ rule = { name = ". - Sublime Text 2 (UNREGISTERED)" },
		properties = { border_width = "0" },
		callback = function (c) awful.client.movetotag(tags[mouse.screen][4], c) end }
}

client.connect_signal("manage", function (c, startup)

    -- Sloppy Focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)