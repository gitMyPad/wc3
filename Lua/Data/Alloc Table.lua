do
    local tb        = protected_table()
    AllocTable      = setmetatable({}, tb)
    tb._alloc       = {}
    tb.__metatable  = AllocTable
    tb._DEF_ALLOC   = 32

    function tb:__call(o, size, const, dest)
        local o         = protected_table()
        local co        = {}
        tb._alloc[o]    = co

        size            = size or tb._DEF_ALLOC
        local i         = 1
        while i <= size do
            co[i]       = {}
            i           = i + 1
        end
        o.__call        = function(t, ...)
            local oo
            if #co > 0 then
                oo      = co[#co]
                co[#co] = nil
            else
                oo      = {}
            end
            if o.__constructor then
                o.__constructor(oo, ...)
            end
            setmetatable(oo, o)
            return oo
        end
        o.__destroy     = function(t)
            if not getmetatable(t) then return;
            end

            local mt        = o.__metatable
            if o.__destructor then
                o.__destructor(t)
            end
            o.__metatable   = nil
            setmetatable(t, nil)
            o.__metatable   = mt

            co[#co + 1] = t
        end
        o.create        = o.__call
        o.new           = o.__call
        o.destroy       = o.__destroy
        return o, co
    end
end