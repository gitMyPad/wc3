library UnitArmorStat requires CustomUnitStatFactory

globals
    private constant integer ABILITY_ID                         = '!001'
    private constant abilityintegerlevelfield ABILITY_FIELD     = ABILITY_ILF_DEFENSE_BONUS_IDEF
endglobals

struct ArmorStat extends array
    private static ability array abilHandle

    private method onApply takes unit whichUnit, real amount returns nothing
        call IncUnitAbilityLevel(whichUnit, ABILITY_ID)
        if (amount < 0) then
            set amount  = amount - 0.5
        else
            set amount  = amount + 0.5
        endif
        call BlzSetAbilityIntegerLevelField(abilHandle[GetUnitId(whichUnit)], ABILITY_FIELD, /* 
            */ 0, R2I(amount))
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