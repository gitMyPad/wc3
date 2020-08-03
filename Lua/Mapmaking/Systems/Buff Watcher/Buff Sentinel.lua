do
    local tb        = getmetatable(BuffWatcher)
    tb.__metatable  = BuffWatcher

    --  Does not sandbox the function at all,
    --  but adds the ability for buffs to listen to its' removal
    local _native   = {
        removeAbil      = UnitRemoveAbility,
        removeBuffs     = UnitRemoveBuffs,
        removeBuffsEx   = UnitRemoveBuffsEx,
    }
    function UnitRemoveAbility(whichunit, abilId)
        local result    = _native.removeAbil(whichunit, abilId)
        if not result then return result;
        elseif not tb._u_buff_list[whichunit] then return result;
        elseif not tb._u_buff_list[whichunit][abilId] then return result;
        end

        local self  = tb._u_buff_list[whichunit][abilId]
        tb._destroy(self)
        return result
    end
    function UnitRemoveBuffs(whichunit, remove_pos, remove_neg)
        _native.removeBuffs(whichunit, remove_pos, remove_neg)
        if not tb._u_buff_list[whichunit] then return;
        end
        local list  = tb._u_buff_list[unit]
        for self in list.list:iterator() do
            self:check()
        end
    end
    -- UnitRemoveBuffsEx(whichUnit, removePositive, removeNegative, magic, physical, timedLife, aura, autoDispel)
    function UnitRemoveBuffsEx(whichunit, remove_pos, remove_neg, ...)
        _native.removeBuffsEx(whichunit, remove_pos, remove_neg, ...)
        if not tb._u_buff_list[whichunit] then return;
        end
        local list  = tb._u_buff_list[unit]
        for self in list.list:iterator() do
            self:check()
        end
    end

    UnitState.register("DEATH_EVENT", function(unit)
        if not tb._u_buff_list[unit] then return;
        end

        local list  = tb._u_buff_list[unit]
        for self in list.list:iterator() do
            tb._destroy(self)
        end
    end)
    UnitDex.register("LEAVE_EVENT", function(unit)
        if not tb._u_buff_list[unit] then return;
        end

        local list  = tb._u_buff_list[unit]
        for self in list.list:iterator() do
            tb._destroy(self)
        end
        list.list:destroy()
        tb._u_buff_list[unit]   = nil
    end)
end