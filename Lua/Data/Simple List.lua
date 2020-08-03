do
    local tb    = protected_table()
    SimpleList  = setmetatable({}, tb)

    function tb:__call(...)
        local o = setmetatable({list = LinkedList(), pointer = {}}, tb)
        local j = select('#', ...)
        for i = 1, j do
            o:insert(select(i, ...))
        end
        return o
    end
    function tb:create()
        return self()
    end
    function tb:new()
        return self()
    end
    function tb:destroy()
        self:clear()
        self.pointer    = nil
    end

    function tb:insert(elem)
        if self.pointer[elem] then return false;
        end
        self.pointer[elem] = select(2, self.list:insert(elem))
        return true
    end
    function tb:remove(elem)
        if not self.pointer[elem] then return false;
        end
        self.list:remove(self.pointer[elem])
        self.pointer[elem] = nil
        return true
    end
    function tb:is_in(elem)
        return self.pointer[elem] ~= nil
    end
    function tb:iterator(node, debug)
        return self.list:iterator(node, debug)
    end
    function tb:__len()
        return #self.list
    end
    function tb:random()
        return self.list:random()
    end
    function tb:clear()
        local node  = select(2, self.list:first())
        local j     = #self.list
        while j > 0 do
            local prev_node = node
            node            = self.list:next(node)

            self:remove(prev_node.data)
            j = j - 1
        end
    end
end