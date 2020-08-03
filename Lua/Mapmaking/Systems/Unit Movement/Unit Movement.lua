do
    local tb        = AllocTable(100)
    local temp      = {}
    local data      = {}
    local list      = {}
    tb.DEF_PRIORITY = 2
    tb.INTERVAL     = Missile.INTERVAL
    tb.GRADIENT     = Missile.GRADIENT
    tb._NORMAL      = Vector2D.ORIGIN
    tb._FLY_ABIL    = FourCC("Amrf")

    UnitMovement    = setmetatable({}, tb)
    tb._moving      = TimerIterator:create(tb.INTERVAL, function(self)
        if rawget(self, 'on_update') then
            temp.vect, temp.dz  = self.on_update(self)
        else
            temp.vect, temp.dz  = tb._NORMAL, 0
        end

        if not self.unit then return;
        elseif not self.running then return;
        end

        local tx, ty, h     = self:get_x(), self:get_y(), self:get_height()
        local flag          = true
        tx, ty, h           = tx + temp.vect.x, ty + temp.vect.y, h + temp.dz
        if self.checkpathing then
            if not IsUnitType(self.unit, UNIT_TYPE_FLYING) then
                flag, tx, ty   = IsTerrainWalkable(tx, ty)
            end
        end
        if flag then
            self:set_x(tx)
            self:set_y(ty)
        end
        self:set_height(h)
    end)

    function tb:get_x()
        return GetUnitX(self.unit)
    end
    function tb:get_y()
        return GetUnitY(self.unit)
    end
    function tb:get_height()
        return GetUnitFlyHeight(self.unit)
    end
    function tb:set_data(value)
        data[self]  = value
    end
    function tb:set_x(val)
        val = val or 0
        SetUnitX(self.unit, val)
    end
    function tb:set_y(val)
        val = val or 0
        SetUnitY(self.unit, val)
    end
    function tb:set_height(val)
        val = val or GetUnitDefaultFlyHeight(self.unit)
        if UnitAddAbility(self.unit, tb._FLY_ABIL) then
            UnitRemoveAbility(self.unit, tb._FLY_ABIL)
        end
        SetUnitFlyHeight(self.unit, val, 0)
    end
    function tb:get_data()
        return data[self]
    end

    function tb:show(flag)
        ShowUnit(self.unit, flag)
    end
    function tb:visible()
        return not IsUnitHidden(self.unit)
    end

    function tb:__constructor(unit, priority)
        self.unit           = unit
        self.running        = false
        self.checkpathing   = true
        self.priority       = priority or tb.DEF_PRIORITY
        if not list[unit] then
            list[unit]      = SimpleList()
        end
        list[unit]:insert(self)
    end
    function tb:__destructor()
        if rawget(self, 'running') == nil then return;
        end

        self:stop()
        self.running        = nil
        if rawget(self, 'on_destroy') then
            local func      = self.on_destroy
            rawset(self, 'on_destroy', nil)
            func(self)
        end
        rawset(self, 'on_stop', nil)
        rawset(self, 'on_launch', nil)
        rawset(self, 'on_update', nil)

        local unit          = self.unit
        data[self]          = nil
        self.unit           = nil
        self.checkpathing   = nil
        self.priority       = nil
        list[unit]:remove(self)
    end

    --  Generic launch and stop methods
    function tb:is_moving()
        return self.running
    end
    function tb:launch(cx, cy, h)
        if self.running then return;
        end

        self.running    = true
        tb._moving:insert(self)
        if rawget(self, 'on_launch') then
            self.on_launch(self, cx, cy, h)
        end
        if cx then
            self:set_x(cx)
        end
        if cy then
            self:set_y(cy)
        end
        if h then
            self:set_height(h)
        end
    end
    function tb:stop(interrupted)
        if not self.running then return;
        end

        self.running    = false
        tb._moving:remove(self)
        if rawget(self, 'on_stop') then
            self.on_stop(self, interrupted)
        end
    end

    --  Configurable callback functions.
    function tb:config_launch(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_launch', func)
    end
    function tb:config_move(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_update', func)
    end
    function tb:config_destroy(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_destroy', func)
    end
    function tb:config_stop(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_stop', func)
    end

    --  Interruption destroys instances.
    function tb.interrupt(unit, prio)
        if not list[unit] then return;
        end

        prio = prio or tb.DEF_PRIORITY
        for self in list[unit]:iterator() do
            if self.priority <= prio then
                self:stop(true)
                self:destroy()
            end
        end
    end

    UnitDex.register("LEAVE_EVENT", function(unit)
        if not list[unit] then return;
        end
        for self in list[unit]:iterator() do
            self:destroy()
        end
        list[unit]:destroy()
        list[unit]  = nil
    end)
end