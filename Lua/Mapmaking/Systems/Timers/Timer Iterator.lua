local tb        = protected_table()
tb.curList      = 0
tb.curFunc      = 0
TimerIterator   = setmetatable({}, tb)

function tb:create(iters, func)
    local o = {}
    o.list  = SimpleList()
    o.iters = iters
    o.func  = func
    o._call = function()
        local prev_list, prev_func  = tb.curList, tb.curFunc
        tb.curList, tb.curFunc      = o.list, func
        for elem in o.list:iterator() do
            func(elem)
        end
        tb.curList, tb.curFunc      = prev_list, prev_fun
        if #o.list == 0 then
            TimerEvent.deactivate(iters, o._call)
        end
    end
    o.list.debug    = true
    TimerEvent.register(iters, o._call)
    setmetatable(o, tb)
    return o
end
function tb:insert(elem)
    if self.list:insert(elem) and #self.list == 1 then
        TimerEvent.activate(self.iters, self._call)
    end
end
function tb:remove(elem)
    if self.list:remove(elem) and #self.list <= 0 then
        TimerEvent.deactivate(self.iters, self._call)
    end
end
function tb:is_elem_in(elem)
    return self.list:is_in(elem)
end