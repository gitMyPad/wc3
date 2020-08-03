do
    local tb        = protected_table()
    local show      = ShowUnit
    tb._monitor     = {lizard = SimpleList(), timer = CreateTimer(), INTERVAL = 0.25}
    tb._vis         = {}
    tb._handler     = EventListener:create()
    UnitVisibility  = setmetatable({}, tb)

    function tb.register(func)
        tb._handler:register(func)
    end
    function tb._check_visibility(whichunit)
        local visible   = not IsUnitHidden(whichunit)
        if (tb._vis[whichunit] == nil) or (tb._vis[whichunit] ~= visible) then
            tb._vis[whichunit] = visible
            tb._handler:execute(whichunit, visible)
        end
    end
    function ShowUnit(whichunit, flag)
        show(whichunit, flag)
        tb._check_visibility(whichunit)
    end

    function tb._monitor_visibility()
        for unit in tb._monitor.lizard:iterator() do
            tb._check_visibility(unit)
        end
    end
    function tb._monitor_unit(whichunit)
        tb._monitor.lizard:insert(whichunit)
        if #tb._monitor.lizard == 1 then
            TimerStart(tb._monitor.timer, tb._monitor.INTERVAL, true, tb._monitor_visibility)
        end
    end
    function tb._remove_unit(whichunit)
        tb._monitor.lizard:remove(whichunit)
        if #tb._monitor.lizard == 0 then
            PauseTimer(tb._monitor.timer)
        end
    end
    UnitDex.register("ENTER_EVENT", function()
        local unit  = UnitDex.eventUnit
        tb._monitor_unit(unit)
        tb._check_visibility(unit)
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local unit  = UnitDex.eventUnit
        tb._remove_unit(unit)
    end)
end