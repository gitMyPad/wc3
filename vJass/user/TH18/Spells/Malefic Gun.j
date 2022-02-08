scope MaleficGun

private module MaleficGunConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A004'
    endmethod
    static constant method operator DEBUFF_ID takes nothing returns integer
        return 'B001'
    endmethod
    static constant method operator BASE_DAMAGE takes nothing returns real
        return 10.0
    endmethod
    static constant method operator CUR_MANA_DAMAGE_FACTOR takes nothing returns real
        return 0.15
    endmethod
    static constant method operator CUR_MANA_COST_FACTOR takes nothing returns real
        return 0.10
    endmethod
    static constant method operator GUN_ATTACK_TYPE takes nothing returns attacktype
        return ATTACK_TYPE_NORMAL
    endmethod
    static constant method operator GUN_DAMAGE_TYPE takes nothing returns damagetype
        return DAMAGE_TYPE_LIGHTNING
    endmethod
endmodule

private struct MaleficGun extends array
    implement MaleficGunConfig

    private static group  dragonGroup   = CreateGroup()
    private static EventResponder resp  = 0

    private static method onDragonEnter takes nothing returns nothing
        local unit whichUnit    = GetIndexedUnit()
        if (GetUnitAbilityLevel(whichUnit, ABILITY_ID) == 0) then
            set whichUnit   = null
            return
        endif
        call GroupAddUnit(dragonGroup, whichUnit)
        if (BlzGroupGetSize(dragonGroup) == 1) then
            call GTimer[UPDATE_TICK].requestCallback(resp)
        endif
        set whichUnit   = null
    endmethod

    private static method onDragonLeave takes nothing returns nothing
        local unit whichUnit    = GetIndexedUnit()
        if (not IsUnitInGroup(whichUnit, dragonGroup)) then
            set whichUnit   = null
            return
        endif
        call GroupRemoveUnit(dragonGroup, whichUnit)
        if (BlzGroupGetSize(dragonGroup) == 0) then
            call GTimer[UPDATE_TICK].releaseCallback(resp)
        endif
        set whichUnit   = null
    endmethod

    private static method onDragonTransform takes nothing returns nothing
        local unit whichUnit    = UnitAuxHandler.unit
        //  The unit might have lost the ability when transforming.
        if (IsUnitInGroup(whichUnit, dragonGroup) and /*
        */ (GetUnitAbilityLevel(whichUnit, ABILITY_ID) == 0)) then
            call GroupRemoveUnit(dragonGroup, whichUnit)
            if (BlzGroupGetSize(dragonGroup) == 0) then
                call GTimer[UPDATE_TICK].releaseCallback(resp)
            endif
            set whichUnit   = null
            return
        endif
        if (not IsUnitInGroup(whichUnit, dragonGroup)) and /*
        */ (GetUnitAbilityLevel(whichUnit, ABILITY_ID) != 0) then
            //  The unit might have acquired the ability
            call GroupAddUnit(dragonGroup, whichUnit)
            if (BlzGroupGetSize(dragonGroup) == 1) then
                call GTimer[UPDATE_TICK].requestCallback(resp)
            endif
        endif
        set whichUnit   = null
    endmethod

    private static method updateMana takes nothing returns nothing
        local unit picked   = GetEnumUnit()
        local real curMana  = GetUnitState(picked, UNIT_STATE_MANA)
        if (UnitAlive(picked)) then
            call BlzSetUnitAbilityManaCost(picked, ABILITY_ID, 0, R2I(curMana*CUR_MANA_COST_FACTOR))
        endif
        set picked = null
    endmethod
    private static method onMonitorMana takes nothing returns nothing
        call ForGroup(dragonGroup, function thistype.updateMana)
    endmethod

    private static method onDamage takes nothing returns nothing
        local real mana
        if (GetUnitAbilityLevel(DamageHandler.target, DEBUFF_ID) == 0) then
            return
        endif
        call UnitRemoveAbility(DamageHandler.target, DEBUFF_ID)
        set mana    = GetUnitState(DamageHandler.source, UNIT_STATE_MANA)
        call UnitDamageTarget(DamageHandler.source, DamageHandler.target, BASE_DAMAGE + mana*CUR_MANA_DAMAGE_FACTOR, /*
                            */false, false, GUN_ATTACK_TYPE, GUN_DAMAGE_TYPE, null)
    endmethod
    private static method init takes nothing returns nothing
        set resp    = GTimer.register(UPDATE_TICK, function thistype.onMonitorMana)
        call OnUnitIndex(function thistype.onDragonEnter)
        call OnUnitDeindex(function thistype.onDragonLeave)
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamage)
        call UnitAuxHandler.ON_TRANSFORM.register(function thistype.onDragonTransform)
    endmethod
    implement Init
endstruct

endscope