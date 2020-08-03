do
    local tb        = getmetatable(List)
    local ftb       = {flag={}}
    local temp      = {}
    local lock      = {}

    local rmvcall   = {}
    local rmvstack  = {}
    local destcall  = {}
    local curnode   = {}
    local curftb    = {depth=0}

    local _insert   = tb.insert
    local _unshift  = tb.unshift

    local function lock_object(self)
        if not lock[self] then
            lock[self]      = 0
            destcall[self]  = 0
            rawset(self, 'remove', temp.remove)
            rawset(self, 'clear', temp.clear)
            rawset(self, 'destroy', temp.destroy)
        end
        lock[self]  = lock[self] + 1
    end
    local function unlock_object(self)
        lock[self]  = lock[self] - 1
        if lock[self] <= 0 then
            lock[self]      = nil
            curnode[self]   = nil
            rawset(self, 'remove', nil)
            rawset(self, 'clear', nil)
            rawset(self, 'destroy', nil)

            if destcall[self] > 0 then
                destcall[self]  = nil
                self:destroy()
            end
        end
    end
    local function iterator_unlock(obj, self)
        curftb[obj.depth][self]     = nil
    end
    local function iterator_lock(obj, self)
        while curftb.depth < lock[self] do
            curftb.depth            = curftb.depth + 1
            curftb[curftb.depth]    = {}
        end
        curftb[lock[self] ][self]    = obj
    end
    local function iterator_restore(obj)
        if ftb.flag[obj] then return;
        end
        ftb[#ftb + 1]   = obj
        ftb.flag[obj]   = true
        
        iterator_unlock(obj, obj.list)
        unlock_object(obj.list)
        obj.debug       = nil
        obj.depth       = nil
        obj.list        = nil
        obj.node        = nil
    end
    local function iterator_request()
        local obj
        if ftb[#ftb] then
            obj             = ftb[#ftb]
            ftb[#ftb]       = nil
            ftb.flag[obj]   = false
            return obj
        end
        obj             = {}
        obj.timer       = CreateTimer()
        obj.callback    = function()
            local node  = obj.node
            obj.node    = obj.list:next(obj.node)

            if rmvstack[node] then
                rmvstack[node] = rmvstack[node] - 1
                if rmvstack[node] < 0 then
                    tb.remove(obj.list, node)
                    rmvstack[node]  = nil
                    rmvcall[node]   = nil
                end
            end
            if obj.node == obj.list then
                PauseTimer(obj.timer)
                iterator_restore(obj)
                return nil;
            end

            node                = obj.node
            curnode[obj.list]   = node
            rmvstack[node]      = rmvstack[node] or 0
            rmvstack[node]      = rmvstack[node] + 1
            if obj.debug then
                print("Current rmvstack[node]", rmvstack[node])
            end
            return node.data, node, lock[obj.list]
        end
        TimerStart(obj.timer, 0.00, false, function()
            PauseTimer(obj.timer)
            iterator_restore(obj)
        end)
        PauseTimer(obj.timer)
        return obj
    end

    function temp:remove(node)
        if curnode[self] == node then
            if rmvcall[node] then return;
            end
            rmvcall[node]   = 1
            rmvstack[node]  = rmvstack[node] - 1
            return
        end
        if rmvstack[node] then
            if rmvcall[node] then return;
            end
            rmvcall[node]   = 1
            rmvstack[node]  = rmvstack[node] - 1
            return
        end
        tb.remove(self, node)
    end
    function temp:clear()
        local i     = 1
        local j     = #self
        local node  = select(2, self:first())
        while i <= j do
            local prev_node = node
            node            = self:next(node)

            self:remove(prev_node)
            i   = i + 1
        end
    end
    function temp:destroy()
        destcall[self]  = 1
    end

    function tb:insert(...)
        local n = select('#', ...)
        if n == 0 then
            return self
        end
        return self, _insert(self, 1, ...)
    end
    function tb:unshift(...)
        local n = select('#', ...)
        if n == 0 then
            return self
        end
        return self, _unshift(self, 1, ...)
    end
    function tb:is_head(t)
        return t == self
    end
    function tb:new(...)
        return self(...)
    end
    function tb:create(...)
        return self(...)
    end
    function tb:random()
        if #self <= 0 then return nil, nil;
        end

        local i     = math.random(1, #self)
        local iter  = select(2, self:first())
        while i > 1 do
            iter    = self:next(iter)
            i       = i - 1
        end
        return iter.data, iter
    end

    function tb:iterator(node, debug)
        if (not node) or (not self:is_node_in(node)) then
            node    = self
        end

        local obj           = iterator_request()
        lock_object(self)
        iterator_lock(obj, self)

        obj.list            = self
        obj.node            = node
        obj.depth           = lock[self]
        obj.debug           = debug

        ResumeTimer(obj.timer)
        return obj.callback
    end
    function tb:remove_elem(elem)
        if not self:is_elem_in(elem) then return;
        end
        for comp_elem, pointer in self:iterator() do
            if elem == comp_elem then
                tb.remove(self, pointer)
                break
            end
        end
    end
end