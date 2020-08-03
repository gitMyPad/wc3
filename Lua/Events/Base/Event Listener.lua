do
    local m_listener        = protected_table()
    EventListener           = setmetatable({}, m_listener)

    local function clean_object(self)
        local meta              = m_listener.__metatable
        m_listener.__metatable  = nil
        setmetatable(self, nil)
        m_listener.__metatable  = meta
    end
    function m_listener:new(o)
        o               = o or {}
        o.list          = {}
        o.list_count    = {}
        o.func_point    = {}
        setmetatable(o, m_listener)
        return o
    end
    function m_listener:create(o)
        return self:new(o)
    end
    function m_listener:__call(o)
        return self:new(o)
    end

    function m_listener:register(func, rep)
        if not is_function(func) or (self == EventListener) then return false;
        end
        rep = rep or 1

        if not self.func_point[func] then
            self.list[#self.list + 1]       = func
            self.list_count[#self.list]     = 0
            self.func_point[func]           = #self.list
        end
        local index             = self.func_point[func]
        self.list_count[index]  = self.list_count[index] + rep
        return true
    end
    function m_listener:deregister(func, rep)
        if not is_function(func) or (self == EventListener) or (not self.func_point[func]) then return false;
        end
        rep = rep or 1

        local index             = self.func_point[func]
        self.list_count[index]  = self.list_count[index] - rep
        if self.list_count[index] <= 0 then
            local i, j = index, #self.list
            while i < j do
                local func2             = self.list_count[i + 1]
                self.list_count[i]      = func2
                self.list[i]            = self.list[i + 1]
                self.func_point[func2]  = i
                i   = i + 1
            end
            self.list_count[j]      = nil
            self.list[j]            = nil
            self.func_point[func]   = nil
        end
        return true
    end
    function m_listener:destroy()
        while true do
            self:deregister(self.list[#self.list], self.list_count[#self.list])
            if #self.list <= 0 then break end
        end
        clean_object(self)
    end
end