do
    local m_listener        = getmetatable(EventListener)
    local event_tb          = {
        cur_event           = 0,
        cur_function        = 0,
    }
    m_listener.__metatable  = EventListener

    local old_method       = {
        new     = m_listener.new,
        dest    = m_listener.destroy,
        reg     = m_listener.register,
        dereg   = m_listener.deregister
    }
    local temp_method       = {}

    function m_listener:new(o)
        o               = o or {}
        o.recr          = {}
        o.remove_count  = {}
        o.active_count  = {}
        o.dest_count    = 0
        o.mut_count     = 0
        o.max_recr      = 0
        return old_method.new(self, o)
    end
    function m_listener:destroy()
        self.recr           = nil
        self.remove_count   = nil
        self.active_count   = nil
        old_method.dest(self)
    end
    function m_listener:register(func, rep)
        local flag  = old_method.reg(self, func, rep)
        if flag and not self.recr[func] then
            self.recr[func]         = 0
            self.active_count[func] = 0
        end
        return flag
    end
    function m_listener:deregister(func, rep)
        local flag  = old_method.dereg(self, func, rep)
        if flag and not self.func_point[func] then
            self.recr[func]         = nil
            self.active_count[func] = nil
        end
        return flag
    end
    function m_listener:enable(func)
        if not self.func_point[func] then return;
        end
        self.active_count[func] = self.active_count[func] + 1
    end
    function m_listener:disable(func)
        if not self.func_point[func] then return;
        end
        self.active_count[func] = self.active_count[func] - 1
    end
    function m_listener:is_enabled(func)
        if not self.func_point[func] then return false;
        end
        return self.active_count[func] >= 0
    end
    function m_listener:is_registered(func)
        return self.func_point[func] ~= nil
    end
    function m_listener:get_depth()
        return self.mut_count
    end
    function m_listener.get_event()
        return event_tb.cur_event
    end
    function m_listener.get_cur_function()
        return event_tb.cur_function
    end

    do
        function temp_method:register(func, rep)
            rep         = rep or 1
            if not self.func_point[func] then
                return m_listener.register(self, func, rep)
            else
                if self.remove_count[func] then
                    self.remove_count[func] = self.remove_count[func] - rep
                else
                    self.remove_count[func] = -rep
                end
            end
        end
        function temp_method:deregister(func, rep)
            rep = rep or 1
            if not self.func_point[func] then
                return m_listener.deregister(self, func, rep)
            else
                if self.remove_count[func] then
                    self.remove_count[func] = self.remove_count[func] + rep
                else
                    self.remove_count[func] = rep
                end
            end
        end
        function temp_method:destroy()
            self.dest_count = self.dest_count + 1
        end
        function temp_method:restore()
            self.dest_count = self.dest_count - 1
        end
    
        local function evaluate_cond(self, cond)
            if not is_function(cond) then return cond;
            end
            return cond();
        end
        local function pass_recr(self, i)
            if self.max_recr <= 0 then return true end

            local func = self.list[i]
            return self.recr[func] < self.max_recr and 
                   self.list_count[self.func_point[func]] > self.remove_count[func]
        end
        local is_enabled    = m_listener.is_enabled

        local function override_setters(self)
            --  Temporarily overwrite self:register, self:deregister, and self:destroy
            rawset(self, 'register', temp_method.register)
            rawset(self, 'deregister', temp_method.deregister)
            rawset(self, 'destroy', temp_method.destroy)
            rawset(self, 'restore', temp_method.restore)
        end
        local function reset_setters(self)
            rawset(self, 'register', nil)
            rawset(self, 'deregister', nil)
            rawset(self, 'destroy', nil)
            rawset(self, 'restore', nil)
        end

        function m_listener:_restore()
            local i = 1
            while i <= #self.list do
                local func = self.list[i]
                if self.remove_count[func] then
                    if self.remove_count[func] > 0 then
                        self:deregister(func, self.remove_count[func])
                    else
                        self:register(func, -self.remove_count[func])
                    end
                    self.remove_count[func] = nil
                    --  If the instance was removed at any point, reset index
                    if not self.func_point[func] then
                        i = i - 1
                    end
                end
                i = i + 1
            end
        end
        function m_listener:conditional_exec(cond, ...)
            local tbs       = {
                cur_event       = event_tb.cur_event,
                cur_function    = event_tb.cur_function
            }
            event_tb.cur_event      = self
            self.mut_count          = self.mut_count + 1
            if self.mut_count == 1 then
                override_setters(self)
            end
            local i = 1
            while i <= #self.list do
                local func      = self.list[i]
                if not self.remove_count[func] then self.remove_count[func] = 0;
                end
                if is_enabled(self, func) and evaluate_cond(self, cond) and pass_recr(self, i) then
                    event_tb.cur_function   = func
                    self.recr[func]         = self.recr[func] + 1
                    
                    local k = 1
                    while k <= (self.list_count[i] - self.remove_count[func]) do
                        pcall(func, ...)
                        k = k + 1
                    end
                    self.recr[func] = self.recr[func] - 1
                end
                i = i + 1
            end
            event_tb.cur_event      = tbs.cur_event
            event_tb.cur_function   = tbs.cur_function
            self.mut_count          = self.mut_count - 1
            if self.mut_count <= 0 then
                reset_setters(self)
                if self.dest_count > 0 then
                    self:destroy()
                else
                    m_listener._restore(self)
                end
            end
        end
    end
    function m_listener:execute(...)
        self:conditional_exec(true, ...)
    end
    function m_listener:set_recursion_count(value)
        value           = ((type(value) ~= 'number') and 0) or value
        self.max_recr   = value
    end
    function m_listener:set_recursion_depth(value)
        self:set_recursion_count(value)
    end
end