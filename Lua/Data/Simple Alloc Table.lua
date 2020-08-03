do
    local tb        = protected_table()
    AllocTableEx    = setmetatable({}, tb)

    tb._DEF_SIZE    = 0
    tb._ALLOC       = {}
    function tb:__call(size)
        size            = size or 50

        local o         = protected_table()
        local co        = {pointer={}}
        tb._ALLOC[o]    = co
        
        if size > 0 then
            for i = 1, size do
                co[i]               = {}
                co.pointer[co[i]]   = i
            end
        end
        o.request   = function()
            if co[#co] then
                local t         = co[#co]
                co.pointer[t]   = nil
                co[#co]         = nil
                return t
            end
            return {}
        end
        o.release   = function(t)
            if co.pointer[t] then return;
            end
            co[#co + 1]     = t
            co.pointer[t]   = #co
        end
        o.restore   = o.release
        return o
    end
end