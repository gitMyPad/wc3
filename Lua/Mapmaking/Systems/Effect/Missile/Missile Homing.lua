do
    local tb        = MissileInterface()
    local grad      = Missile.GRADIENT
    local moving    = {}
    local otb       = {}
    local mtb       = {stopped={}}
    HomingMissile   = setmetatable({}, tb)

    function tb:__constructor(target, speed, turn)
        self.target         = target or 0
        self.speed          = speed or 0.
        self.turn_rate      = turn or -1.
        mtb[self.missile]   = self
    end
    function tb:__destructor()
        self.target         = nil
        self.speed          = nil
        self.turn_rate      = nil
        self.tx             = nil
        self.ty             = nil
        moving[self]        = nil
        mtb[self.missile]   = nil
    end

    --  Attribute getters and setters
    function tb:get_speed(cmd)
        if cmd == 'raw' then
            return self.speed
        end
        return self.speed/grad
    end
    function tb:set_speed(amt, cmd)
        amt = amt or 0
        if cmd == 'raw' then
            self.speed  = amt
        else
            self.speed  = amt*grad
        end
    end
    function tb:get_turn_rate(cmd)
        if cmd == 'raw' then
            return self.turn_rate
        end
        return self.turn_rate/grad
    end
    function tb:set_turn_rate(amt, cmd)
        amt = amt or 0
        if cmd == 'raw' then
            self.turn_rate  = amt
        else
            self.turn_rate  = amt*grad
        end
    end
    function tb:set_target(targ)
        self.target = targ
    end
    function tb:get_target()
        return self.target
    end

    otb.launch      = tb.launch
    otb.config_move = tb.config_move

    --  Convenience methods
    function tb:launch(...)
        if (self.target == 0) or (not self.target) then return;
        elseif self:is_moving() then return;
        end
        if mtb.stopped[self] then
            local t = {...}
            doAfter(0.00, tb.launch, self, table.unpack(t))
            return
        end
        otb.config_move(self, tb.while_moving)
        otb.launch(self, ...)
    end
    function tb:config_move(func)
        if not is_function(func) then return;
        end
        moving[self]    = func
    end

    local temp  = {}
    function tb.while_moving(self)
        self  = mtb[self]

        --  Consider a 0-collision size missile first
        --  With an instant turn rate (<= 0)
        temp.tx, temp.ty    = GetWidgetX(self.target), GetWidgetY(self.target)
        temp.cx, temp.cy    = self.missile:get_x(), self.missile:get_y()
        temp.theta          = math.atan(temp.ty - temp.cy, temp.tx - temp.cx)
        temp.theta          = tb.apply_turn_rate(temp.theta, self.facing, self.turn_rate)

        temp.cos            = math.cos(temp.theta)
        temp.sin            = math.sin(temp.theta)
        temp.cx             = temp.cx + self.speed*temp.cos
        temp.cy             = temp.cy + self.speed*temp.sin
        temp.dx             = temp.cx + self.col_size*temp.cos
        temp.dy             = temp.cy + self.col_size*temp.sin
        temp.disp           = self.speed*self.speed
        temp.dist           = (temp.tx-temp.dx)*(temp.tx-temp.dx) + (temp.ty-temp.dy)*(temp.ty-temp.dy)

        self.facing         = temp.theta
        temp.h              = 0
        if moving[self] then
            temp.h = moving[self](self, temp.theta) or 0
        end
        if not self:is_moving() then return Vector2D(0, 0), temp.h;
        end

        if temp.disp < temp.dist then
            return Vector2D(self.speed*temp.cos, self.speed*temp.sin), temp.h
        else
            mtb.stopped[self]   = true
            self:stop()
            mtb.stopped[self]   = false
            return Vector2D(temp.tx - self.missile:get_x(), temp.ty - self.missile:get_y()), temp.h
        end
    end
end