do
    local tb    = {__index = function(t, k) return tb[k] end, __newindex = function() end}
    local wt    = {__mode  = 'kv'}
    tb.__DEF    = 16
    WeakObject  = setmetatable({}, tb)

    function tb:__call(size)
        local mo    = {}
        local o     = {}
        local co    = {}

        size        = size or tb.__DEF
        local i     = 1
        while i <= size do
            co[i]   = {}
            i       = i + 1
        end
        o.__index       = function(t, k)
            if o[k] then return o[k];
            elseif not mo[k] then return nil;
            end
            return mo[k][t]
        end
        o.__newindex    = function(t, k, v)
            if o[k] then return;
            end
            if not mo[k] then
                mo[k]   = setmetatable({}, wt)
            end
            mo[k][t]    = v
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
        o.destroy       = o.__destroy
        o.__gc          = function(self)
            self:__destroy()
        end
        return o, mo, co
    end
end