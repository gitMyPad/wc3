do
    local tb        = AllocTable(10)
    local mtb       = {}
    local list      = {}
    local stun      = {
        ABIL_ID     = FourCC("uKup"),
        BUFF_ID     = FourCC("BKup"),
        ORDER       = "creepthunderbolt",
    }
    tb._DEBUG       = false
    tb.DEF_PRIORITY = UnitMovement.DEF_PRIORITY + 2
    Knockback       = setmetatable({}, tb)

    Initializer("SYSTEM", function()
        local dummy = DummyUtils.request()
        UnitAddAbility(dummy, stun.ABIL_ID)
        BlzUnitDisableAbility(dummy, FourCC("Amov"), true, true)
        tb.DUMMY    = dummy
    end)

    function tb._apply_knockup(unit, dostun)
        if not dostun then return;
        end
        if not stun[unit] then
            stun[unit]  = 0
        end
        SetUnitX(tb.DUMMY, GetUnitX(unit))
        SetUnitY(tb.DUMMY, GetUnitY(unit))
        IssueTargetOrder(tb.DUMMY, stun.ORDER, unit)
        stun[unit]      = stun[unit] + 1
    end
    function tb._remove_knockup(unit)
        if not stun[unit] then return;
        end
        stun[unit]      = stun[unit] - 1
        if stun[unit] <= 0 then
            UnitRemoveAbility(unit, stun.BUFF_ID)
        end
    end
    function tb:__constructor(unit, duration, dostun)
        self.movement       = UnitMovement(unit, tb.DEF_PRIORITY)
        self.vel_xy         = 0.
        self.vel_z          = 0.
        self.stunflag       = (dostun == true)
        mtb[self.movement]  = self

        self.movement:config_move(tb._on_knockback)
        self.movement:config_destroy(tb._on_destroy)
        tb.set_duration(self, duration or 0)
        if not list[unit] then
            list[unit]  = SimpleList()
        end
        tb._apply_knockup(unit, dostun)
        list[unit]:insert(self)
    end
    function tb:__destructor()
        list[self.movement.unit]:remove(self)
        if self.stunflag then
            tb._remove_knockup(self.movement.unit)
        end
        mtb[self.movement]  = nil
        self.vel_xy         = nil
        self.vel_z          = nil
        self.duration       = nil
        self.theta          = nil
        self.stunflag       = nil
    end

    function tb:config_move(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_update', func)
    end
    function tb:config_stop(func)
        if not is_function(func) then return;
        end
        rawset(self, 'on_stop', func)
    end
    function tb:config_launch(func)
        self.movement:config_launch(func)
    end
    function tb:config_destroy(func)
        self.movement:config_destroy(func)
    end

    function tb:set_velocity(speed, z_speed)
        speed       = speed or 0
        z_speed     = z_speed or 0
        self.vel_xy = speed*UnitMovement.GRADIENT
        self.vel_z  = z_speed*UnitMovement.GRADIENT
        if rawget(self, 'duration') then
            self.dxy    = -2*self.vel_xy/self.duration
            self.dz     = -2*self.vel_z/self.duration
        end
    end
    function tb:set_theta(value)
        rawset(self, 'theta', value)
    end
    function tb:set_duration(value)
        value   = value or UnitMovement.GRADIENT
        value   = math.max(math.floor(value*UnitMovement.INTERVAL + 0.5), 1)
        rawset(self, 'duration', value)

        self.dxy    = -2*self.vel_xy/self.duration
        self.dz     = -2*self.vel_z/self.duration
    end
    function tb:get_theta()
        return rawget(self, 'theta') or 0
    end
    function tb:get_velocity()
        return self.vel_xy*UnitMovement.INTERVAL, self.vel_z*UnitMovement.INTERVAL
    end
    function tb:get_duration()
        local dur   = rawget(self, 'duration') or 0
        dur         = dur*UnitMovement.GRADIENT
        return dur
    end

    function tb:launch()
        if self.duration <= 0 then return;
        elseif not rawget(self, 'theta') then return;
        end
        self.movement:config_move(tb._on_knockback)
        self.movement:config_stop(tb._on_knockback_stop)
        self.movement:config_destroy(tb._on_destroy)
        UnitMovement.interrupt(self.movement.unit)
        self.movement:launch()
    end

    function tb:get_data()
        return self.movement:get_data()
    end
    function tb:set_data(value)
        self.movement:set_data(value)
    end

    function tb._on_knockback(movement)
        local self  = mtb[movement]
        local flag  = true
        if rawget(self, 'on_update') then
            flag = pcall(self.on_update, self)
        end
        if not flag and tb._DEBUG then
            print("Knockback.on_update >> Instance failed to terminate!")
            print("Knockback.on_update >> Instance:", self)
            PauseGame(true)
            return
        end
        local dx, dy    = self.vel_xy*math.cos(self.theta), self.vel_xy*math.sin(self.theta)
        local dz        = self.vel_z
        self.vel_xy     = self.vel_xy + self.dxy
        self.vel_z      = self.vel_z + self.dz

        self.duration   = self.duration - 1
        if self.duration <= 0 then
            if #list[movement.unit] == 1 then
                dz  = GetUnitDefaultFlyHeight(movement.unit) - movement:get_height()
            end
            movement:set_height(movement:get_height() + dz)
            movement:stop()
            return Vector2D.ORIGIN, 0
        end
        return Vector2D(dx, dy), dz
    end
    function tb._on_destroy(movement)
        local self  = mtb[movement]
        self:destroy()
    end
    function tb._on_knockback_stop(movement)
        local self  = mtb[movement]
        local flag  = true
        if rawget(self, 'on_stop') then
            flag = pcall(self.on_stop, self)
        end
        if not flag and tb._DEBUG then
            print("Knockback.on_stop >> Instance failed to terminate")
        end
        movement:destroy()
    end
    UnitDex.register("LEAVE_EVENT", function(unit)
        if stun[unit] then
            stun[unit]  = nil
        end
        if not list[unit] then return;
        end
        list[unit]:destroy()
        list[unit]  = nil
    end)
end