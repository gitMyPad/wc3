library DNCycle requires EventListener, Init    /*

     --------------------------
    |
    |   DNCycle
    |
    |--------------------------
    |
    |   API:
    |
    |   class DNCycle {
    |   =======================
    |       readonly static EventListener ON_DAY
    |           - EventListener that triggers on the onset
    |             of dawn.
    |
    |       readonly static EventListener ON_NIGHT
    |           - EventListener that triggers on the onset
    |             of dusk.
    |
    |       readonly static boolean isDay
    |           - A flag telling us if it is day or night
    |             if one can't be bothered to use the
    |             GetFloatGameState native.
    |   =======================
    }
*/

struct DNCycle extends array
    readonly static constant real DAY_TIME      = 6.00
    readonly static constant real NIGHT_TIME    = 18.00
    readonly static EventListener ON_DAY        = 0
    readonly static EventListener ON_NIGHT      = 0
    readonly static boolean       isDay         = false

    private static method initVars takes nothing returns nothing
        set ON_DAY      = EventListener.create()
        set ON_NIGHT    = EventListener.create()
    endmethod

    private static method onTimeChange takes nothing returns nothing
        local real time         = R2I(GetFloatGameState(GAME_STATE_TIME_OF_DAY) + 0.5)
        local boolean daytime   = ((time >= DAY_TIME) and (time < NIGHT_TIME))
        if (isDay == daytime) then
            return
        endif
        set isDay   = daytime
        if (isDay) then
            call ON_DAY.run()
        else
            call ON_NIGHT.run()
        endif
    endmethod

    private static method initEvents takes nothing returns nothing
        local trigger dncTrig   = CreateTrigger()
        call TriggerRegisterGameStateEvent(dncTrig, GAME_STATE_TIME_OF_DAY, LESS_THAN_OR_EQUAL, DAY_TIME)
        call TriggerRegisterGameStateEvent(dncTrig, GAME_STATE_TIME_OF_DAY, GREATER_THAN_OR_EQUAL, DAY_TIME)
        call TriggerRegisterGameStateEvent(dncTrig, GAME_STATE_TIME_OF_DAY, GREATER_THAN_OR_EQUAL, NIGHT_TIME)
        call TriggerAddCondition(dncTrig, Condition(function thistype.onTimeChange))
    endmethod

    private static method init takes nothing returns nothing
        call thistype.initVars()
        call thistype.initEvents()
    endmethod
    implement Init
endstruct

endlibrary