do
    local tb            = protected_table()
    local mtb           = {}
    local co            = {pointer={}}
    MissileInterface    = setmetatable({}, tb)

    local function request_table()
        if co[#co] then
            local t         = co[#co]
            co[#co]         = nil
            co.pointer[t]   = nil
            return t
        end
        return {}
    end
    local function restore_table(t)
        if co.pointer[t] then return;
        end
        co[#co + 1]     = t
        co.pointer[t]   = #co
    end

    function tb.is_missile_type(o)
        return mtb[o]
    end

    --  Helper functions
    function tb:config_launch(func)
        self.missile:config_launch(func)
    end
    function tb:config_stop(func)
        self.missile:config_stop(func)
    end
    function tb:config_move(func)
        self.missile:config_move(func)
    end
    function tb:config_destroy(func)
        self.missile:config_destroy(func)
    end
    function tb:show(flag)
        self.missile:show(flag)
    end
    function tb:launch(...)
        self.missile:launch(...)
    end
    function tb:stop()
        self.missile:stop()
    end

    function tb:visible()
        return self.missile:visible()
    end
    function tb:is_moving()
        return self.missile:is_moving()
    end
    function tb.apply_turn_rate(theta, facing, turn_rate)
        if turn_rate <= 0 then return theta;
        end
        
        local mag   = math.abs(facing - theta)
        if (mag < turn_rate) then return theta;
        elseif (mag >= 2*math.pi - turn_rate) then return theta;
        end

        if mag > math.pi then
            if facing < theta then
                theta = facing - turn_rate
            else
                theta = facing + turn_rate
            end
        else
            if facing < theta then
                theta = facing + turn_rate
            else
                theta = facing - turn_rate
            end
        end
        if theta < -math.pi then
            theta   = theta + 2*math.pi
        elseif theta > math.pi then
            theta   = theta - 2*math.pi
        end
        return theta
    end

    function tb:__constructor(path, cx, cy)
        self.missile  = Missile(path, cx, cy)
        self.facing   = 0.00
        self.col_size = 0.00
    end
    function tb:__destructor(path, cx, cy)
        self.col_size   = nil
        self.facing     = nil
        self.missile    = nil
    end
    function tb:__call(o, const, dest)
        o               = o or protected_table()
        mtb[o]          = true

        if const then
            o.__constructor = const
        end
        if dest then
            o.__destructor  = dest
        end

        o.__call        = function(t, path, cx, cy, ...)
            local oo    = request_table()

            tb.__constructor(oo, path, cx, cy)
            if o.__constructor then
                o.__constructor(oo, ...)
            end
            setmetatable(oo, o)
            return oo
        end
        o.destroy       = function(self)
            if co.pointer[self] then return;
            end

            local mt        = o.__metatable
            o.__metatable   = nil
            setmetatable(self, nil)
            o.__metatable   = mt

            if o.__destructor then
                o.__destructor(self)
            end
            self.missile:destroy()
            tb.__destructor(self)
            restore_table(self)
        end
        o.switch        = function(self, other, ...)
            if not mtb[other] then
                other   = getmetatable(other)
            end
            if not mtb[other] then return;
            elseif not self.missile then return;
            end

            local mt        = o.__metatable
            o.__metatable   = nil
            setmetatable(self, nil)
            o.__metatable   = mt
            if o.__destructor then
                o.__destructor(self)
            end

            if other.__constructor then
                other.__constructor(self, ...)
            end
            setmetatable(self, other)
        end

        o.config_launch     = tb.config_launch
        o.config_stop       = tb.config_stop
        o.config_move       = tb.config_move
        o.config_destroy    = tb.config_destroy

        o.show              = tb.show
        o.visible           = tb.visible
        o.launch            = tb.launch
        o.stop              = tb.stop
        o.is_moving         = tb.is_moving
        o.apply_turn_rate   = tb.apply_turn_rate
        return o
    end
end