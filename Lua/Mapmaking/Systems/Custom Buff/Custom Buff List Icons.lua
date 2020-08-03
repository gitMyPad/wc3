do
    local tb                = protected_table()
    local list              = CustomBuff.ListPanel
    CustomBuff.ListIcons    = setmetatable({}, tb)

    tb.TOC_PATH             = "war3mapImported\\BoxedText.toc"

    tb._ICON_LIST           = {}
    tb.ICON_PATH            = "UI\\Custom\\EmptyInventory.blp"
    tb.ICON_HEIGHT          = 0.015
    tb.ICON_MAX_COUNT       = 5

    tb.ICON_REL_X           = 0.002
    tb.ICON_REL_Y           = 0

    tb.ICON_HEIGHT          = math.min(tb.ICON_HEIGHT, list.HEIGHT)
    tb.ICON_WIDTH           = tb.ICON_HEIGHT
    tb.ICON_MAX_COUNT       = math.floor(tb.ICON_MAX_COUNT + 0.2)

    tb.TOOLTIP_MARGIN_TOP   = 0.005
    tb.TOOLTIP_MARGIN_BOT   = 0.010
    tb.TOOLTIP_MARGIN_LEFT  = 0.005
    tb.TOOLTIP_MARGIN_RIGHT = 0.005

    tb.ICON_MARGIN_X        = 0.006
    tb.ICON_MARGIN_Y        = 0.004

    tb.TOOLTIP_HEIGHT       = 0.02
    tb.TOOLTIP_WIDTH        = CustomBuff.Main.WIDTH

    tb.ICON_TOOLTIP_HEIGHT  = 0.03
    tb.ICON_TOOLTIP_WIDTH   = tb.ICON_TOOLTIP_HEIGHT
    tb.ICON_NAME_HEIGHT     = tb.ICON_TOOLTIP_HEIGHT
    tb.ICON_NAME_WIDTH      = tb.TOOLTIP_WIDTH - tb.ICON_TOOLTIP_WIDTH 
                            
    tb.ICON_TEXT_SCALE      = 1.15
    tb.DESC_TEXT_SCALE      = 1.15
    tb.ICON_TEXT_DENSITY    = 0.004
    tb.ICON_TEXT_LATERAL    = 0.0115

    tb.ICON_TEXT_LATERAL    = tb.ICON_TEXT_LATERAL*tb.DESC_TEXT_SCALE

    function tb.count_newlines(str)
        local i, j = 0, 0
        while true do
            j = select(2, str:find('\n', j))
            if not j then break;
            end
            i = i + 1
        end
        return i
    end
    function tb.get_frame(i)
        i = i or 1
        return tb._ICON_LIST[i]
    end
    function tb._process_max_icons()
        local max   = tb.ICON_MAX_COUNT
        local width = tb.ICON_WIDTH
        local rel_x = tb.ICON_REL_X
        while width*max + rel_x*(max - 1) > list.WIDTH do
            max = max - 1
        end
        tb.ICON_MAX_COUNT   = max
        tb.ICONS_WIDTH      = width*max + rel_x*(max - 1)
    end
    tb._process_max_icons()

    tb.REL_X                = (list.WIDTH - tb.ICONS_WIDTH)/2
    function tb._create()
        local o     = {}
        o.main      = BlzCreateFrameByType("BACKDROP", "CustomBuffIconBG", list.panel, "", 0)
        o.icon      = BlzCreateFrameByType("BACKDROP", "CustomBuffIcon", list.panel, "", 0)
        o.button    = BlzCreateFrameByType("GLUEBUTTON", "CustomBuffButton", o.icon, "IconicButtonTemplate", 0)
        o.tooltip   = {
            frame       = BlzCreateFrame("BoxedText", o.button, 0, 0),
            width       = tb.TOOLTIP_WIDTH,
            height      = tb.TOOLTIP_HEIGHT + tb.ICON_TOOLTIP_HEIGHT,
        }
        o.tooltip.height    = o.tooltip.height + tb.TOOLTIP_MARGIN_TOP + tb.TOOLTIP_MARGIN_BOT
        o.tooltip.name      = BlzCreateFrameByType("TEXT", "CustomBuffName", o.tooltip.frame, "", 0)
        o.tooltip.icon      = BlzCreateFrameByType("BACKDROP", "CustomBuffTipIcon", o.tooltip.frame, "", 0)
        o.tooltip.text      = BlzCreateFrameByType("TEXT", "CustomBuffDescription", o.tooltip.frame, "", 0)
        setmetatable(o, tb)

        tb._setup_main(o)
        tb._setup_tooltip(o)
        return o
    end
    function tb:_setup_main()
        BlzFrameSetSize(self.main, tb.ICON_WIDTH, tb.ICON_HEIGHT)
        BlzFrameSetTexture(self.main, tb.ICON_PATH, 0, true)

        BlzFrameClearAllPoints(self.icon)
        BlzFrameClearAllPoints(self.button)
        BlzFrameSetAllPoints(self.icon, self.main)
        BlzFrameSetAllPoints(self.button, self.icon)

        BlzFrameSetParent(self.icon, nil)
        BlzFrameSetVisible(self.icon, false)
        BlzFrameSetEnable(self.button, false)
    end
    function tb:_setup_tooltip()
        BlzFrameSetParent(self.tooltip.frame, nil)
        BlzFrameSetVisible(self.tooltip.frame, false)

        local width = self.tooltip.width - tb.TOOLTIP_MARGIN_LEFT - tb.TOOLTIP_MARGIN_RIGHT
        BlzFrameSetSize(self.tooltip.frame, self.tooltip.width, self.tooltip.height + tb.ICON_MARGIN_Y)
        BlzFrameSetSize(self.tooltip.icon, tb.ICON_TOOLTIP_WIDTH, tb.ICON_TOOLTIP_HEIGHT)
        BlzFrameSetSize(self.tooltip.name, tb.ICON_NAME_WIDTH, tb.ICON_NAME_HEIGHT)
        BlzFrameSetSize(self.tooltip.text, width/tb.DESC_TEXT_SCALE,
                        self.tooltip.height - tb.ICON_TOOLTIP_HEIGHT - tb.TOOLTIP_MARGIN_BOT)
        
        BlzFrameClearAllPoints(self.tooltip.frame)
        BlzFrameClearAllPoints(self.tooltip.icon)
        BlzFrameClearAllPoints(self.tooltip.name)
        BlzFrameClearAllPoints(self.tooltip.text)

        BlzFrameSetPoint(self.tooltip.frame, FRAMEPOINT_TOPLEFT, CustomBuff.Main.panel, FRAMEPOINT_BOTTOMLEFT, 
                            0, 0)
        BlzFrameSetPoint(self.tooltip.icon, FRAMEPOINT_TOPLEFT, self.tooltip.frame, FRAMEPOINT_TOPLEFT, 
                            tb.TOOLTIP_MARGIN_RIGHT, -tb.TOOLTIP_MARGIN_TOP)
        BlzFrameSetPoint(self.tooltip.name, FRAMEPOINT_LEFT, self.tooltip.icon, FRAMEPOINT_RIGHT,
                            tb.ICON_MARGIN_X, 0)
        BlzFrameSetPoint(self.tooltip.text, FRAMEPOINT_TOPLEFT, self.tooltip.icon, FRAMEPOINT_BOTTOMLEFT, 0, -tb.ICON_MARGIN_Y)

        BlzFrameSetTextAlignment(self.tooltip.text, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        BlzFrameSetTextAlignment(self.tooltip.name, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
        BlzFrameSetScale(self.tooltip.name, tb.ICON_TEXT_SCALE)
        BlzFrameSetScale(self.tooltip.text, tb.DESC_TEXT_SCALE)
    end

    function tb._condense_str(...)
        local t     = {...}
        if #t <= 0 then return "";
        end
        t.str       = ""
        for i = 1, #t do
            t[i]    = (type(t[i]) == 'string' and t[i]) or tostring(t[i])
            t.str   = t.str .. t[i]
        end
        return t.str
    end
    function tb:visible()
        return BlzFrameIsVisible(self.icon)
    end
    function tb:show(flag)
        BlzFrameSetVisible(self.icon, flag)
    end
    function tb:activate(flag)
        BlzFrameSetEnable(self.button, flag)
    end
    function tb:set_icon(iconpath)
        iconpath = (type(iconpath) == 'string' and iconpath) or tostring(iconpath)
        BlzFrameSetTexture(self.icon, iconpath, 0, true)
        BlzFrameSetTexture(self.tooltip.icon, iconpath, 0, true)
    end
    function tb:set_name(...)
        local str = tb._condense_str(...)
        BlzFrameSetText(self.tooltip.name, tb._condense_str(...))
    end
    function tb:set_desc(...)
        local str       = tb._condense_str(...)
        BlzFrameSetText(self.tooltip.text, str)
        
        local width     = (self.tooltip.width - tb.TOOLTIP_MARGIN_LEFT - tb.TOOLTIP_MARGIN_RIGHT)
        local lateral   = math.floor(#str/width*tb.ICON_TEXT_DENSITY*tb.DESC_TEXT_SCALE)
        local newlines  = tb.count_newlines(str)

        lateral         = lateral + newlines
        local size      = self.tooltip.height + lateral*tb.ICON_TEXT_LATERAL
        BlzFrameSetSize(self.tooltip.frame, self.tooltip.width, size + tb.ICON_MARGIN_Y)
        BlzFrameSetSize(self.tooltip.text, width/tb.DESC_TEXT_SCALE, size - tb.ICON_TOOLTIP_HEIGHT - tb.TOOLTIP_MARGIN_BOT)
    end
    function tb:unfocus()
        BlzFrameSetFocus(self.button, false)
    end

    Initializer("SYSTEM", function()
        tb.ICON_NAME_WIDTH  = tb.ICON_NAME_WIDTH - tb.TOOLTIP_MARGIN_LEFT - tb.TOOLTIP_MARGIN_RIGHT
        tb.ICON_NAME_WIDTH  = tb.ICON_NAME_WIDTH - tb.ICON_MARGIN_X
        BlzLoadTOCFile(tb.TOC_PATH)

        tb._ICON_LIST[1] = tb._create()
        BlzFrameSetPoint(tb._ICON_LIST[1].main, FRAMEPOINT_LEFT, list.panel, FRAMEPOINT_LEFT, tb.REL_X, 0)
        for i = 2, tb.ICON_MAX_COUNT do
            tb._ICON_LIST[i] = tb._create()
            BlzFrameSetPoint(tb._ICON_LIST[i].main, FRAMEPOINT_LEFT, tb._ICON_LIST[i - 1].main, FRAMEPOINT_RIGHT, tb.ICON_REL_X, 0)
        end
    end)
end