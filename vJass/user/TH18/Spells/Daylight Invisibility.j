scope DaylightInvisibility

private module DaylightInvisibilityConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00K'
    endmethod
    static constant method operator TINT_ALPHA_START takes nothing returns integer
        return 0xff
    endmethod
    static constant method operator TINT_ALPHA_END takes nothing returns integer
        return 0x7f
    endmethod
endmodule

private struct DaylightInvisibility extends array
    implement DaylightInvisibilityConfig

    private  static group tentGroup             = null
    private  static real  INVISIBILITY_DUR      = 0.0

    //  ======================================================
    //          Event callback functions
    //  ======================================================
    private static method onEnter takes nothing returns nothing
        if (GetUnitAbilityLevel(StructureHandler.structure, ABILITY_ID) == 0) then
            return
        endif
        call GroupAddUnit(tentGroup, StructureHandler.structure)
        if (not DNCycle.isDay) then
            call BlzUnitDisableAbility(StructureHandler.structure, ABILITY_ID, true, true)
        else
            call VisibilityManager.unitApply(StructureHandler.structure, TINT_ALPHA_START, TINT_ALPHA_END, INVISIBILITY_DUR)
        endif
    endmethod

    private static method onLeave takes nothing returns nothing
        call GroupRemoveUnit(tentGroup, StructureHandler.structure)
    endmethod

    private static method onDaylight takes nothing returns nothing
        local integer i         = 0
        local integer n         = BlzGroupGetSize(tentGroup)
        local boolean enable    = (not DNCycle.isDay)
        local unit temp
        loop
            exitwhen i >= n
            set temp    = BlzGroupUnitAt(tentGroup, i)
            if (not enable) then
                call VisibilityManager.unitApply(temp, TINT_ALPHA_START, TINT_ALPHA_END, INVISIBILITY_DUR)
            else
                call VisibilityManager.unitApply(temp, TINT_ALPHA_END, TINT_ALPHA_START, INVISIBILITY_DUR)
            endif
            call BlzUnitDisableAbility(temp, ABILITY_ID, enable, enable)
            set i       = i + 1
        endloop
    endmethod
    //  ======================================================
    //          Initializing function
    //  ======================================================
    private static method initInviDur takes nothing returns nothing
        local Dummy dummy       = Dummy.request(Player(PLAYER_NEUTRAL_PASSIVE), 0.0, 0.0, 0.0)
        call dummy.addAbil(ABILITY_ID)
        set INVISIBILITY_DUR    = BlzGetAbilityRealLevelField(BlzGetUnitAbility(dummy.dummy, ABILITY_ID), ABILITY_RLF_DURATION_NORMAL, 0)
        call dummy.removeAbil(ABILITY_ID)
        call dummy.recycle()
    endmethod

    private static method onInit takes nothing returns nothing
        set tentGroup   =   CreateGroup()
        call thistype.initInviDur()
        call StructureHandler.ON_ENTER.register(function thistype.onEnter)
        call StructureHandler.ON_LEAVE.register(function thistype.onLeave)
        call DNCycle.ON_DAY.register(function thistype.onDaylight)
        call DNCycle.ON_NIGHT.register(function thistype.onDaylight)
    endmethod
endstruct

endscope