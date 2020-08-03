do
    local tb    = protected_table({
        _THRESHOLD  = 50,
        _CUR_INDEX  = 0,
    })
    DebugTable  = setmetatable({}, tb)

    function tb:__call(o, thresh, name)
        tb._CUR_INDEX   = tb._CUR_INDEX + 1
        o               = o or protected_table()
        o._THRESHOLD    = thresh or tb._THRESHOLD
        o._COUNTER      = {}
        o._CMAX         = {}
        o._NAME         = name or "DebugTable[" .. tostring(tb._CUR_INDEX) .. "]"
        o.__call        = function(self, name, crit)
            if type(name) ~= 'string' then return;
            end
            if not o._COUNTER[name] then
                o._COUNTER[name] = 0
                o._CMAX[name]    = crit or o._THRESHOLD
            end
        end
        o.refresh       = function(self, name)
            if type(name) ~= 'string' then return;
            elseif not o._COUNTER[name] then return;
            end
            o._COUNTER[name]    = 0
        end
        o.update        = function(self, name)
            if type(name) ~= 'string' then return;
            elseif not o._COUNTER[name] then return;
            end
            if o._COUNTER[name] == 0 then
                doAfter(0.00, o.refresh, o, name)
            end
            o._COUNTER[name]    = o._COUNTER[name] + 1
            if o._COUNTER[name] >= o._CMAX[name] then
                PauseGame(true)
                print(o._NAME .. " >> Game Paused! Recursion without a breakpoint detected.")
                print(o._NAME .. " >> Associated name of function: " .. name)
            end
        end
        local mo        = setmetatable({}, o)
        return mo, o
    end
end