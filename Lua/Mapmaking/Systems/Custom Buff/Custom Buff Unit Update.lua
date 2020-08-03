do
    local tb            = protected_table()
    local system        = CustomBuff.UnitInfo
    local icons         = CustomBuff.ListIcons
    local event         = CustomBuff.ListEvent
    local selection     = CustomBuff.Selection
    CustomBuff.Update   = setmetatable({}, tb)

    local mtb           = {}
    mtb.select_unit     = {}
    mtb.select_stamp    = {}
    tb._INTERVAL        = 1/4.

    --[[
        TO-DO:  Include a maximum number count for convenience.
    ]]
    function tb._unrender(p, i, j)
        while j <= icons.ICON_MAX_COUNT do
            local icon = icons.get_frame(j)
            if mtb.player == p then
                if icon:visible() then
                    icon:show(false)
                    icon:activate(false)
                end
                icon:set_icon(nil)
                icon:set_name(nil)
                icon:set_desc(nil)
            end
            event.deactivate_buff(p, j)
            j = j + 1
        end
    end
    function tb._render(p, i, unit, list)
        local j = -mtb.select_stamp[i]
        for buff in list:iterator() do
            j = j + 1
            if j > 0 then
                if j > icons.ICON_MAX_COUNT then
                    j = j - 1
                    break;
                end

                local icon = icons.get_frame(j)
                if mtb.player == p then
                    if buff:is_visible() then
                        if not icon:visible() then
                            icon:show(true)
                            icon:activate(true)
                        end
                        icon:set_icon(buff.icon_path)
                        icon:set_name(buff.icon_name)
                        icon:set_desc(buff.icon_desc)
                    else
                        if icon:visible() then
                            icon:show(false)
                            icon:activate(false)
                        end
                        icon:set_icon(nil)
                        icon:set_name(nil)
                        icon:set_desc(nil)
                    end
                end
            end
        end
        local str = tostring(j + mtb.select_stamp[i]) .. "/" .. tostring(#list)
        if mtb.player == p then
            BlzFrameSetText(selection.disp_frame, str)
        end
        j = j + 1
        tb._unrender(p, i, j)
    end
    
    Initializer("SYSTEM", function()
        mtb.player      = GetLocalPlayer()
        mtb.player_id   = GetPlayerId(mtb.player)

        local ptb       = {}
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local p     = Player(i)
            if GetPlayerController(p) == MAP_CONTROL_USER then
                ptb[#ptb + 1]       = p
                mtb.select_stamp[i] = 0
            end
        end

        local g         = CreateGroup()
        local timer     = CreateTimer()
        TimerStart(timer, tb._INTERVAL, true, function()
            for j = 1, #ptb do
                local p = ptb[j]
                local i = GetPlayerId(p)

                GroupEnumUnitsSelected(g, p, nil)
                local unit  = FirstOfGroup(g)
                local list  = system.get_list(unit)
                if mtb.select_unit[i] ~= unit then
                    mtb.select_stamp[i] = 0
                    mtb.select_unit[i]  = unit
                end
                if list then
                    tb._render(p, i, unit, list)
                else
                    tb._unrender(p, i, 1)
                    if mtb.player == p then
                        BlzFrameSetText(selection.disp_frame, "0/0")
                    end
                end
            end
        end)

        local trig  = CreateTrigger()
        BlzTriggerRegisterFrameEvent(trig, selection.top_button, FRAMEEVENT_CONTROL_CLICK)
        BlzTriggerRegisterFrameEvent(trig, selection.bot_button, FRAMEEVENT_CONTROL_CLICK)
        TriggerAddCondition(trig, Condition(function()
            local p         = GetTriggerPlayer()
            local i         = GetPlayerId(p)
            local button    = BlzGetTriggerFrame()

            if mtb.player == p then
                BlzFrameSetEnable(button, false)
                BlzFrameSetEnable(button, true)
                BlzFrameSetFocus(button, false)
            end
            GroupEnumUnitsSelected(g, p, nil)
            local unit  = FirstOfGroup(g)
            local list  = system.get_list(unit)
            if mtb.select_unit[i] ~= unit then
                mtb.select_stamp[i] = 0
                mtb.select_unit[i]  = unit
                return
            end
            if not list then
                mtb.select_stamp[i] = 0
                return
            end
            if #list <= icons.ICON_MAX_COUNT then return;
            end
            if button == selection.top_button then
                mtb.select_stamp[i] = mtb.select_stamp[i] + icons.ICON_MAX_COUNT
                if mtb.select_stamp[i] > #list then
                    mtb.select_stamp[i] = 0
                end
            else
                mtb.select_stamp[i] = mtb.select_stamp[i] - icons.ICON_MAX_COUNT
                if mtb.select_stamp[i] < 0 then
                    mtb.select_stamp[i] = math.floor(#list/icons.ICON_MAX_COUNT)*icons.ICON_MAX_COUNT
                end
            end
            event.deactivate_buff(p, event.get_primary_index(p))
            tb._render(p, i, unit, list)
        end))
    end)
end