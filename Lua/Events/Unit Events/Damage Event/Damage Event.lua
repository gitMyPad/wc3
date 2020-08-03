--  Thanks to Bribe for the REPO thread about damage event interactions
do
    local tb    = protected_table()
    local dtb   = {dt=AllocTableEx(5), mt=AllocTableEx(5)}
    DamageEvent = setmetatable({}, tb)

    local interactions  = {
        dmg_type    = {
            magic       = 1,
            universal   = 2,
            normal      = 4
        },
        atk_type    = {
            normal  = 8,
            spells  = 16,
            magic   = 32
        },
    }
    interactions.atk_tb = {
        [ATTACK_TYPE_MELEE]     = interactions.atk_type.normal,
        [ATTACK_TYPE_PIERCE]    = interactions.atk_type.normal,
        [ATTACK_TYPE_SIEGE]     = interactions.atk_type.normal,
        [ATTACK_TYPE_CHAOS]     = interactions.atk_type.normal,
        [ATTACK_TYPE_HERO]      = interactions.atk_type.normal,
        [ATTACK_TYPE_NORMAL]    = interactions.atk_type.spells,
        [ATTACK_TYPE_MAGIC]     = interactions.atk_type.magic,
    }
    interactions.dmg_tb = {
        [DAMAGE_TYPE_UNKNOWN]           = interactions.dmg_type.universal,
        [DAMAGE_TYPE_UNIVERSAL]         = interactions.dmg_type.universal,
        [DAMAGE_TYPE_NORMAL]            = interactions.dmg_type.normal,
        [DAMAGE_TYPE_ENHANCED]          = interactions.dmg_type.normal,
        [DAMAGE_TYPE_POISON]            = interactions.dmg_type.normal,
        [DAMAGE_TYPE_DISEASE]           = interactions.dmg_type.normal,
        [DAMAGE_TYPE_ACID]              = interactions.dmg_type.normal,
        [DAMAGE_TYPE_DEFENSIVE]         = interactions.dmg_type.normal,
        [DAMAGE_TYPE_SLOW_POISON]       = interactions.dmg_type.normal,
        [DAMAGE_TYPE_FIRE]              = interactions.dmg_type.magic,
        [DAMAGE_TYPE_COLD]              = interactions.dmg_type.magic,
        [DAMAGE_TYPE_LIGHTNING]         = interactions.dmg_type.magic,
        [DAMAGE_TYPE_DIVINE]            = interactions.dmg_type.magic,
        [DAMAGE_TYPE_MAGIC]             = interactions.dmg_type.magic,
        [DAMAGE_TYPE_SONIC]             = interactions.dmg_type.magic,
        [DAMAGE_TYPE_FORCE]             = interactions.dmg_type.magic,
        [DAMAGE_TYPE_DEATH]             = interactions.dmg_type.magic,
        [DAMAGE_TYPE_MIND]              = interactions.dmg_type.magic,
        [DAMAGE_TYPE_PLANT]             = interactions.dmg_type.magic,
        [DAMAGE_TYPE_DEMOLITION]        = interactions.dmg_type.magic,
        [DAMAGE_TYPE_SPIRIT_LINK]       = interactions.dmg_type.magic,
        [DAMAGE_TYPE_SHADOW_STRIKE]     = interactions.dmg_type.magic,
    }
    tb._modifier     = PriorityEvent:create()
    tb._damage       = EventListener:create()
    tb._after_dmg    = EventListener:create()

    tb._LIFE_CHANGE_DELTA    = 0.00001
    tb._MODIFIER_EVENT       = {
        MODIFIER_EVENT_SYSTEM   = 5,
        MODIFIER_EVENT_ALPHA    = 4,
        MODIFIER_EVENT_BETA     = 3,
        MODIFIER_EVENT_GAMMA    = 2,
        MODIFIER_EVENT_DELTA    = 1,
    }
    tb._modifier:preload_registry(
        tb._MODIFIER_EVENT.MODIFIER_EVENT_DELTA,
        tb._MODIFIER_EVENT.MODIFIER_EVENT_SYSTEM
    )
    tb._pure_flag    = false

    local function mindex(t, k, v)
        return getmetatable(t)[k]
    end
    local function newindex(t, k, v)
        if getmetatable(t)[k] then return;
        end
        rawset(t, k, v)
    end
    local function clear_metatable(mt)
        mt.source           = nil
        mt.target           = nil
        mt.original_dmg     = nil
        mt.orig_atktype     = nil
        mt.orig_dmgtype     = nil
        mt.orig_wpntype     = nil
        mt.pure             = nil
        mt.block_dmg        = nil
        mt.wc3_dmg          = nil
        mt.__index          = nil
        mt.__newindex       = nil
    end
    local function clear_dmgtable(t)
        t.dmg       = nil
        t.atktype   = nil
        t.dmgtype   = nil
        t.wpntype   = nil
        t.suspend   = nil
    end
    local function restore_dmgtable(t)
        local mt    = getmetatable(t)
        clear_dmgtable(t)
        clear_metatable(mt)
        dtb.mt.restore(mt)
        dtb.dt.restore(t)
    end
    local function new_damage_info()
        local mt           = dtb.mt.request()
        mt.source          = GetEventDamageSource()
        mt.target          = GetTriggerUnit()
        mt.original_dmg    = GetEventDamage()
        mt.orig_atktype    = BlzGetEventAttackType()
        mt.orig_dmgtype    = BlzGetEventDamageType()
        mt.orig_wpntype    = BlzGetEventWeaponType()
        mt.pure            = tb._pure_flag
        mt.block_dmg       = 0
        
        local t             = dtb.dt.request()
        t.dmg               = mt.original_dmg
        t.atktype           = mt.orig_atktype
        t.dmgtype           = mt.orig_dmgtype
        t.wpntype           = mt.orig_wpntype
        t.suspend           = 0
        setmetatable(t, mt)

        mt.__index     = mindex
        mt.__newindex  = newindex
        return t
    end
    function SuspendDamageEvent(flag)
        if not tb.current then return;
        end
        if flag then
            tb.current.suspend   = tb.current.suspend + 1
        else
            tb.current.suspend   = tb.current.suspend - 1
        end
    end

    Initializer("SYSTEM", function()
        local zero_timer    = CreateTimer()
        local trigdata      = {}

        local function do_flush(i)
            if i > #dtb then return;
            end
            restore_dmgtable(dtb[i])
            while i < #dtb do
                dtb[i]  = dtb[i + 1]
                i       = i + 1
            end
            dtb[#dtb]   = nil
            tb.current  = dtb[#dtb]
        end
        --  A clearing callback function that removes dangling events
        local function clear_info()
            while #dtb > 0 do
                do_flush(#dtb)
            end
        end
        local function can_run_events()
            return tb.current.suspend <= 0
        end

        TimerStart(zero_timer, 0.00, false, clear_info)
        PauseTimer(zero_timer)

        local after_dmg_callback
        local function after_dmg_trigcall()
            local trig  = GetTriggeringTrigger()
            local index = trigdata[trig]
            DisableTrigger(trig)
            DestroyTrigger(trig)
            after_dmg_callback(index)
        end

        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DAMAGING, function()
            local t         = new_damage_info()
            local mt        = getmetatable(t)
            dtb[#dtb + 1]   = t
            tb.current      = t
            tb._modifier:fire(tb._MODIFIER_EVENT.MODIFIER_EVENT_SYSTEM, t.target, t.source, t.dmg)
            tb._modifier:conditional_fire_to(tb._MODIFIER_EVENT.MODIFIER_EVENT_ALPHA,
                                                tb._MODIFIER_EVENT.MODIFIER_EVENT_GAMMA,
                                                can_run_events, t.target, t.source, t.dmg)
            if not t.pure then
                BlzSetEventAttackType(t.atktype)
                BlzSetEventDamageType(t.dmgtype)
                BlzSetEventWeaponType(t.wpntype)
                BlzSetEventDamage(t.dmg)
            else
                t.atktype  = t.orig_atktype
                t.dmgtype  = t.orig_dmgtype
                t.wpntype  = t.orig_wpntype
                t.dmg      = t.original_dmg
            end

            if BlzIsUnitInvulnerable(t.target) or not UnitAlive(t.target) then
                do_flush(#dtb)
                return
            end

            local is_ethereal       = IsUnitType(t.target, UNIT_TYPE_ETHEREAL)
            local is_immune         = IsUnitType(t.target, UNIT_TYPE_MAGIC_IMMUNE)
            local atk_map, dmg_map  = interactions.atk_tb[t.atktype], interactions.dmg_tb[t.dmgtype]
            if is_ethereal and 
            (atk_map == interactions.atk_type.normal or 
            (atk_map == interactions.atk_type.spells and
            dmg_map == interactions.dmg_type.normal)) then
                do_flush(#dtb)
                return
            end
            if is_immune and 
            (atk_map == interactions.attackType.magic or
            dmg_map == interactions.damageType.magic) then
                do_flush(#dtb)
                return
            end
            if #dtb == 1 then
                ResumeTimer(zero_timer)
            end
        end)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DAMAGED, function()
            local t         = dtb[#dtb]
            local mt        = getmetatable(t)
            local index     = #dtb
            if not t then return;
            end
            
            mt.wc3_dmg      = GetEventDamage()
            t.dmg           = mt.wc3_dmg
            tb.current      = t

            --  Lock the ability to modify atktype, dmgtype and wpntype
            mt.atktype      = t.atktype
            mt.dmgtype      = t.dmgtype
            mt.wpntype      = t.wpntype
            t.atktype, t.dmgtype, t.wpntype      = nil
            tb._modifier:conditional_fire(tb._MODIFIER_EVENT.MODIFIER_EVENT_DELTA,
                                                can_run_events, t.target, t.source, t.dmg)
            if not mt.pure then
                BlzSetEventDamage(t.dmg)
                mt.dmg      = t.dmg
            else
                BlzSetEventDamage(mt.original_dmg)
                mt.dmg      = mt.original_dmg
            end
            t.dmg      = nil

            --  This event can modify the amount of damage blocked
            --  but not manipulate damage dealt directly
            mt.block   = nil
            t.block    = 0
            tb._damage:conditional_exec(can_run_events, t.target, t.source, t.dmg)
            BlzSetEventDamage(t.dmg - t.block)

            --  Check for unit-state changes here.
            if BlzIsUnitInvulnerable(t.target) or not UnitAlive(t.target) then
                do_flush(index)
                return
            end

            local curHP     = GetWidgetLife(t.target)
            SetWidgetLife(t.target, math.max(curHP - mt.dmg, 0.406))
            local nextHP    = GetWidgetLife(t.target)
            SetWidgetLife(t.target, curHP)
            
            if mt.dmg ~= 0 and math.max(curHP - nextHP) > tb._LIFE_CHANGE_DELTA then
                local detector  = CreateTrigger()
                TriggerRegisterUnitStateEvent(detector, t.target, UNIT_STATE_LIFE, GREATER_THAN, nextHP)
                TriggerRegisterUnitStateEvent(detector, t.target, UNIT_STATE_LIFE, LESS_THAN, nextHP)
                TriggerAddCondition(detector, Filter(after_dmg_trigcall))
                trigdata[detector]  = index
            else
                after_dmg_callback(index)
            end
        end)
        after_dmg_callback  = function(index)
            local t         = dtb[index]
            tb.current      = t
            tb._after_dmg:conditional_exec(can_run_events, t.target, t.source, t.dmg)
            do_flush(index)
        end
    end)

    function tb.register_modifier(event, func)
        if not tb._MODIFIER_EVENT[event] then return;
        end
        tb._modifier:register(tb._MODIFIER_EVENT[event], func)
    end
    function tb.register_damage(func)
        tb._damage:register(func)
    end
    function tb.register_after_damage(func)
        tb._after_dmg:register(func)
    end

    function IsPhysicalDamage()
        return interactions.atk_tb[tb.current.atktype] == interactions.atk_type.normal
    end
    function IsSpellDamage()
        return interactions.atk_tb[tb.current.atktype] == interactions.atk_type.spell
    end
    function IsMagicDamage()
        return interactions.atk_tb[tb.current.atktype] == interactions.atk_type.magic
    end
    function IsPureDamage()
        return tb.current.pure
    end
end