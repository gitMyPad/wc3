do
    local tb        = protected_table()
    tb._DEF_CHANCE  = 0.05
    FixedChance     = setmetatable({}, tb)

    function tb:create(chance)
        local o     = {}
        o._chance   = 1/(chance or tb._DEF_CHANCE)
        o._cur      = 0
        setmetatable(o, tb)
        return o
    end
    function tb:destroy()
        self._chance    = nil
        self._cur       = nil
    end
    function tb:test()
        self._cur    = self._cur + 1
        if self._cur >= self._chance then
            --  Wrap around
            self._cur = math.fmod(self._cur, self._chance)
            return true
        end
        return false
    end
    function tb:set_chance(chance)
        self._chance    = 1/(chance or tb._DEF_CHANCE)
    end
    function tb:get_chance()
        return 1/self._chance
    end
    function tb:cur_progress()
        return self._cur/self._chance
    end
end