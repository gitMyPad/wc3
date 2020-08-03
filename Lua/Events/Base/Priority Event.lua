do
    local m_prio        = protected_table()
    PriorityEvent       = setmetatable({}, m_prio)
    m_prio.__metatable  = PriorityEvent

    local function DoNothing()
    end
    function m_prio:new(o)
        o           = o or {}
        o.list      = {
            prio    = {[0]=0},
            event   = {[0]=EventListener:create()},
        }
        o.max       = 0
        o.min       = 0
        o.size      = 1
        setmetatable(o, m_prio)
        return o
    end
    function m_prio:create(o)
        return self:new(o)
    end
    function m_prio:__call(o)
        return self:new(o)
    end

    --  is_prio_in should return a flag, and an appropriate index
    local function is_prio_in(self, prior)
        if (prior >= self.max) then
            if prior == self.max then
                return true, self.size - 1
            end
            return false, self.size
        end
        if (prior <= self.min) then
            if prior == self.min then
                return true, 0
            end
            return false, 0
        end        
        local pos = self.size - 1
        while pos >= 0 do
            if prior >= self.list.prio[pos] then break;
            end
            pos = pos - 1
        end
        if prior == self.list.prio[pos] then
            return true, pos
        end
        return false, pos + 1
    end
    local function insert(self, prior, index)
        local i     = self.size - 1
        if index == 0 then
            self.min    = prior
        elseif index >= self.size then
            self.max    = prior
        end
        while i >= index do
            self.list.prio[i + 1]   = self.list.prio[i]
            self.list.event[i + 1]  = self.list.event[i]
            i = i - 1
        end
        self.size               = self.size + 1
        self.list.prio[index]   = prior
        self.list.event[index]  = EventListener:create()
    end

    --  prior will only accept integers.
    --  floats will be rounded to the nearest integer.
    --  If no priority is provided via nil, prior will instead default to self.min
    function m_prio:register(prior, func)
        prior           = prior or self.min
        prior           = math.floor(prior + 0.5)
        local has, pos  = is_prio_in(self, prior)
        if not has then insert(self, prior, pos);
        end
        self.list.event[pos]:register(func)
    end
    function m_prio:deregister(prior, func)
        prior           = prior or self.min
        prior           = math.floor(prior + 0.5)
        local has, pos  = is_prio_in(self, prior)
        if not has then return;
        end
        self.list.event[pos]:deregister(func)
    end
    function m_prio:conditional_fire(prior, cond, ...)
        prior           = prior or self.min
        prior           = math.floor(prior + 0.5)
        local has, pos  = is_prio_in(self, prior)
        if not has then return;
        end
        self.list.event[pos]:conditional_exec(cond, ...)
    end
    function m_prio:fire(prior, ...)
        self:conditional_fire(prior, true, ...)
    end
    function m_prio:conditional_fire_to(upper, lower, cond, ...)
        upper, lower    = math.floor(upper + 0.5), math.floor(lower + 0.5)
        local i, j      = select(2, is_prio_in(self, upper)), select(2, is_prio_in(self, lower))
        if i <= j then i, j    = j, i;
        end
        while i >= j do
            self.list.event[i]:conditional_exec(cond, ...)
            i = i - 1
        end
    end
    function m_prio:fire_to(upper, lower, ...)
        self:conditional_fire_to(upper, lower, true, ...)
    end
    function m_prio:fire_all(...)
        self:conditional_fire_to(self.max, self.min, true, ...)
    end
    function m_prio:conditional_fire_all(cond, ...)
        self:conditional_fire_to(self.max, self.min, cond, ...)
    end
    function m_prio:set_prio_recursion(prior, value)
        prior           = prior or self.min
        prior           = math.floor(prior + 0.5)
        local has, pos  = is_prio_in(self, prior)
        if not has then
            return
        end
        self.listeners[prior]:set_recursion_count(value)
    end
    function m_prio:preload_registry(min, max, incr)
        min     = min or self.min
        max     = max or self.max
        incr    = incr or 1
        while min <= max do
            self:register(min, DoNothing)
            self:deregister(min, DoNothing)
            min = min + incr
        end
    end
end