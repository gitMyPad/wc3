scope Maul

private module MaulConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A009'
    endmethod
    static constant method operator BONUS_DAMAGE takes nothing returns real
        return 60.0
    endmethod
    static constant method operator MAUL_CHANCE takes nothing returns integer
        return 20
    endmethod
    static constant method operator MAUL_MODEL takes nothing returns string
        return "Objects\\Spawnmodels\\Human\\HumanBlood\\BloodElfSpellThiefBlood.mdl"
    endmethod
    static constant method operator STUN_DURATION_NORMAL takes nothing returns real
        return 1.0
    endmethod
    static constant method operator STUN_DURATION_HERO takes nothing returns real
        return 0.5
    endmethod
    static constant method operator DAMAGE_RECOVER_FACTOR takes nothing returns real
        return 0.5
    endmethod
    static method filterTarget takes unit source, unit target returns boolean
        return (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MECHANICAL))
    endmethod
endmodule

private struct Maul extends array
    implement MaulConfig

    private static method onDamageModify takes nothing returns nothing
        local integer srcID     = 0
        local real dur          = STUN_DURATION_NORMAL
        //  Filter out unwanted sources
        if (GetUnitAbilityLevel(DamageHandler.source, ABILITY_ID) == 0) or /*
        */ (not DamageHandler.isDamageAttack()) or /*
        */ (not Maul.filterTarget(DamageHandler.source, DamageHandler.target)) or /*
        */ (GetRandomInt(1, 100) > MAUL_CHANCE) then
            return
        endif
        if (IsUnitType(DamageHandler.target, UNIT_TYPE_HERO)) or /*
        */ (IsUnitType(DamageHandler.target, UNIT_TYPE_RESISTANT)) then
            set dur             = STUN_DURATION_HERO
        endif
        set DamageHandler.dmg   = DamageHandler.dmg + BONUS_DAMAGE
        call SetWidgetLife(DamageHandler.source, GetWidgetLife(DamageHandler.source) /*
                       */+ DamageHandler.dmg*DAMAGE_RECOVER_FACTOR)
        call DestroyEffect(AddSpecialEffectTarget(MAUL_MODEL, DamageHandler.source, "head"))
        call Stun.applyBuff(DamageHandler.target, dur)
    endmethod

    private static method onInit takes nothing returns nothing
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamageModify)
    endmethod
endstruct
endscope