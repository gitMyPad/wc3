library Stun requires CBuff

struct Stun extends array
    private static effect array fx

    private static method EFFECT_MODEL takes nothing returns string
        return "Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl"
    endmethod
    private static method EFFECT_ATTACHMENT takes nothing returns string
        return "overhead"
    endmethod
    private static method DEBUFF_ABIL_ID takes nothing returns integer
        return '!STN'
    endmethod
    private static method DEBUFF_BUFF_ID takes nothing returns integer
        return '^STN'
    endmethod

    private static method BEHAVIOR_ID takes integer level returns integer
        return CustomBuff.BEHAVIOR_PHYSICAL
    endmethod
    private static method PRIORITY_VALUE takes integer level returns integer
        return 2
    endmethod

    private static method onBuffRemove takes nothing returns nothing
        local integer id    = GetUnitId(Buff.current.unit)
        call BlzPauseUnitEx(Buff.current.unit, false)
        call DestroyEffect(fx[id])
        set fx[id]          = null
    endmethod
    private static method onBuffAdd takes nothing returns nothing
        set fx[GetUnitId(Buff.current.unit)]    = AddSpecialEffectTarget(EFFECT_MODEL(), Buff.current.unit, EFFECT_ATTACHMENT())
        call BlzPauseUnitEx(Buff.current.unit, true)
    endmethod
    implement CustomBuffHandler
endstruct

endlibrary