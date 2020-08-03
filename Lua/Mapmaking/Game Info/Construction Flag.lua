do
    local tb    = {}

    function IsUnitUnderConstruction(whichunit)
        return tb[whichunit] ~= nil
    end

    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_START, function()
        local unit      = GetConstructingStructure()
        tb[unit]  = true
    end)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, function()
        local unit      = GetConstructedStructure()
        tb[unit]  = nil
    end)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, function()
        local unit      = GetConstructedStructure()
        tb[unit]  = nil
    end)
    UnitDex.register("LEAVE_EVENT", function()
        tb[UnitDex.eventUnit] = nil
    end)
end