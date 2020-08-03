do
    local tb        = protected_table()
    local btb       = {stack={}}
    BuffWatcher     = setmetatable({}, tb)

    tb._u_buff_list = btb    -- This contains the list of instances of registered buffs per unit.
    tb._TICKS       = 10    -- This is on a per-second basis
    tb.INTERVAL     = 1/tb._TICKS

    local function is_unit(whichunit)
        return tostring(whichunit):sub(1, 5) == "unit:"
    end
    local function is_num(buffid)
        return type(buffid) == 'number'
    end
    local function restore_table(t)
        btb.stack[#btb.stack + 1]   = t
    end
    local function request_table()
        if btb.stack[#btb.stack] then
            local t                 = btb.stack[#btb.stack]
            btb.stack[#btb.stack]   = nil
            return t
        end
        return {}
    end
    local function restore_instance(self)
        local mt        = tb.__metatable
        tb.__metatable  = nil
        setmetatable(self, nil)
        tb.__metatable  = mt
        restore_table(self)
    end
    local function internal_dest(self)
        if self.dest_flag or (self.dest_flag == nil) then return;
        end

        self.dest_flag  = true
        if rawget(self, 'check_func') then
            self.check_func = nil
        end
        if rawget(self, 'dest_func') then
            local func      = self.dest_func
            self.dest_func  = nil
            pcall(func, self.unit, self.buff)
        end
        tb._LIST:remove(self)
        btb[self.unit].list:remove(btb[self.unit][self.buff])
        btb[self.unit][self.buff] = nil
        self.unit       = nil
        self.buff       = nil
        self.dest_flag  = nil
        
        restore_instance(self)
    end
    function tb._remove_info(whichunit)
        if btb[whichunit] then
            btb[whichunit].list:destroy()
            restore_table(btb[whichunit])
            btb[whichunit].list = nil
            btb[whichunit]      = nil
        end
    end
    function tb._add_info(whichunit)
        if not btb[whichunit] then
            btb[whichunit]  = request_table()
            btb[whichunit].list = LinkedList()
        end
    end

    tb._LIST    = TimerIterator:create(tb._TICKS, function(self)
        if GetUnitAbilityLevel(self.unit, self.buff) == 0 then
            internal_dest(self)
            return
        end
        if rawget(self, 'check_func') then
            self.check_func(self.unit, self.buff)
        end
    end)
    function tb._create(whichunit, buffid)
        local o     = request_table()
        o.unit      = whichunit
        o.buff      = buffid
        o.dest_flag = false
        setmetatable(o, tb)
        return o
    end
    function tb:_destroy()
        internal_dest(self)
    end

    function tb:check()
        if GetUnitAbilityLevel(self.unit, self.buff) == 0 then
            internal_dest(self)
        end
    end
    function tb.watch(whichunit, buffid)
        --  Check parameters
        if (not is_unit(whichunit)) or (not is_num(buffid)) then return;
        end
        if btb[whichunit] and btb[whichunit][buffid] then
            return btb[whichunit][buffid].data
        end
        --  Create a table for unit
        tb._add_info(whichunit)
        local list      = btb[whichunit]
        local self      = tb._create(whichunit, buffid)
        list[buffid]    = select(2, list.list:insert(self))

        tb._LIST:insert(self)
        return self
    end
    function tb:on_buff_check(func)
        if not is_function(func) then return;
        end
        rawset(self, 'check_func', func)
    end
    function tb:on_buff_remove(func)
        if not is_function(func) then return;
        end
        rawset(self, 'dest_func', func)
    end
end