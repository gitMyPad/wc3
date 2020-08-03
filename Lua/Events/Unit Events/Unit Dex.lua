do
    local m_dex         = protected_table()
    local info          = {
        preplaced_flag  = true,
        preplace_table  = {},
        register_table  = {},
        index_table     = {},
        alloc           = {[0]=0},
    }

    UnitDex                 = setmetatable({}, m_dex)
    m_dex.__metatable       = UnitDex
    m_dex._UNDEFEND         = 852056
    m_dex._DETECT_LEAVE     = FourCC("uDex")        --  Ability must be based on footman's defend ability
    m_dex._OVERRIDE         = false
    m_dex._REMOVE           = RemoveUnit

    local param         = {
        ENTER_EVENT     = EventListener:create(),
        LEAVE_EVENT     = EventListener:create()
    }
    if m_dex._OVERRIDE then
        info.setdata   = SetUnitUserData
        function SetUnitUserData(whichUnit, data)
        end
    end

    local function checkparams(ev)
        return param[ev] ~= nil
    end
    function m_dex.register(ev, func)
        if not checkparams(ev) then
            return
        end
        param[ev]:register(func)
    end
    function m_dex.deregister(ev, func)
        if not checkparams(ev) then
            return
        end
        param[ev]:deregister(func)
    end

    Initializer("TRIGGER", function()
        m_dex._GROUP    = CreateGroup()

        local function new_index()
            local i = info.alloc[0]
            if info.alloc[i] == 0 then
                i               = i + 1
                info.alloc[0]   = i
            else
                info.alloc[0]   = info.alloc[i]
            end
            info.alloc[i]   = 0
            return i
        end
        local function recycle_index(i)
            if not info.alloc[i] then
                return
            end
            if info.alloc[i] ~= 0 then
                return
            end
            info.alloc[i]   = info.alloc[0]
            info.alloc[0]   = i
        end
        local function throw_event(ev, whichunit)
            local prev_unit = m_dex.eventUnit
            local prev_type = m_dex.eventType
            m_dex.eventUnit = whichunit
            m_dex.eventType = ev
            param[ev]:execute(whichunit)
            m_dex.eventUnit = prev_unit
            m_dex.eventType = prev_type
        end

        local function reg(whichunit)
            if info.register_table[whichunit] then return;
            end
            --  Proceed with registration
            info.register_table[whichunit]  = true
            info.preplace_table[whichunit]  = info.preplaced_flag
            if info.setdata then
                local i             = new_index()
                info.index_table[i] = whichunit
                info.setdata(whichunit, i)
            end
            --  Add detection ability
            UnitAddAbility(whichunit, m_dex._DETECT_LEAVE)
            UnitMakeAbilityPermanent(whichunit, true, m_dex._DETECT_LEAVE)
            BlzUnitDisableAbility(whichunit, m_dex._DETECT_LEAVE, true, true)
            --  Add Unit to the global group
            GroupAddUnit(m_dex._GROUP, whichunit)
            --  Throw event
            throw_event("ENTER_EVENT", whichunit)
        end
        local function dereg(whichunit)
            if not info.register_table[whichunit] then return;
            end
            --  Proceed with removal
            info.register_table[whichunit]  = nil
            info.preplace_table[whichunit]  = nil
            if info.setdata then
                local i             = GetUnitUserData(whichunit)
                recycle_index(i)
                info.index_table[i] = nil
                info.setdata(whichunit, 0)
            end
            --  Remove the unit from the global group
            GroupRemoveUnit(m_dex._GROUP, whichunit)
            --  Throw event
            throw_event("LEAVE_EVENT", whichunit)
        end

        --  RemoveUnit is overwritten to instantly deregister the unit
        --  instead of anticipating the undefend order
        function RemoveUnit(whichunit)
            dereg(whichunit)
            m_dex._REMOVE(whichunit)
        end
        
        local trig  = CreateTrigger()
        TriggerRegisterEnterRegion(trig, WorldRect.reg, nil)
        TriggerAddCondition(trig, Filter(function()
            reg(GetTriggerUnit())
        end))
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function()
            if GetIssuedOrderId() ~= m_dex._UNDEFEND then return;
            elseif GetUnitAbilityLevel(GetTriggerUnit(), m_dex._DETECT_LEAVE) ~= 0 then return;
            end
            dereg(GetTriggerUnit())
        end)
        --  Enumerate all pre-placed units
        local tempgrp   = CreateGroup()
        GroupEnumUnitsInRect(tempgrp, WorldRect.rect, nil)
        ForGroup(tempgrp, function()
            reg(GetEnumUnit())
        end)
        DestroyGroup(tempgrp)
        info.preplaced_flag = false
    end)
    function m_dex.is_preplaced(whichunit)
        return info.preplace_table[whichunit]
    end
    function EnumAllUnits(whichgroup, filter)
        if whichgroup == m_dex._GROUP then return;
        end

        GroupClear(whichgroup)
        for i = 0, BlzGroupGetSize(m_dex._GROUP) - 1 do
            local uu = BlzGroupUnitAt(m_dex._GROUP, i)
            if filter(uu) then
                GroupAddUnit(whichgroup, uu)
            end
        end
    end

    IsUnitPreplaced = m_dex.is_preplaced

    do
        local temp  = {index={}, max={}}
        local function index_pop()
            local index = #temp.index
            temp.index[index]  = nil
            temp.max[index]    = nil
            if index == 1 then
                PauseTimer(temp.timer)
            end
        end
        local function index_clear()
            while #temp.index > 0 do
                index_pop()
            end
        end
        local function index_push()
            local index = #temp.index + 1
            temp.index[index]  = 0
            temp.max[index]    = BlzGroupGetSize(m_dex._GROUP)
            if index == 1 then
                if not temp.timer then
                    temp.timer  = CreateTimer()
                end
                TimerStart(temp.timer, 0.00, false, index_clear)
            end
        end
        local function unit_iterator()
            local unit
            while (not unit) and (temp.index[#temp.index] < temp.max[#temp.index]) do
                unit = BlzGroupUnitAt(m_dex._GROUP, temp.index[#temp.index])
                temp.index[#temp.index] = temp.index[#temp.index] + 1
            end
            if unit then return unit;
            end
            if temp.index[#temp.index] >= temp.max[#temp.index] then
                index_pop()
            end
        end
        function UnitIterator()
            index_push()
            return unit_iterator
        end
    end
    if info.setdata then
        function m_dex.unit_from_id(i)
            return info.index_table[i]
        end
        function m_dex.unit_id(whichunit)
            return GetUnitUserData(whichunit)
        end
        function GetUnitById(i)
            return m_dex.unit_from_id(i)
        end
        function GetUnitId(whichunit)
            return m_dex.unit_id(whichunit)
        end
    end
end