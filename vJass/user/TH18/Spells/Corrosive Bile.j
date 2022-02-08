scope CorrosiveBile

private module CorrosiveBileConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A002'
    endmethod
    static method DEBUFF_ABIL_ID takes nothing returns integer
        return 'A@00'
    endmethod
    static method DEBUFF_BUFF_ID takes nothing returns integer
        return 'B@00'
    endmethod
    static constant method operator MAX_SOURCE_STACKS takes nothing returns integer
        return 3
    endmethod
    static constant method operator MAX_STACKS_PER_TARGET takes nothing returns integer
        return 8
    endmethod
    static constant method operator ARMOR_PER_STACK takes nothing returns real
        return -1.0
    endmethod
    static constant method operator DEBUFF_DURATION takes nothing returns real
        return 8.0
    endmethod
    static constant method operator DEBUFF_MODEL takes nothing returns string
        return "Custom\\Model\\Buff\\corrosive_bile_beta.mdx"
    endmethod
    static constant method operator DEBUFF_MODEL_ATTACH takes nothing returns string
        return "chest"
    endmethod
    static method BEHAVIOR_ID takes integer level returns integer
        return CustomBuff.BEHAVIOR_NO_BUFF + CustomBuff.BEHAVIOR_PHYSICAL
    endmethod
endmodule

private struct CorrosiveBile extends array
    implement CorrosiveBileConfig

    private static unit dmgSource       = null
    private static Buff array debuff
    private static effect array debuffFX
    private static Table array debuffTable
    private static integer array stackCount
    private static CStat array armorMod

    private unit source
    private static method onBuffRemove takes nothing returns nothing
        local integer id    = GetUnitId(Buff.current.unit)
        call DestroyEffect(debuffFX[id])
        call debuffTable[id].destroy()
        if (stackCount[id] != 0) then
            call armorMod[id].destroy()
        endif
        set debuffFX[id]    = null
        set debuffTable[id] = 0
        set debuff[id]      = 0
        set armorMod[id]    = 0
        set stackCount[id]  = 0
    endmethod

    private static method onBuffUnstack takes nothing returns nothing
        local integer id    = GetUnitId(Buff.current.unit)
        local integer srcID = 0
        //  This function assumes that the Buff is created
        //  via the method .applyTimed() instead of .apply().
        set srcID           = GetUnitId(thistype(Buff.lastData).source)
        set debuffTable[id].integer[srcID]  = debuffTable[id].integer[srcID] - 1
        if (debuffTable[id].integer[srcID] < MAX_SOURCE_STACKS) then
            set stackCount[id]              = stackCount[id] - 1
            set armorMod[id].amount         = ARMOR_PER_STACK*IMinBJ(stackCount[id], MAX_STACKS_PER_TARGET)
        endif
    endmethod

    private static method onBuffStack takes nothing returns nothing
        local integer id    = GetUnitId(Buff.current.unit)
        local integer srcID = GetUnitId(dmgSource)
        if (debuffTable[id] == 0) then
            set debuffTable[id] = Table.create()
        endif
        //  This function assumes that the Buff is created
        //  via the method .applyTimed() instead of .apply().
        set thistype(Buff.lastData).source  = dmgSource
        set debuffTable[id].integer[srcID]  = debuffTable[id].integer[srcID] + 1
        if (debuffTable[id].integer[srcID] <= MAX_SOURCE_STACKS) then
            set stackCount[id]              = stackCount[id] + 1
            set armorMod[id].amount         = ARMOR_PER_STACK*IMinBJ(stackCount[id], MAX_STACKS_PER_TARGET)
        endif
    endmethod

    private static method onDamage takes nothing returns nothing
        local integer id    = GetUnitId(DamageHandler.target)
        if ((GetUnitAbilityLevel(DamageHandler.source, ABILITY_ID) == 0) or /*
         */ (not DamageHandler.isDamageAttack())) then
            return
        endif
        set dmgSource           = DamageHandler.source
        if (armorMod[id] == 0) then
            set armorMod[id]    = ArmorStat.apply(DamageHandler.target, 0.0, STAT_ADD)
        endif
        if (debuffFX[id] == null) then
            set debuffFX[id]    = AddSpecialEffectTarget(DEBUFF_MODEL, DamageHandler.target, DEBUFF_MODEL_ATTACH)
        endif
        set debuff[id]          = thistype.applyBuff(DamageHandler.target, DEBUFF_DURATION)
    endmethod

    private static method onInit takes nothing returns nothing
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamage)
    endmethod
    implement CustomBuffHandler
endstruct

endscope