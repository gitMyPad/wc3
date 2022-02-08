scope ShadowEye

private module ShadowEyeConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00Y'
    endmethod
    static constant method operator AMPLIFY_FACTOR takes nothing returns real
        return 5.0
    endmethod
    static constant method operator SHADOW_MODEL takes nothing returns string
        return "Abilities\\Weapons\\AvengerMissile\\AvengerMissile.mdl"
    endmethod
    static constant method operator SHADOW_ATTACH takes nothing returns string
        return "chest"
    endmethod
    static method filterTarget takes unit source, unit target returns boolean
        return (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (IsUnitEnemy(target, GetOwningPlayer(source))) and /*
            */ (IsUnitInvisible(target, Player(bj_PLAYER_NEUTRAL_VICTIM)))
    endmethod
endmodule

private struct ShadowEye extends array
    implement ShadowEyeConfig
    private static method onDamageModify takes nothing returns nothing
        local real missHP
        if (GetUnitAbilityLevel(DamageHandler.source, ABILITY_ID) == 0) or /*
        */ (not thistype.filterTarget(DamageHandler.source, DamageHandler.target)) then
            return
        endif
        set DamageHandler.dmg   = DamageHandler.dmg*AMPLIFY_FACTOR
        call DestroyEffect(AddSpecialEffectTarget(SHADOW_MODEL, DamageHandler.target, SHADOW_ATTACH))
    endmethod

    private static method init takes nothing returns nothing
        call DamageHandler.MODIFIER_OUTGOING.register(function thistype.onDamageModify)
    endmethod
    implement Init
endstruct

endscope