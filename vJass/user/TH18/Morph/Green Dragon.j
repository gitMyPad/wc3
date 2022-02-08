scope GreenDragonMorph

private module GreenDragonMorphConfig
    static real array FLY_HEIGHT

    static method initVars takes nothing returns nothing
        set thistype.ABIL_ID            = 'A008'

        set thistype.UNIT_ID[1]         = 'e000'
        set thistype.UNIT_ID[2]         = 'e001'
        set thistype.UNIT_ID[3]         = 'e002'

        set thistype.MORPH_SKILL_ID[1]  = 'A005'
        set thistype.MORPH_SKILL_ID[2]  = 'A006'
        set thistype.MORPH_SKILL_ID[3]  = 'A007'

        set thistype.FLY_HEIGHT[1]      = 80.0
        set thistype.FLY_HEIGHT[2]      = 0.0
        set thistype.FLY_HEIGHT[3]      = 240.0
    endmethod

    implement GenericMorphHandler
endmodule

private struct GreenDragonMorph extends array
    private static real array lastMana
    private static boolean array surgingStrikesHidden
    private static boolean array manaStored

    private static method onEnter takes unit dragon, integer curType returns nothing
        if (curType == 2) then
            call UnitMakeAbilityPermanent(dragon, true, 'A003')
        else
            set surgingStrikesHidden[GetUnitId(dragon)] = true
            set manaStored[GetUnitId(dragon)]           = (curType == 3)
        endif
    endmethod
    private static method onLeave takes unit dragon, integer curType returns nothing
        local integer dragID                = GetUnitId(dragon)
        set surgingStrikesHidden[dragID]    = false
        set manaStored[dragID]              = false
    endmethod
    private static method onAttemptMorph takes unit dragon, integer prevType, integer curType returns nothing
        local integer dragID                = GetUnitId(dragon)
        if (prevType == 3) then
            set lastMana[dragID]            = GetUnitState(dragon, UNIT_STATE_MANA)
        endif
    endmethod
    private static method onTransform takes unit dragon, integer curType returns nothing
        local integer dragID                = GetUnitId(dragon)
        if (curType == 3) then
            if (not manaStored[dragID]) then
                set manaStored[dragID]      = true
                set lastMana[dragID]        = 200.0
            endif
            call SetUnitState(dragon, UNIT_STATE_MANA, lastMana[dragID])
            call BlzSetUnitRealField(dragon, UNIT_RF_MANA_REGENERATION, 2.0)
        endif
        if (curType == 2) then
            if UnitAddAbility(dragon, 'A003') then
                call UnitMakeAbilityPermanent(dragon, true, 'A003')
            else
                call BlzUnitDisableAbility(dragon, 'A003', false, false)
            endif
            set surgingStrikesHidden[dragID]        = false
        else
            if (GetUnitAbilityLevel(dragon, 'A003') != 0) and /*
            */ (not surgingStrikesHidden[dragID]) then
                call BlzUnitDisableAbility(dragon, 'A003', true, true)
                set surgingStrikesHidden[dragID]    = true
            endif
        endif
        if UnitAddAbility(dragon, 'Amrf') and UnitRemoveAbility(dragon, 'Amrf') then
        endif
        call SetUnitFlyHeight(dragon, FLY_HEIGHT[curType], 0.0)
    endmethod
    implement GreenDragonMorphConfig
endstruct

endscope