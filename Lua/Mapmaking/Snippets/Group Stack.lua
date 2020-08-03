do
    local tb    = {pointer={}}

    function tb.request()
        local obj
        if not tb[#tb] then
            obj             = {group = CreateGroup(), index=0, max=0}
            obj.callback    = function()
                local unit  = nil
                while (not unit) and (obj.index <= obj.max) do
                    unit        = BlzGroupUnitAt(obj.group, obj.index)
                    obj.index   = obj.index + 1
                end
                if obj.index > obj.max then
                    PauseTimer(obj.timer)
                    tb.recycle(obj)
                    return nil;
                end
                return unit
            end
            obj.timer       = CreateTimer()
            SetTimerData(obj.timer, obj)
            TimerStart(obj.timer, 0.00, false, tb.recycle_obj)
            return obj
        end
        obj             = tb[#tb]
        tb[#tb]         = nil
        tb.pointer[obj] = nil
        return obj
    end
    function tb.recycle(obj)
        if tb.pointer[obj] then return;
        end
        tb[#tb + 1]     = obj
        tb.pointer[obj] = #tb
    end
    function tb.recycle_obj()
        tb.recycle(GetTimerData(GetExpiredTimer()))
    end
    function tb.enum_factory(func)
        return function(...)
            local obj   = tb.request()
            func(obj.group, ...)

            obj.index   = 0
            obj.max     = BlzGroupGetSize(obj.group)
            ResumeTimer(obj.timer)

            return obj.callback
        end
    end

    EnumUnitsInRange    = tb.enum_factory(GroupEnumUnitsInRange)
    EnumUnitsOfPlayer   = tb.enum_factory(GroupEnumUnitsOfPlayer)
end