do
    local tb        = protected_table()
    tb.PRELOAD_SIZE = 1024

    local data      = {}
    local pointer   = {}

    local next      = {}
    local prev      = {}
    local size      = {}
    local database  = {}

    local tstack    = {}
    List            = setmetatable({}, tb)
    LinkedList      = List

    data.__index    = function(t, k)
        if k == 'data' then
            return data[t]
        end
        return nil
    end
    data.__newindex = function(t, k, v)
    end

    for i = 1, tb.PRELOAD_SIZE do
        tstack[i]   = setmetatable({}, data)
    end

    local function remove_from_class(self)
        local meta      = tb.__metatable
        tb.__metatable  = nil
        setmetatable(self, nil)
        tb.__metatable  = meta
    end
    local function stack_request()
        if tstack[#tstack] then
            local t         = tstack[#tstack]
            tstack[#tstack] = nil
            return t
        end
        return {}
    end
    local function stack_restore(t)
        tstack[#tstack + 1] = t
    end
    local function generic_insert(self, func, ...)
        local n = select('#', ...)
        if n == 0 then return;
        elseif n == 1 then generic_insert(self, func, 1, select(1, ...)); return;
        end

        local j     = math.floor(select(1, ...) + 0.5)
        local start = self
        local ptb   = {}
        while j > 1 do
            start   = next[self][start]
            j   = j - 1
        end
        for k = 2, n do
            local t         = stack_request()
            data[t]         = select(k, ...)
            pointer[t]      = self
            ptb[#ptb + 1]   = t
            if not database[self][data[t]] then
                database[self][data[t]] = 1
            else
                database[self][data[t]] = database[self][data[t]] + 1
            end
            func(self, t, start)
            next[self][prev[self][t]]   = t
            prev[self][next[self][t]]   = t

            size[self]      = size[self] + 1
        end
        return table.unpack(ptb)
    end
    local function rout_insert(self, t, start)
        next[self][t]   = start
        prev[self][t]   = prev[self][start]
    end
    local function rout_unshift(self, t, start)
        prev[self][t]   = start
        next[self][t]   = next[self][start]
    end

    --  Constructor
    function tb:__call(...)
        local o     = {}
        next[o]     = {}
        prev[o]     = {}
        database[o] = {}
        size[o]     = 0

        next[o][o]  = o
        prev[o][o]  = o
        tb.insert(o, ...)
        setmetatable(o, tb)
        return o
    end
    function tb:insert(...)
        return generic_insert(self, rout_insert, ...)
    end
    function tb:unshift(...)
        return generic_insert(self, rout_unshift, ...)
    end

    function tb:remove(t)
        if pointer[t] ~= self then return;
        elseif t == self then return;
        end

        database[self][data[t]] = database[self][data[t]] - 1
        if database[self][data[t]] <= 0 then
            database[self][data[t]] = nil
        end

        data[t]     = nil
        pointer[t]  = nil

        next[self][prev[self][t]]   = next[self][t]
        prev[self][next[self][t]]   = prev[self][t]
        next[self][t]   = nil
        prev[self][t]   = nil
        size[self]  = size[self] - 1
        
        stack_restore(t)
    end
    function tb:first()
        return data[next[self][self]], next[self][self]
    end
    function tb:last()
        return data[prev[self][self]], prev[self][self]
    end
    function tb:next(t)
        return next[self][t]
    end
    function tb:prev(t)
        return next[self][t]
    end

    function tb:unshift()
        self:remove(select(2, self:first()))
    end
    function tb:pop()
        self:remove(select(2, self:last()))
    end

    function tb:is_node_in(t)
        return pointer[t] == self
    end
    function tb:is_elem_in(elem)
        return database[self][elem] ~= nil
    end

    --  Destructors
    function tb:clear()
        while size[self] > 0 do
            self:remove(prev[self][self])
        end
    end
    function tb:destroy()
        if not size[self] then return;
        end
        self:clear()
        next[self][self]    = nil
        prev[self][self]    = nil

        database[self]  = nil
        next[self]  = nil
        prev[self]  = nil
        size[self]  = nil
    end

    --  Size getters
    function tb:size()
        return size[self]
    end
    function tb:__len()
        return size[self]
    end
end