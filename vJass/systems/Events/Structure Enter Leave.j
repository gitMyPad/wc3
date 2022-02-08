library StructureEnterLeave requires /*

    --------------------------------------
    */  UnitDex, EventListener, Init    /*
    --------------------------------------

    ------------------------------
    */  Table, UnitAuxEvents    /*
    ------------------------------

     ----------------------------------------------------------------
    |
    |       StructureEnterLeave
    |           - v.1.1.0
    |
    |----------------------------------------------------------------
    |
    |   A snippet that handles the moments when a structure is placed,
    |   constructed, or destroyed. The underlying system assumes that
    |   the structure is already available for use when its own ENTER
    |   event runs, hence why it cannot fully rely on the events provided
    |   by UnitDex.
    |
    |----------------------------------------------------------------
    |
    |   API:
    |
    |   class StructureHandler {
    |   ===============================================
    |       readonly static EventListener ON_ENTER
    |           - Runs when a structure has finished construction
    |             or is created via CreateUnit.
    |
    |       readonly static EventListener ON_LEAVE
    |           - Runs when a structure is removed via destruction
    |             or RemoveUnit.
    |
    |       readonly static unit structure
    |           - The current affected building in either event.
    |
    |   ===============================================
    |    -----------------------
    |   |   Added in v.1.1.0    |
    |    -----------------------
    |       static method isConstructing(unit whichStructure) -> bool
    |           - Returns true if the unit is still being constructed.
    |   }
     ----------------------------------------------------------------
*/

private struct StructureHandlerData extends array
    readonly static timer       eventTimer      = null
    readonly static thistype    current         = 0
    unit            structure
    EventListener   whichEvent

    static method pop takes nothing returns nothing
        set current.structure                   = null
        set current.whichEvent                  = 0
        set current                             = integer(current) - 1
    endmethod
    static method push takes unit whichStructure, EventListener whichEvent returns thistype
        set current                             = integer(current) + 1
        set current.structure                   = whichStructure
        set current.whichEvent                  = whichEvent
        return current
    endmethod
    static method stop takes nothing returns nothing
        if (current == 0) then
            call PauseTimer(eventTimer)
        endif
    endmethod
    static method dequeue takes nothing returns nothing
        loop
            exitwhen (integer(current) <= 0)
            call thistype.pop()
        endloop
    endmethod
    static method start takes real dur, code callback returns nothing
        if (current == 1) then
            call TimerStart(eventTimer, dur, false, callback)
        endif
    endmethod
    private static method init takes nothing returns nothing
        set eventTimer                          = CreateTimer()
    endmethod
    implement Init
endstruct

struct StructureHandler extends array
    readonly static EventListener ON_ENTER      = 0
    readonly static EventListener ON_START      = 0
    readonly static EventListener ON_LEAVE      = 0
    readonly static EventListener ON_CANCEL     = 0
    readonly static EventListener ON_DEATH      = 0
    private  static Table constructMap          = 0

    readonly static unit  structure             = null

    private static method throwEvent takes unit whichUnit, EventListener whichEvent returns nothing
        local unit prevStruct       = structure
        set structure               = whichUnit
        call whichEvent.run()
        set structure               = prevStruct
        set prevStruct              = null
    endmethod

    private static method clearQueueEvents takes nothing returns nothing
        local StructureHandlerData object   = 1
        local integer unitHandle            = 0
        loop
            exitwhen (integer(object) > integer(StructureHandlerData.current))
            set unitHandle  = GetHandleId(object.structure)
            if (not constructMap.boolean.has(unitHandle)) then
                set constructMap.boolean[unitHandle]  = false
                call thistype.throwEvent(object.structure, object.whichEvent)
            endif
            set object                      = integer(object) + 1
        endloop
        call StructureHandlerData.dequeue()
    endmethod

    //  ====================================================
    //              Event callback functions.
    //  ====================================================
    private static method onConstructHandler takes nothing returns nothing
        local eventid evID          = GetTriggerEventId()
        local integer unitHandle    = 0
        local unit    building      = GetTriggerUnit()
        set unitHandle              = GetHandleId(building)
        if (evID == EVENT_PLAYER_UNIT_CONSTRUCT_START) then
            set constructMap.boolean[unitHandle]  = true
            call thistype.throwEvent(building, ON_START)
        else
            set constructMap.boolean[unitHandle]  = false
            call thistype.throwEvent(building, ON_ENTER)
        endif
        set building    = null
    endmethod

    private static method onStructureEnter takes nothing returns nothing
        local unit    building      = GetIndexedUnit()
        local integer unitHandle    = GetHandleId(building)
        if (IsUnitType(building, UNIT_TYPE_STRUCTURE)) and /*
        */ (not constructMap.boolean.has(unitHandle)) then
            //  Building was placed via CreateUnit
            call StructureHandlerData.push(building, ON_ENTER)
            call StructureHandlerData.start(0.0, function thistype.clearQueueEvents)
        endif
        set building    = null
    endmethod

    private static method onStructureLeave takes nothing returns nothing
        local unit    building      = GetIndexedUnit()
        local integer unitHandle    = GetHandleId(building)
        if (constructMap.boolean.has(unitHandle)) then
            //  Building was detected. Throw event.
            call constructMap.boolean.remove(unitHandle)
            call thistype.throwEvent(building, ON_LEAVE)
        endif
        set building    = null
    endmethod

    private static method onCancelHandler takes nothing returns nothing
        local eventid evID                      = GetTriggerEventId()
        local unit    building                  = GetTriggerUnit()
        local integer unitHandle                = GetHandleId(building)
        set constructMap.boolean[unitHandle]  = false
        call thistype.throwEvent(building, ON_CANCEL)
        set building                            = null
    endmethod

    private static method onStructureDeath takes nothing returns nothing
        //  Don't throw an event for units. Reserved for structures.
        if (not constructMap.boolean.has(GetHandleId(UnitAuxHandler.unit))) then
            return
        endif
        call thistype.throwEvent(UnitAuxHandler.unit, ON_DEATH)
    endmethod

    //  ====================================================
    //              Initializing functions.
    //  ====================================================
    private static method initVars takes nothing returns nothing
        set ON_ENTER                = EventListener.create()
        set ON_START                = EventListener.create()
        set ON_LEAVE                = EventListener.create()
        set ON_DEATH                = EventListener.create()
        set ON_CANCEL               = EventListener.create()
        set constructMap            = Table.create()
    endmethod

    private static method initEvents takes nothing returns nothing
        local trigger trig          = CreateTrigger()
        local trigger cancelTrig    = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_CONSTRUCT_START)
        call TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
        call TriggerRegisterAnyUnitEventBJ(cancelTrig, EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL)
        call TriggerAddCondition(trig, Condition(function thistype.onConstructHandler))
        call TriggerAddCondition(cancelTrig, Condition(function thistype.onCancelHandler))
        call OnUnitIndex(function thistype.onStructureEnter)
        call OnUnitDeindex(function thistype.onStructureLeave)
        call UnitAuxHandler.ON_DEATH.register(function thistype.onStructureDeath)
    endmethod

    private static method init takes nothing returns nothing
        call thistype.initVars()
        call thistype.initEvents()
    endmethod
    implement Init
endstruct

endlibrary