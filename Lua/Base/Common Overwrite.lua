do
    local old_func  = {}
    old_func.print  = print

    function print_after(delay, ...)
        if not delay or delay < 0 then old_func.print(...) return;
        end
        local t = {...}
        TimerStart(CreateTimer(), delay, false, function()
            old_func.print(table.unpack(t))
            DestroyTimer(GetExpiredTimer())
        end)
    end
    function is_function(func)
        if func == nil then return true;
        elseif type(func) == 'function' then return true;
        end
        if type(func) == 'table' then
            return is_function(getmetatable(func).__call)
        end
    end
end