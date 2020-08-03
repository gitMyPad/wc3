do
    local tb        = AllocTable(200)
    local t         = {[1]={}, [2]={}}
    local data      = {}
    tb._NORMAL      = Vector2D.ORIGIN
    tb.INTERVAL     = 64
    tb.GRADIENT     = 1/tb.INTERVAL
    Missile         = setmetatable({}, tb)

    tb._moving      = TimerIterator:create(tb.INTERVAL, function(self)
        if rawget(self, 'on_update') then
            t[1].vect, t[1].dz  = self.on_update(self)
        else
            t[1].vect, t[1].dz  = tb._NORMAL, 0
        end

        if not self.effect then return;
        elseif not self.running then return;
        end

        local tx, ty, h     = self:get_x(), self:get_y(), self:get_height()
        self:set_x(tx + t[1].vect.x)
        self:set_y(ty + t[1].vect.y)
        self:set_height(h + t[1].dz)

        t[1], t[2]          = t[2], t[1]
    end)

    --  Getters and setters
    function tb:get_x()
        return GetEffectX(self.effect)
    end
    function tb:get_y()
        return GetEffectY(self.effect)
    end
    function tb:get_height()
        return GetEffectHeight(self.effect)
    end
    function tb:set_x(val)
        SetEffectX(self.effect, val)
    end
    function tb:set_y(val)
        SetEffectY(self.effect, val)
    end
    function tb:set_height(val)
        SetEffectHeight(self.effect, val)
    end

    --  Convenience functions
    function tb:show(flag)
        ShowEffect(self.effect, flag)
    end
    function tb:visible()
        return IsEffectVisible(self.effect, flag)
    end

    function tb:set_data(value)
        data[self]  = value
    end
    function tb:get_data()
        return data[self]
    end

    --  Constructor and destructor
    function tb:__constructor(path, x, y)
        self.effect     = AddSpecialEffect(path, x, y)
        self.running    = false
    end
    function tb:__destructor()
        self:stop()
        if rawget(self, 'on_destroy') then
            local func      = self.on_destroy
            rawset(self, 'on_destroy', nil)
            func(self)
        end
        rawset(self, 'on_stop', nil)
        rawset(self, 'on_launch', nil)
        rawset(self, 'on_update', nil)

        DestroyEffect(self.effect)
        data[self]      = nil
        self.effect     = nil
        self.running    = nil
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
    function tb:stop()
        if not self.running then return;
        end

        self.running    = false
        tb._moving:remove(self)
        if rawget(self, 'on_stop') then
            self.on_stop(self)
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
end