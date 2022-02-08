library UnitAttackSpeedStat requires CustomUnitStatFactory

globals
    private constant integer ABILITY_ID = '!000'
    private constant abilityreallevelfield ABILITY_FIELD    = ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1
endglobals

struct AttackSpeedStat extends array
    private static ability array abilHandle

    private method onApply takes unit whichUnit, real amount returns nothing
        call IncUnitAbilityLevel(whichUnit, ABILITY_ID)
        call BlzSetAbilityRealLevelField(abilHandle[GetUnitId(whichUnit)], ABILITY_FIELD, /* 
            */ 0, amount)
        call DecUnitAbilityLevel(whichUnit, ABILITY_ID)
    endmethod

    static method onRegister takes unit whichUnit returns nothing
        call UnitAddAbility(whichUnit, ABILITY_ID)
        call UnitMakeAbilityPermanent(whichUnit, true, ABILITY_ID)
        set abilHandle[GetUnitId(whichUnit)]    = BlzGetUnitAbility(whichUnit, ABILITY_ID)
    endmethod

    implement CUnitStatFactory
endstruct

endlibrary