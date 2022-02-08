scope SharpShotDaggers

private module SharpShotDaggerConfig
    static constant method operator TECH_ID takes nothing returns integer
        return 'R006'
    endmethod
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00B'
    endmethod
    static constant method operator DEBUFF_ID takes nothing returns integer
        return 'B004'
    endmethod
    static constant method operator BONUS_CHANCE takes nothing returns integer
        return 25
    endmethod
    static constant method operator BONUS_DAMAGE takes nothing returns real
        return 35.0
    endmethod
    static constant method operator HP_LOSS_FACTOR takes nothing returns real
        return 0.08
    endmethod
    static constant method operator HP_LOSS_FACTOR_HERO takes nothing returns real
        return 0.0
    endmethod
    static constant method operator TARGET_EFFECT takes nothing returns string
        return "Custom\\Model\\Buff\\Snipe Target Ex.mdx"
    endmethod
    static constant method operator TARGET_ATTACH takes nothing returns string
        return "overhead"
    endmethod
    static method filterTarget takes unit source, unit target returns boolean
        return (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (IsUnitEnemy(target, GetOwningPlayer(source)))
    endmethod
endmodule

private struct SharpShotDagger extends array
    implement SharpShotDaggerConfig
    private static method onDamageModify takes nothing returns nothing
        local real missHP
        if (GetUnitAbilityLevel(DamageHandler.source, ABILITY_ID) == 0) or /*
        */ (not IsAbilityReqLifted(GetOwningPlayer(DamageHandler.source), TECH_ID, 1)) or /*
        */ (GetUnitAbilityLevel(DamageHandler.source, DEBUFF_ID) != 0) or /*
        */ (not DamageHandler.isDamageAttack()) or /*
        */ (not thistype.filterTarget(DamageHandler.source, DamageHandler.target)) or /*
        */ (GetRandomInt(1, 100) > BONUS_CHANCE) then
            return
        endif
        set missHP  = GetUnitState(DamageHandler.target, UNIT_STATE_MAX_LIFE) - GetWidgetLife(DamageHandler.target)
        if (IsUnitType(DamageHandler.target, UNIT_TYPE_HERO)) or /*
        */ (IsUnitType(DamageHandler.target, UNIT_TYPE_RESISTANT)) then
            set DamageHandler.dmg   = DamageHandler.dmg + BONUS_DAMAGE + missHP*HP_LOSS_FACTOR_HERO
        else
            set DamageHandler.dmg   = DamageHandler.dmg + BONUS_DAMAGE + missHP*HP_LOSS_FACTOR
        endif
        call AddSpecialEffectTargetTimed(TARGET_EFFECT, DamageHandler.target, TARGET_ATTACH, 0.5)
    endmethod

    private static method init takes nothing returns nothing
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamageModify)
    endmethod
    implement Init
endstruct

endscope