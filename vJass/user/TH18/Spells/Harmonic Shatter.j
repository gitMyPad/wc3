scope HarmonicShatter

private module HarmonicShatterConfig
    readonly static integer array RESET_ABIL_ID
    static group tempGroup                          = null

    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00U'
    endmethod
    private static method onInit takes nothing returns nothing
        set RESET_ABIL_ID[1]                        = 'A00Q'
        set RESET_ABIL_ID[2]                        = 'A00S'
    endmethod
endmodule

private struct HarmonicShatter extends array
    implement HarmonicShatterConfig

    private static method onSpellEffect takes nothing returns nothing
        local integer i     = 1
        loop
            exitwhen (RESET_ABIL_ID[i] == 0)
            call BlzEndUnitAbilityCooldown(SpellHandler.unit, RESET_ABIL_ID[i])
            set i           = i + 1
        endloop
    endmethod
    private static method onInit takes nothing returns nothing
        call SpellHandler.register(EVENT_EFFECT, ABILITY_ID, function thistype.onSpellEffect)
    endmethod
endstruct

endscope