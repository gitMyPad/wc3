do
    local tb        = protected_table()
    UnitRecycler    = setmetatable({}, tb)
    tb.PLAYER       = Player(PLAYER_NEUTRAL_PASSIVE)
    tb.ABILITY_ID   = FourCC("uADA")    -- This ability must be based on phoenixmorph
    tb.ORDER_ID     = "phoenixmorph"

    tb._ids         = {}
    tb._pointer     = {}

    local function reset(unit)
        UnitAddAbility(unit, tb.ABILITY_ID)
        UnitMakeAbilityPermanent(unit, true, tb.ABILITY_ID)
    end
    local function animdeath_remove_aloc()
        local timer     = GetExpiredTimer()
        local unit      = GetTimerData(timer)
        local t         = tb._pointer[unit]
        if not t.aloc_flag and (not t.recycled) then
            UnitRemoveAbility(whichunit, FourCC("Aloc"))
        end
        PauseTimer(timer)
        DestroyTimer(timer)
    end
    function tb:simulate_death(whichunit)
        if not tb._pointer[whichunit] then return;
        end
        local t         = tb._pointer[whichunit]
        local time      = BlzGetUnitRealField(whichunit, UNIT_RF_DEATH_TIME)
        if not t.aloc_flag then
            UnitAddAbility(whichunit, FourCC("Aloc"))
        end
        SetUnitAnimation(whichunit, "death")
        QueueUnitAnimation(whichunit, "decay flesh")
        QueueUnitAnimation(whichunit, "decay bone")

        local timer     = CreateTimer()
        SetTimerData(timer, whichunit)
        TimerStart(timer, time, false, animdeath_remove_aloc)
    end
    function tb:recycle(whichunit)
        if not tb._pointer[whichunit] then return;
        end
        local t         = tb._pointer[whichunit]
        local unitid    = t.unitid

        t.recycled      = true
        tb._ids[unitid].restore(t)
        SetUnitOwner(whichunit, tb.PLAYER, true)
        ShowUnit(whichunit, false)
        PauseUnit(whichunit, true)
        if not t.aloc_flag then
            UnitAddAbility(whichunit, FourCC('Aloc'))
        end
        SetUnitX(whichunit, WorldRect.rectMinX)
        SetUnitY(whichunit, WorldRect.rectMinY)
        SetWidgetLife(whichunit, BlzGetUnitMaxHP(whichunit)*10000)
    end
    function tb:request(player, unitid, x, y, face)
        x, y, face  = x or 0, y or 0, face or 0
        if not tb._ids[unitid] then
            tb._ids[unitid]  = AllocTableEx(0)
        end
        local t     = tb._ids[unitid].request()
        t.recycled  = false
        if not t.unit then
            t.unit                  = CreateUnit(player, unitid, x, y, face)
            t.aloc_flag             = (GetUnitAbilityLevel(t.unit, FourCC("Aloc")) ~= 0)
            t.unitid                = unitid
            tb._pointer[t.unit]     = t
            UnitAddAbility(t.unit, tb.ABILITY_ID)
            UnitMakeAbilityPermanent(t.unit, true, tb.ABILITY_ID)
        else
            SetUnitAnimation(t.unit, "stand")
            SetUnitOwner(t.unit, player, true)
            SetUnitFacing(t.unit, face)
            ShowUnit(t.unit, true)
            PauseUnit(t.unit, false)
            UnitRemoveAbility(t.unit, FourCC('Aloc'))
            if t.aloc_flag then
                UnitAddAbility(t.unit, FourCC('Aloc'))
            end
            SetUnitPosition(t.unit, x, y)
        end
        return t.unit
    end
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function()
        local unit  = GetTriggerUnit()
        local order = OrderId2String(GetIssuedOrderId())

        if order ~= tb.ORDER_ID then return;
        elseif not tb._pointer[unit] then return;
        end

        UnitRemoveAbility(unit, tb.ABILITY_ID)
        SetWidgetLife(unit, BlzGetUnitMaxHP(unit)*10000)
        doAfter(0.00, reset, unit)
    end)

    --  Just in case a recycled unit is accidentally removed.
    UnitDex.register("LEAVE_EVENT", function(unit)
        if not tb._pointer[unit] then return;
        end

        local t             = tb._pointer[unit]
        local unitid        = t.unitid
        tb._pointer[unit]   = nil
        t.unit              = nil
        t.unitid            = nil
        t.aloc_flag         = nil
        if not t.recycled then
            tb._ids[unitid].restore(t)
            t.recycled  = true
        end
    end)
end