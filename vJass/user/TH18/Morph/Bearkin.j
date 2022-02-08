scope BearkinMorph

//  TO-DO: Fix mana regeneration.
private module BearkinMorphConfig
    static method initVars takes nothing returns nothing
        set thistype.ABIL_ID            = 'A00I'

        set thistype.UNIT_ID[1]         = 'e004'
        set thistype.UNIT_ID[2]         = 'e005'
        set thistype.UNIT_ID[3]         = 'e006'

        set thistype.MORPH_SKILL_ID[1]  = 'A00F'
        set thistype.MORPH_SKILL_ID[2]  = 'A00G'
        set thistype.MORPH_SKILL_ID[3]  = 'A00H'
    endmethod

    implement GenericMorphHandler
endmodule

private struct BearkinMorph extends array
    private static real array lastMana
    private static boolean array manaFirstTime

    private static method onEnter takes unit bearkin, integer curType returns nothing
        set manaFirstTime[GetUnitId(bearkin)]   = (curType != 3)
    endmethod
    private static method onLeave takes unit bearkin, integer curType returns nothing
        local integer bearID                    = GetUnitId(bearkin)
        set lastMana[bearID]                    = 0.0
        set manaFirstTime[bearID]               = false
    endmethod
    private static method onAttemptMorph takes unit bear, integer prevType, integer curType returns nothing
        local integer bearID                    = GetUnitId(bear)
        if (prevType == 3) then
            set lastMana[bearID]                = GetUnitState(bear, UNIT_STATE_MANA)
        endif
        if (manaFirstTime[bearID]) and (curType == 3) then
            set lastMana[bearID]                = 50.0
            set manaFirstTime[bearID]           = false
        endif
    endmethod
    private static method onTransform takes unit bearkin, integer curType returns nothing
        local integer bearID        = GetUnitId(bearkin)
        if (curType == 3) then
            if (GetUnitState(bearkin, UNIT_STATE_MANA) <= lastMana[bearID]) then
                call SetUnitState(bearkin, UNIT_STATE_MANA, lastMana[bearID])
            endif
            call BlzSetUnitRealField(bearkin, UNIT_RF_MANA_REGENERATION, 0.50)
        endif
        if UnitAddAbility(bearkin, 'Amrf') and UnitRemoveAbility(bearkin, 'Amrf') then
        endif
        call SetUnitFlyHeight(bearkin, GetUnitDefaultFlyHeight(bearkin), 0.0)
    endmethod

    implement BearkinMorphConfig
endstruct

endscope