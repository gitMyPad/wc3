--[[
    This system was inspired by Spellbound's Socket System,
    and was written from scratch.
]]
do
    local ftb       = {stack={}}
    local tb        = protected_table({
        cur_event           = {},
        cur_unit            = {},
        cur_socket          = {},
        cur_socket_instance = {},
        cur_socketer        = {},
        _cur_context        = {},

        DEF_RANGE           = 300,
        DEF_SOCKETS         = 2,
        _CROW_ABIL          = FourCC("Amrf"),
    })
    local plug      = {}
    local socket    = {}
    local info      = {socket={}, pos={}, trig_pointer={}}
    SocketSystem    = setmetatable({}, tb)

    tb._events      = {
        ENTER_EVENT     = 1,
        ON_SOCKET_EVENT = 2,
        LEAVE_EVENT     = 3,
    }
    tb._plug        = plug
    tb._socket      = socket
    tb._handler     = PriorityEvent:create()
    tb._handler:preload_registry(tb._events.ENTER_EVENT, tb._events.LEAVE_EVENT)

    function ftb.is_unit(whichunit)
        if pcall(GetUnitTypeId, whichunit) then return true;
        end
        return false
    end
    function ftb.restore_table(t)
        ftb.stack[#ftb.stack + 1]   = t
    end
    function ftb.request_table()
        if not ftb.stack[#ftb.stack] then
            return {}
        end
        local t = ftb.stack[#ftb.stack]
        ftb.stack[#ftb.stack]   = nil
        return t
    end
    function ftb.throw_event(eventtype, observer, occupant, pos, socket)
        local index = #tb.cur_event + 1

        tb.cur_event[index]             = eventtype
        tb.cur_unit[index]              = occupant
        tb.cur_socketer[index]          = observer
        tb.cur_socket[index]            = pos
        tb.cur_socket_instance[index]   = socket
        tb._cur_context[index]          = 0

        tb._handler:fire(tb._events[eventtype], observer, occupant, pos, socket)

        local result    = tb._cur_context[index]
        tb.cur_event[index]             = nil
        tb.cur_unit[index]              = nil
        tb.cur_socketer[index]          = nil
        tb.cur_socket[index]            = nil
        tb.cur_socket_instance[index]   = nil
        tb._cur_context[index]          = nil
        return result
    end
    function ftb.set_occupant_pos(occupant, x, y, z, checkpathing)
        if UnitAddAbility(occupant, tb._CROW_ABIL) then
            UnitRemoveAbility(occupant, tb._CROW_ABIL)
        end
        if checkpathing then
            SetUnitPosition(occupant, x, y)
        else
            SetUnitX(occupant, x)
            SetUnitY(occupant, y)
        end
        SetUnitFlyHeight(occupant, z, 0)
    end
    function ftb.add_plug_info(whichunit)
        if not plug[whichunit] then
            plug[whichunit] = ftb.request_table()
            plug[whichunit].list        = LinkedList()
            plug[whichunit].unit_map    = ftb.request_table()
            plug[whichunit].pointer     = ftb.request_table()
        end
    end
    function ftb.remove_plug_info(whichunit)
        if plug[whichunit] then
            plug[whichunit].list:destroy()
            ftb.restore_table(plug[whichunit].pointer)
            ftb.restore_table(plug[whichunit].unit_map)
            ftb.restore_table(plug[whichunit])

            plug[whichunit].unit_map    = nil
            plug[whichunit].pointer     = nil
            plug[whichunit].list        = nil
            plug[whichunit]             = nil
        end
    end
    function ftb.clear_plug_info(whichunit)
        while #plug[whichunit].list > 0 do
            local self  = plug[whichunit].list:first()
            self:destroy()
        end
    end
    function ftb.add_instance(observer, self)
        local p = plug[observer]
        p.pointer[self] = select(2, p.list:insert(self))
    end
    function ftb.remove_instance(observer, self)
        local p = plug[observer]
        p.list:remove(p.pointer[self])
        p.pointer[self] = nil
    end
    function ftb.restore_instance(self)
        local mt        = tb.__metatable
        tb.__metatable  = nil
        setmetatable(self, nil)
        tb.__metatable  = mt
        ftb.restore_table(self)
    end
    function ftb.clear_list(self)
        for pos, pointer in self.socket.free:iterator() do
            self.socket.pointer[pos]    = nil
            self.socket.free:remove(pointer)
        end
        self.socket.used:destroy()
        self.socket.free:destroy()
        ftb.restore_table(self.socket.pointer)
    end

    --  Callback function encased in a filter
    Initializer("SYSTEM", function()
        ftb.detector_callback   = Filter(function()
            local self      = info.trig_pointer[GetTriggeringTrigger()]
            local occupant  = GetTriggerUnit()

            if occupant == self.observer then return;
            elseif #self.socket.free == 0 then return;
            elseif socket[occupant] then return;
            end

            local pos       = self:get_nearest_socket(GetUnitX(occupant), GetUnitY(occupant))
            local context   = ftb.throw_event("ENTER_EVENT", self.observer, occupant, pos, self)
            local enterID   = GetUnitTypeId(occupant)
            if not UnitAlive(self.observer) then
                context = context - 1
            end
            if not self.unit_map:is_elem_in(enterID) then
                context = context - 1
            end
            if context < 0 then return;
            end
            ftb.add_unit(self, occupant, pos)
        end)
    end)

    --  Socket occupancy functions
    function ftb.add_unit(self, occupant, pos)
        --  Some assumptions are made here, such as
        --  the socket being free, the occupant not
        --  being socketed yet.
        self.socket.free:remove(self.socket.pointer[pos])
        self.socket.pointer[pos]    = select(2, self.socket.used:insert(pos))
        self.socket[pos].occupant   = occupant
        
        socket[occupant]            = self.observer
        info.socket[occupant]       = self
        info.pos[occupant]          = pos

        local tx, ty, tz            = self:get_socket_pos(pos)
        ftb.set_occupant_pos(occupant, tx, ty, tz)
        ftb.throw_event("ON_SOCKET_EVENT", self.observer, occupant, pos, self)
    end
    function ftb.remove_unit(self, occupant, ignorecontext)
        --  Some assumptions are made here, such as
        --  the socket being used, the occupant being
        --  socketed to the same instance.
        local pos           = info.pos[occupant]
        local tx, ty, tz    = self:get_socket_pos(pos)
        ftb.set_occupant_pos(occupant, tx, ty, GetUnitDefaultFlyHeight(occupant), true)

        local context       = ftb.throw_event("LEAVE_EVENT", self.observer, occupant, pos, self)
        if not UnitAlive(self.observer) then
            context = context + 1
        end
        if (context < 0) and (not ignorecontext) then
            ftb.set_occupant_pos(occupant, tx, ty, tz)
            return
        end

        self.socket.used:remove(self.socket.pointer[pos])
        self.socket.pointer[pos]    = select(2, self.socket.free:insert(pos))
        self.socket[pos].occupant   = occupant

        socket[occupant]            = nil
        info.socket[occupant]       = nil
        info.pos[occupant]          = nil
    end

    --  Socket instance-related functions
    function tb:get_socket_pos(pos)
        local tx, ty, tz    = self.socket[pos].x, self.socket[pos].y, self.socket[pos].z
        if not self.socket[pos].abs then
            tx, ty          = tx + GetUnitX(self.observer), ty + GetUnitY(self.observer)
        end
        return tx, ty, tz
    end
    function tb:set_socket_pos(pos, x, y, z, abs)
        self.socket[pos].x    = x or 0
        self.socket[pos].y    = y or 0
        self.socket[pos].z    = z or 0
        self.socket[pos].abs  = abs

        if self.socket[pos].occupant then
            local tx, ty, tz    = self:get_socket_pos(pos)
            ftb.set_occupant_pos(self.socket[pos].occupant, tx, ty, tz)
        end
    end
    function tb:get_nearest_socket(cx, cy)
        local pos   = 0
        local min   = 99999999.0
        --  Do not iterate if there's no more space.
        if #self.socket.free == 0 then
            return pos
        end
        for index in self.socket.free:iterator() do
            local tx, ty    = self:get_socket_pos(index)
            local dist      = (tx-cx)*(tx-cx) + (ty-cy)*(ty-cy)
            if min >= dist then
                min = dist
                pos = index
            end
        end
        return pos
    end

    --  Plug-related functions
    function tb._new(whichunit, range, num)
        local self      = ftb.request_table()
        self.observer   = whichunit
        self.range      = range
        self.count      = num
        self.socket     = ftb.request_table()
        self.unit_map   = LinkedList()
        self.detector   = 0

        self.socket.pointer = ftb.request_table()
        self.socket.free    = LinkedList()
        self.socket.used    = LinkedList()
        for i = 1, num do
            self.socket.pointer[i]  = select(2, self.socket.free:insert(i))
            self.socket[i]          = ftb.request_table()

            self.socket[i].x        = 0
            self.socket[i].y        = 0
            self.socket[i].z        = 0
            self.socket[i].abs      = false
        end
        setmetatable(self, tb)
        return self
    end
    function tb:destroy(ignorecontext)
        DestroyTrigger(self.detector)

        self:clear_unittype()
        self:clear_occupants(ignorecontext)
        --  Restore tables
        for i = 1, self.count do
            self.socket[i].x        = nil
            self.socket[i].y        = nil
            self.socket[i].z        = nil
            self.socket[i].abs      = nil

            ftb.restore_table(self.socket[i])
            self.socket[i]          = nil
        end

        ftb.clear_list(self)
        self.socket.free    = nil
        self.socket.used    = nil
        self.socket.pointer = nil
        ftb.restore_table(self.socket)

        self.unit_map:destroy()
        ftb.remove_instance(self.observer, self)

        self.unit_map       = nil
        self.count          = nil
        self.detector       = nil
        self.range          = nil
        self.observer       = nil
        ftb.restore_instance(self)
    end

    --  Event-handler related functions
    function tb.allow_socket()
        if tb.cur_event[#tb.cur_event] == "ENTER_EVENT" then
            tb._cur_context[#tb._cur_context] = tb._cur_context[#tb._cur_context] + 1
        elseif tb.cur_event[#tb.cur_event] == "LEAVE_EVENT" then
            tb._cur_context[#tb._cur_context] = tb._cur_context[#tb._cur_context] - 1
        end
    end
    function tb.prevent_socket()
        if tb.cur_event[#tb.cur_event] == "LEAVE_EVENT" then
            tb._cur_context[#tb._cur_context] = tb._cur_context[#tb._cur_context] + 1
        elseif tb.cur_event[#tb.cur_event] == "ENTER_EVENT" then
            tb._cur_context[#tb._cur_context] = tb._cur_context[#tb._cur_context] - 1
        end
    end
    function tb.will_socket()
        if tb.cur_event[#tb.cur_event] == "ENTER_EVENT" then
            return tb._cur_context[#tb._cur_context] >= 0
        elseif tb.cur_event[#tb.cur_event] == "LEAVE_EVENT" then
            return tb._cur_context[#tb._cur_context] < 0
        end
        return true
    end
    function tb.is_unit_plugged(whichunit)
        return socket[whichunit] ~= nil
    end
    function tb.get_plug(whichunit)
        return socket[whichunit]
    end
    function tb.get_plug_instance(whichunit)
        return info.socket[whichunit]
    end
    function tb:in_socket(whichunit)
        return info.socket[whichunit] == self
    end

    --  Sandboxed functions.
    function tb:add_unit(occupant, pos)
        --  Verify if occupant is a unit
        if not ftb.is_unit(occupant) then return;
        elseif not occupant then return;
        elseif (socket[occupant] ~= nil) then return;
        end

        --  Verify if the position is vacant
        pos     = pos or self:get_nearest_socket(GetUnitX(occupant), GetUnitY(occupant))
        if pos == 0 then return;
        elseif self.socket.used:is_elem_in(pos) then return;
        end

        --  Proceed with inclusion
        ftb.add_unit(self, occupant, pos)
    end
    function tb:remove_unit(occupant)
        --  Verify if occupant is a unit
        if not ftb.is_unit(occupant) then return;
        elseif not occupant then return;
        end
        --  Verify if the socket occupant belongs
        --  to this instance. 
        if info.socket[occupant] ~= self then return;
        end
        --  Proceed with removal
        ftb.remove_unit(self, occupant)
    end

    function tb:add_unittype(unitid)
        local observer  = self.observer

        --  Check if the unitid is already added to another list
        if plug[observer].unit_map[unitid] then return;
        end
        plug[observer].unit_map[unitid] = select(2, self.unit_map:insert(unitid))
    end
    function tb:remove_unittype(unitid)
        local observer  = self.observer

        --  Check if the unitid is in this list
        if not plug[observer].unit_map[unitid] then return;
        elseif not self.unit_map:is_node_in(plug[observer].unit_map[unitid]) then return;
        end

        self.unit_map:remove(plug[observer].unit_map[unitid])
        plug[observer].unit_map[unitid] = nil
    end
    function tb:clear_unittype()
        while #self.unit_map > 0 do
            self:remove_unittype(self.unit_map:first())
        end
    end
    function tb:clear_occupants(ignorecontext)
        while #self.socket.used > 0 do
            local pos   = self.socket.used:first()
            ftb.remove_unit(self, self.socket[pos].occupant, ignorecontext)
        end
    end

    function tb:_init_detector()
        if type(self.detector) ~= 'number' then
            info.trig_pointer[self.detector]    = nil
            DestroyTrigger(self.detector)
        end
        self.detector   = CreateTrigger()
        info.trig_pointer[self.detector]    = self
        TriggerRegisterUnitInRange(self.detector, self.observer, self.range, nil)
        TriggerAddCondition(self.detector, ftb.detector_callback)
    end
    function tb.register_unit(whichunit, range, num)
        if not ftb.is_unit(whichunit) then return;
        elseif not whichunit then return;
        end

        --  Apply safe values for range and num
        range       = range or tb.DEF_RANGE
        num         = num or tb.DEF_SOCKETS
        num         = math.max(1, num)

        --  Initialize instance, and detector
        local self  = tb._new(whichunit, range, num)
        tb._init_detector(self)

        --  Add the instance to the list of plugs the unit has
        ftb.add_plug_info(whichunit)
        ftb.add_instance(whichunit, self)
        return self
    end
    function tb.register_function(eventtype, func)
        if tb._events[eventtype] then
            tb._handler:register(tb._events[eventtype], func)
        end
    end

    UnitDex.register("LEAVE_EVENT", function(unit)
        if socket[unit] then
            local self  = info.socket[unit]
            ftb.remove_unit(self, unit, true)
        end
        if plug[unit] then
            --  Iterate through a whole list of instances
            ftb.clear_plug_info(unit)
            ftb.remove_plug_info(unit)
        end
    end)
    UnitState.register("DEATH_EVENT", function(unit)
        if socket[unit] then
            local self  = info.socket[unit]
            ftb.remove_unit(self, unit)
        end
        if plug[unit] then
            --  Iterate through a whole list of instances
            for self in plug[unit].list:iterator() do
                self:clear_occupants()
            end
        end
    end)
    tb.throw_event  = ftb.throw_event
end