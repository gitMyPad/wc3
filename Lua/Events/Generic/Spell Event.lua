do
    local m_spell       = protected_table()
    SpellEvent          = setmetatable({}, m_spell)
    m_spell.__listeners = PriorityEvent:create()
    m_spell.__spellId   = {}

    local mt_id         = setmetatable({
        [EVENT_PLAYER_UNIT_SPELL_CAST]      = 1,
        [EVENT_PLAYER_UNIT_SPELL_CHANNEL]   = 2,
        [EVENT_PLAYER_UNIT_SPELL_EFFECT]    = 3,
        [EVENT_PLAYER_UNIT_SPELL_ENDCAST]   = 4,
        [EVENT_PLAYER_UNIT_SPELL_FINISH]    = 5,
        [EVENT_PLAYER_HERO_SKILL]           = 6,
        --  Unit events
        [EVENT_UNIT_SPELL_CAST]     = 1,
        [EVENT_UNIT_SPELL_CHANNEL]  = 2,
        [EVENT_UNIT_SPELL_EFFECT]   = 3,
        [EVENT_UNIT_SPELL_ENDCAST]  = 4,
        [EVENT_UNIT_SPELL_FINISH]   = 5,
    }, {__index = function(t, k) return 0 end})

    local function event2Id(event)
        return mt_id[event]
    end
    local function conv(event)
        return ConvertPlayerUnitEvent(GetHandleId(event))
    end
    function m_spell.register(event, func)
        if tostring(event):sub(1,5) == 'event' then event = conv(event); end
        local i = event2Id(event)
        if i ~= 0 then
            m_spell.__listeners:register(i, func)
        end
    end
    function m_spell.register_spell(event, abilId, func)
        local i = event2Id(event)
        if i == 0 then
            return
        end
        if not m_spell.__spellId[abilId] then
            m_spell.__spellId[abilId]   = {}
        end
        if not m_spell.__spellId[abilId][i] then
            m_spell.__spellId[abilId][i]    = EventListener:create()
        end
        m_spell.__spellId[abilId][i]:register(func)
    end
    Initializer("SYSTEM", function()
        local resp_func = function()
            local unit              = GetTriggerUnit()
            local id, abilId        = event2Id(GetTriggerPlayerUnitEventId()), GetSpellAbilityId()
            if id == 6 then abilId  = GetLearnedSkill() end
            m_spell.__listeners:fire(id, unit, abilId)
            if m_spell.__spellId[abilId] and m_spell.__spellId[abilId][id] then
                m_spell.__spellId[abilId][id]:execute(unit, abilId)
            end
        end
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CAST, resp_func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CHANNEL, resp_func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, resp_func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_ENDCAST, resp_func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_FINISH, resp_func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_HERO_SKILL, resp_func)
    end)
end