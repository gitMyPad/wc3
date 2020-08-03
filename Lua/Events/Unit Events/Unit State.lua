do
    local m_state           = protected_table()
    UnitState               = setmetatable({}, m_state)
    m_state.__metatable     = UnitState

    m_state._DETECT_ABIL    = FourCC("uDey")
    m_state._UNDEFENSE      = "magicundefense"
    m_state._EVENTS         = {
        DEATH_EVENT         = 1,
        RESURRECT_EVENT     = 2,
        TRANSFORM_EVENT     = 3,
        LOAD_EVENT          = 4,
        UNLOAD_EVENT        = 5,
    }
    m_state._properties     = {
        registered      = {},
        death_status    = {
            PHYSICAL_DEAD   = {},
            EVENT_DEAD      = {},
        },
        unit_type       = {},
        transporter     = {},
        transport_grp   = {},
    }
    m_state._listener       = PriorityEvent:create()
    m_state._listener:preload_registry(
        m_state._EVENTS.DEATH_EVENT,
        m_state._EVENTS.UNLOAD_EVENT
    )
    do
        local death_tb      = m_state._properties.death_status
        local transport_grp = m_state._properties.transport_grp
        local transporter   = m_state._properties.transporter
        local event_tb      = {count=0}
        local zero_timer

        Initializer("SYSTEM", function()
            zero_timer  = CreateTimer()
        end)
        local function do_throw(tb)
            if tb.event == "DEATH_EVENT" then
                m_state.eventKiller     = tb.killer
                m_state._listener:fire(m_state._EVENTS[tb.event], m_state.eventUnit,
                                       m_state.eventKiller, tb.killed)
            elseif tb.event == "LOAD_EVENT" or tb.event == "UNLOAD_EVENT" then
                m_state.eventTransport  = tb.transport
                m_state._listener:fire(m_state._EVENTS[tb.event], m_state.eventUnit,
                                       m_state.eventTransport)
            elseif tb.event == "TRANSFORM_EVENT" then
                m_state.prevUnitType    = tb.prev_type
                UnitAddAbility(tb.unit, m_state._DETECT_ABIL)
                BlzUnitHideAbility(tb.unit, m_state._DETECT_ABIL, true)
                m_state._listener:fire(m_state._EVENTS[tb.event], m_state.eventUnit,
                                       m_state.prevUnitType, GetUnitTypeId(m_state.eventUnit))
            else
                m_state._listener:fire(m_state._EVENTS[tb.event], m_state.eventUnit)
            end
            m_state.eventKiller     = nil
            m_state.eventTransport  = nil
            m_state.prevUnitType    = nil
        end
        local function iterate_events()
            local i         = 1
            local ev_unit   = m_state.eventUnit
            local ev_type   = m_state.eventType
            while i <= event_tb.count do
                m_state.eventUnit = event_tb[i].unit
                m_state.eventType = event_tb[i].event
                do_throw(event_tb[i])
                event_tb[i] = nil
                i = i + 1
            end
            m_state.eventUnit   = ev_unit
            m_state.eventType   = ev_type
            event_tb.count = 0
        end
        local function throw_event(event, unit)
            local tb    = {
                unit    = unit,
                event   = event,
            }
            event_tb.count              = event_tb.count + 1
            event_tb[event_tb.count]    = tb
            PauseTimer(zero_timer)
            TimerStart(zero_timer, 0, false, iterate_events)
            return tb
        end
        local function throw_unload_event(unit, transport)
            GroupRemoveUnit(transport_grp[transport], unit)
            transporter[unit] = nil
            throw_event("UNLOAD_EVENT", unit).transport = transport
        end
        Initializer("SYSTEM", function()
            RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function()
                local order = GetIssuedOrderId()
                if OrderId2String(order) ~= m_state._UNDEFENSE then return;
                end

                local unit      = GetTriggerUnit()
                local is_dead   = not UnitAlive(unit)

                --  Ability was removed, somehow
                --  Check if the unit was removed at any point in the game
                local cur_type  = GetUnitTypeId(unit)
                if cur_type == 0 then return;
                end
                --  Check for death or resurrect event
                if (is_dead ~= death_tb.PHYSICAL_DEAD[unit]) then
                    local event                     = (is_dead and "DEATH_EVENT") or "RESURRECT_EVENT"
                    death_tb.PHYSICAL_DEAD[unit]    = is_dead
                    if not is_dead then
                        death_tb.EVENT_DEAD[unit]   = false
                    end
                    throw_event(event, unit)
                end

                if GetUnitAbilityLevel(unit, m_state._DETECT_ABIL) ~= 0 then return;
                elseif cur_type == m_state._properties.unit_type[unit] then return;
                end
                throw_event("TRANSFORM_EVENT", unit).prev_type  = m_state._properties.unit_type[unit]
                m_state._properties.unit_type[unit]             = cur_type
            end)
            RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function()
                local unit                  = GetTriggerUnit()
                death_tb.EVENT_DEAD[unit]   = true
                for i = 1, event_tb.count do
                    local tb    = event_tb[i]
                    if tb.event == "DEATH_EVENT" and tb.unit == unit then
                        tb.killer   = GetKillingUnit()
                        tb.killed   = true
                        break
                    end
                end
            end)
            RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_LOADED, function()
                local transport, loadee = GetTransportUnit(), GetTriggerUnit()
                if not transport_grp[transport] then
                    transport_grp[transport]    = CreateGroup()
                end
                GroupAddUnit(transport_grp[transport], loadee)
                transporter[loadee] = transport

                SetUnitX(loadee, WorldRect.rectMaxX)
                SetUnitY(loadee, WorldRect.rectMaxY)
                throw_event("LOAD_EVENT", loadee).transport = transport
            end)

            local trig  = CreateTrigger()
            TriggerRegisterEnterRegion(trig, WorldRect.reg, nil)
            TriggerAddCondition(trig, Filter(function()
                local unit  = GetTriggerUnit()
                if not transporter[unit] or IsUnitLoaded(unit) then return;
                end
                throw_unload_event(unit, transporter[unit])
            end))
        end)

        UnitDex.register("ENTER_EVENT", function()
            local unit          = UnitDex.eventUnit
            UnitAddAbility(unit, m_state._DETECT_ABIL)
            BlzUnitHideAbility(unit, m_state._DETECT_ABIL, true)
            m_state._properties.registered[unit]    = true
            m_state._properties.unit_type[unit]     = GetUnitTypeId(unit)
            death_tb.PHYSICAL_DEAD[unit]            = not UnitAlive(unit)
        end)
        UnitDex.register("LEAVE_EVENT", function()
            local unit  = UnitDex.eventUnit
            m_state._properties.registered[unit]    = nil
            m_state._properties.unit_type[unit]     = nil
            death_tb[unit]                          = nil
            death_tb.PHYSICAL_DEAD[unit]            = nil
            death_tb.EVENT_DEAD[unit]               = nil

            if transport_grp[unit] then
                ForGroup(transport_grp[unit], function()
                    throw_unload_event(GetEnumUnit(), unit)
                end)
                iterate_events()
                DestroyGroup(transport_grp[transport])
                transport_grp[transport] = nil
            end
        end)

        function m_state.register(event, func)
            if not m_state._EVENTS[event] then return;
            end
            m_state._listener:register(m_state._EVENTS[event], func)
        end
        function m_state.deregister(event, func)
            if not m_state._EVENTS[event] then return;
            end
            m_state._listener:deregister(m_state._EVENTS[event], func)
        end

        local _GetTransportUnit = GetTransportUnit
        function GetTransportUnit(whichunit)
            if not whichunit then
                return _GetTransportUnit()
            end
            return transporter[whichunit]
        end
        function GetTransportedGroup(whichunit)
            return transport_grp[whichunit]
        end
        function UnitNotDead(whichunit)
            return death_tb.EVENT_DEAD[whichunit]
        end
    end

    local _KillUnit = KillUnit
    function KillUnit(whichunit)
        if UnitIsSleeping(whichunit) then
            BlzUnitDisableAbility(whichunit, m_state._DETECT_ABIL, false, true)
        end
        _KillUnit(whichunit)
    end
end