scope Dragonhide

private module DragonhideConfig
    static constant method operator TECH_ID takes nothing returns integer
        return 'R005'
    endmethod
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00C'
    endmethod
    static constant method operator PIERCE_DAMAGE_RESIST_FACTOR takes nothing returns real
        return 0.20
    endmethod
    static constant method operator NORMAL_DAMAGE_RESIST_FACTOR takes nothing returns real
        return 0.15
    endmethod
    static constant method operator PIERCE_DAMAGE_RESIST_BASE takes nothing returns real
        return 12.0
    endmethod
    static constant method operator NORMAL_DAMAGE_RESIST_BASE takes nothing returns real
        return 6.0
    endmethod
    static constant method operator MIN_DAMAGE_AFTER_REDUC takes nothing returns real
        return 2.0
    endmethod
    static method filterAttackType takes attacktype a returns boolean
        return (a == ATTACK_TYPE_MELEE) or /*
            */ (a == ATTACK_TYPE_PIERCE)
    endmethod
endmodule

private struct Dragonhide extends array
    implement DragonhideConfig
    private static method onDamageModify takes nothing returns nothing
        local real missHP
        if (GetUnitAbilityLevel(DamageHandler.target, ABILITY_ID) == 0) or /*
        */ (not IsAbilityReqLifted(GetOwningPlayer(DamageHandler.target), TECH_ID, 1)) or /*
        */ (not thistype.filterAttackType(DamageHandler.attacktype)) or /*
        */ (DamageHandler.dmg <= MIN_DAMAGE_AFTER_REDUC) then
            return
        endif
        if (DamageHandler.attacktype == ATTACK_TYPE_MELEE) then
            set DamageHandler.dmg   = RMaxBJ(DamageHandler.dmg*(1 - NORMAL_DAMAGE_RESIST_FACTOR) - NORMAL_DAMAGE_RESIST_BASE, MIN_DAMAGE_AFTER_REDUC)
        else
            set DamageHandler.dmg   = RMaxBJ(DamageHandler.dmg*(1 - PIERCE_DAMAGE_RESIST_FACTOR) - PIERCE_DAMAGE_RESIST_BASE, MIN_DAMAGE_AFTER_REDUC)
        endif
    endmethod

    private static method onInit takes nothing returns nothing
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamageModify)
    endmethod
endstruct

endscope