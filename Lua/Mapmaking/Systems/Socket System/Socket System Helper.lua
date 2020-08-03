do
    local tb        = getmetatable(SocketSystem)
    local mtb       = {stack = {}}
    local ftb       = {}
    local ignore    = {list=SimpleList()}
    local plug      = tb._plug
    local socket    = tb._socket

    ftb.register_unit   = tb.register_unit
    ftb.destroy         = tb.destroy

    Initializer("SYSTEM", function()
        ignore.timer    = CreateTimer()
        TimerStart(ignore.timer, 0.00, false, function()
            for unit in ignore.list:iterator() do
                ignore[unit]    = false
                ignore.list:remove(unit)
            end
        end)
        PauseTimer(ignore.timer)
    end)

    function mtb.restore(t)
        mtb.stack[#mtb.stack + 1] = t
    end
    function mtb.request()
        if mtb.stack[#mtb.stack] then
            local t = mtb.stack[#mtb.stack]
            mtb.stack[#mtb.stack]   = nil
            return t
        end
        return {}
    end
    function tb.register_unit(whichunit, range, num)
        local self  = ftb.register_unit(whichunit, range, num)
        mtb[self]   = mtb.request()
        return self
    end
    function tb:destroy()
        ftb.destroy(self)
        mtb.restore(mtb[self])
        mtb[self]   = nil
    end

    function tb:order_watched(whichorder)
        if #mtb[self] <= 0 then return false;
        end

        local flag  = false
        for i = 1, #mtb[self] do
            if mtb[self][i] == whichorder then
                flag    = true
                break
            end
        end
        return flag
    end
    function tb:watch_order(whichorder)
        if not self:order_watched(whichorder) then
            mtb[self][#mtb[self] + 1] = whichorder
        end
    end
    function tb:on_enter(func)
        if is_function(func) then
            mtb[self].enter_func    = func
        end
    end
    function tb:on_socket(func)
        if is_function(func) then
            mtb[self].socket_func   = func
        end
    end
    function tb:on_leave(func)
        if is_function(func) then
            mtb[self].leave_func    = func
        end
    end

    --  Check if the unit is being issued the appropriate order
    tb.register_function("ENTER_EVENT", function(observer, occupant, pos, self)
        if #mtb[self] > 0 then
            local orderInfo = OrderMatrix[occupant]
            if not self:order_watched(orderInfo.order[1]) then
                tb.prevent_socket()
            elseif orderInfo.target[1] ~= observer then
                tb.prevent_socket()
            end
        end
        if mtb[self].enter_func then
            mtb[self].enter_func(observer, occupant, pos, self)
        end
    end)
    tb.register_function("ON_SOCKET_EVENT", function(observer, occupant, pos, self)
        if mtb[self].socket_func then
            mtb[self].socket_func(observer, occupant, pos, self)
        end
    end)
    tb.register_function("LEAVE_EVENT", function(observer, occupant, pos, self)
        if #mtb[self] > 0 then
            local orderInfo = OrderMatrix[occupant]
            if not self:order_watched(orderInfo.order[1]) then
                tb.prevent_socket()
            elseif orderInfo.target[1] ~= observer then
                tb.prevent_socket()
            end
        end
        if mtb[self].leave_func then
            mtb[self].leave_func(observer, occupant, pos, self)
        end
    end)

    function ftb.unsocket(occupant)
        local self          = tb.get_plug_instance(occupant)
        local event, func   = EventListener.get_event(), EventListener.get_cur_function()

        if #mtb[self] <= 0 then return;
        end
        event:disable(func)
        tb.ignore_unit_orders(occupant)
        self:remove_unit(occupant)
        event:enable(func)
    end
    function ftb.on_order()
        local unit  = GetTriggerUnit()
        if not socket[unit] then return;
        elseif ignore[unit] then return;
        end
        ftb.unsocket(unit)
    end
    function tb.ignore_unit_orders(whichunit)
        ignore[whichunit]   = true
        ignore.list:insert(whichunit)
        ResumeTimer(ignore.timer)
    end

    local function check_func(self, order, unit, targ)
        if #mtb[self]== 0 then return;
        elseif not self:order_watched(order) then return;
        elseif not IsUnitInRange(unit, targ, self.range) then return;
        end

        local pos       = self:get_nearest_socket(GetUnitX(unit), GetUnitY(unit))
        if pos == 0 then return;
        end

        local context   = tb.throw_event("ENTER_EVENT", targ, unit, pos, self)
        local enterID   = GetUnitTypeId(unit)
        if not UnitAlive(targ) then
            context = context - 1
        end
        if not self.unit_map:is_elem_in(enterID) then
            context = context - 1
        end
        if self:in_socket(unit) then
            context = -1
        end
        if context < 0 then return;
        end
        self:add_unit(unit)
    end

    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, ftb.on_order)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, ftb.on_order)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function()
        local unit, targ    = GetTriggerUnit(), GetOrderTargetUnit()
        local order         = OrderId2String(GetIssuedOrderId())
        if not plug[targ] then return;
        end
        tb.ignore_unit_orders(unit)
        for self in plug[targ].list:iterator() do
            check_func(self, order, unit, targ)
        end
    end)
end