do
    --[[
        IsUnitMoving    -> based on Bribe's GUI IsUnitMoving
    ]]
    local tb        = protected_table()
    tb._INTERVAL    = 1/32
    tb._MIN_DIST    = 1
    tb._handler     = EventListener:create()
    tb._moving      = {cx = {}, cy = {}}
    tb._list        = SimpleList()
    Initializer("SYSTEM", function()
        tb._timer       = CreateTimer()
        tb._MIN_DIST    = tb._MIN_DIST*tb._MIN_DIST*tb._INTERVAL*tb._INTERVAL
    end)
    MovementEvent   = setmetatable({}, tb)

    function tb._check_pos(unit)
        local cx, cy    = GetUnitX(unit), GetUnitY(unit)
        local tx, ty    = tb._moving.cx[unit], tb._moving.cy[unit]
        local dist      = (tx-cx)*(tx-cx) + (ty-cy)*(ty-cy)
        local flag      = dist >= tb._MIN_DIST
        if flag then
            tb._moving.cx[unit] = GetUnitX(unit)
            tb._moving.cy[unit] = GetUnitY(unit)
        end
        if tb._moving[unit] ~= flag then
            tb._moving[unit]    = flag
            tb._handler:execute(unit, flag)
        end
    end
    function tb._check_movement()
        for unit in tb._list:iterator() do
            tb._check_pos(unit)
        end
    end

    function tb._reinstate_unit(unit)
        tb._moving[unit]    = false
        tb._moving.cx[unit] = GetUnitX(unit)
        tb._moving.cy[unit] = GetUnitY(unit)
        tb._list:insert(unit)
        if #tb._list == 1 then
            TimerStart(tb._timer, tb._INTERVAL, true, tb._check_movement)
        end
    end
    function tb._suspend_unit(unit)
        tb._moving[unit]    = nil
        tb._moving.cx[unit] = nil
        tb._moving.cy[unit] = nil

        tb._list:remove(unit)
        if #tb._list == 0 then
            PauseTimer(tb._timer)
        end
    end

    function tb.register(func)
        tb._handler:register(func)
    end
    function tb.deregister(func)
        tb._handler:deregister(func)
    end
    function IsUnitMoving(whichunit)
        return tb._moving[whichunit]
    end
    RegisterUnitMoveState   = tb.register
    DeregisterUnitMoveState = tb.deregister

    UnitDex.register("ENTER_EVENT", function()
        local unit  = UnitDex.eventUnit
        tb._reinstate_unit(unit)
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local unit  = UnitDex.eventUnit
        tb._suspend_unit(unit)
    end)
end