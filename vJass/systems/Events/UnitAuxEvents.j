library UnitAuxEvents requires /*

    ------------------
    */  UnitDex     /*
    ------------------

    ----------------------
    */  EventListener   /*
    ----------------------

    --------------
    */  Init    /*
    --------------

    ------------------
    */  Flagbits    /*
    ------------------

    ----------------------
    */  WorldBounds     /*
    ----------------------

     -------------------------------------------------------------------
    |
    |   UnitExtraEvents
    |       v.1.0.0
    |
    |-------------------------------------------------------------------
    |

*/

globals
    private constant integer DETECT_ABIL_ID = 'uDey'
    private constant integer DETECT_ORDER   = 852056    // undefend
endglobals

//  For debug purposes only.
public function FourCC takes integer value returns string
    local string charMap = "..................................!.#$%&'()*+,-./0123456789:;<=>.@ABCDEFGHIJKLMNOPQRSTUVWXYZ[.]^_`abcdefghijklmnopqrstuvwxyz{|}~................................................................................................................................."
    local string result = ""
    local integer remainingValue = value
    local integer charValue
    local integer byteno

    set byteno = 0
    loop
        set charValue = ModuloInteger(remainingValue, 256)
        set remainingValue = remainingValue / 256
        set result = SubString(charMap, charValue, charValue + 1) + result

        set byteno = byteno + 1
        exitwhen byteno == 4
    endloop
    return result
endfunction

private module UnitAuxOps
    static method operator unit takes nothing returns unit
        return unitA[index]
    endmethod
    static method operator curTransport takes nothing returns unit
        return transportA[index]
    endmethod
    static method operator prevTransformID takes nothing returns integer
        return prevUnitID[GetUnitId(unitA[index])]
    endmethod
    static method operator curTransformID takes nothing returns integer
        return GetUnitTypeId(unitA[index])
    endmethod
    static method operator [] takes unit whichUnit returns thistype
        return GetUnitId(whichUnit)
    endmethod

    method operator isDead takes nothing returns boolean
        return IsFlagSet(statusFlags[this], STATUS_DEAD)
    endmethod
    method operator isTransforming takes nothing returns boolean
        return IsFlagSet(statusFlags[this], STATUS_TRANSFORMING)
    endmethod
    method operator wasKilled takes nothing returns boolean
        return IsFlagSet(statusFlags[this], STATUS_KILLED)
    endmethod
    method operator isTransported takes nothing returns boolean
        return IsFlagSet(statusFlags[this], STATUS_TRANSPORTED)
    endmethod
    method operator transportCount takes nothing returns integer
        return BlzGroupGetSize(this.transportGroup)
    endmethod
endmodule

struct UnitAuxHandler extends array
    readonly static EventListener       ON_TRANSFORM        = 0
    readonly static EventListener       ON_DEATH            = 0
    readonly static EventListener       ON_RESURRECT        = 0
    readonly static EventListener       ON_LOAD             = 0
    readonly static EventListener       ON_UNLOAD           = 0

    //  While STATUS_DEAD and STATUS_KILLED are similar,
    //  STATUS_DEAD is flagged when the unit is considered dead
    //  by UnitAlive(), whereas STATUS_KILLED is flagged when
    //  the unit triggers a native EVENT_PLAYER_UNIT_DEATH event.
    private  static constant integer    STATUS_USED         = 1
    readonly static constant integer    STATUS_DEAD         = 2
    readonly static constant integer    STATUS_KILLED       = 4
    readonly static constant integer    STATUS_TRANSFORMING = 8
    readonly static constant integer    STATUS_TRANSPORTED  = 16
    
    private  static integer array       statusFlags
    readonly static integer array       prevUnitID

    private  static integer             index               = 0
    private  static unit array          unitA
    private  static unit array          transportA
    
    readonly unit   transport
    readonly group  transportGroup

    //  ENUM types for system handling of queued instance information
    private  static constant integer    QUEUE_RESTORE_ABIL  = 1
    private  static constant integer    QUEUE_THROW_DEATH   = 2
    private  static boolean             queueInCallback     = false
    private  static timer               queueDetectTimer    = CreateTimer()
    private  static integer             queueIndex          = 0
    private  static integer             queueSIndex         = 0
    private  static integer array       queueInfo
    private  static unit array          queueUnitA

    implement UnitAuxOps

    //  ========================================================
    //                  Event Handling functions
    //  ========================================================
    private static method releaseEvent takes nothing returns nothing
        set unitA[index]    = null
        set index           = index - 1
    endmethod
    
    private static method prepEvent takes unit source returns nothing
        set index           = index + 1
        set unitA[index]    = source
    endmethod

    private static method throwEvent takes unit source, EventListener whichEvent returns nothing
        call thistype.prepEvent(source)
        call whichEvent.run()
        call thistype.releaseEvent()
    endmethod

    //  ========================================================
    //                  System functions
    //  ========================================================
    private static method enqueueActions takes nothing returns nothing
        local integer i             = 1
        local integer queueID       = 0
        set queueInCallback         = true
        loop
            exitwhen i > queueIndex
            set queueID             = GetUnitId(queueUnitA[i])
            if queueInfo[i] == QUEUE_RESTORE_ABIL then
                call thistype.throwEvent(queueUnitA[i], ON_TRANSFORM)
                set statusFlags[queueID]    = UnsetFlag(statusFlags[queueID], STATUS_TRANSFORMING)
                set prevUnitID[queueID]     = GetUnitTypeId(queueUnitA[i])
                call UnitAddAbility(queueUnitA[i], DETECT_ABIL_ID)

            elseif queueInfo[i] == QUEUE_THROW_DEATH then
                call throwEvent(queueUnitA[i], ON_DEATH)
            endif
            set i                   = i + 1
        endloop
        set queueInCallback         = false
        set queueIndex              = 0
        loop
            exitwhen queueIndex >= queueSIndex
            set queueIndex                      = queueIndex + 1
            set queueInfo[queueIndex]           = queueInfo[queueIndex + 0x4000]
            set queueUnitA[queueIndex]          = queueUnitA[queueIndex + 0x4000]
            set queueInfo[queueIndex + 0x4000]  = 0
            set queueUnitA[queueIndex + 0x4000] = null
        endloop
        set queueSIndex             = 0
        if (queueIndex != 0) then
            call TimerStart(queueDetectTimer, 0.0, false, function thistype.enqueueActions)
        endif
    endmethod

    private static method incrementQueue takes nothing returns nothing
        if (queueInCallback) then
            set queueSIndex         = queueSIndex + 1
        endif
        set queueIndex              = queueIndex + 1
        if (queueIndex == 1) then
            call TimerStart(queueDetectTimer, 0.0, false, function thistype.enqueueActions)
        endif
    endmethod
    private static method queueDetectAbility takes unit source returns nothing
        call thistype.incrementQueue()
        if (queueInCallback) then
            set queueUnitA[queueSIndex + 0x4000]    = source
            set queueInfo[queueSIndex + 0x4000]     = QUEUE_RESTORE_ABIL
            return
        endif
        set queueUnitA[queueIndex]  = source
        set queueInfo[queueIndex]   = QUEUE_RESTORE_ABIL
    endmethod
    private static method queueDeathEvent takes unit source returns nothing
        call thistype.incrementQueue()
        if (queueInCallback) then
            set queueUnitA[queueSIndex + 0x4000]    = source
            set queueInfo[queueSIndex + 0x4000]     = QUEUE_THROW_DEATH
            return
        endif
        set queueUnitA[queueIndex]  = source
        set queueInfo[queueIndex]   = QUEUE_THROW_DEATH
    endmethod

    //  ========================================================
    //                  Event Responses
    //  ========================================================
    private static method onUndefendOrder takes nothing returns nothing
        local unit source
        local integer srcID
        local boolean isAlive
        if (GetIssuedOrderId() != DETECT_ORDER) then
            return
        endif
        set source          = GetTriggerUnit()
        set srcID           = GetUnitId(source)
        //  Since this will run as well, check if the statusFlags
        //  of the unit are defined.
        if (statusFlags[srcID] == 0) then
            set source      = null
            return
        endif
        //  Check for transformation.
        if (GetUnitAbilityLevel(source, DETECT_ABIL_ID) == 0) and /*
        */ (GetUnitTypeId(source) != prevUnitID[srcID]) and /*
        */ (not IsFlagSet(statusFlags[srcID], STATUS_TRANSFORMING)) then
            set statusFlags[srcID]  = SetFlag(statusFlags[srcID], STATUS_TRANSFORMING)
            call thistype.queueDetectAbility(source)
            //  Hopefully, this won't trigger a death event as well.
            return
        endif
        //  Check if unit is alive
        set isAlive         = UnitAlive(source)
        if ((not isAlive) and (not IsFlagSet(statusFlags[srcID], STATUS_DEAD))) then
            //  The unit has died.
            set statusFlags[srcID]  = SetFlag(statusFlags[srcID], STATUS_DEAD)
            call thistype.queueDeathEvent(source)

        elseif ((isAlive) and (IsFlagSet(statusFlags[srcID], STATUS_DEAD))) then
            set statusFlags[srcID]  = UnsetFlag(statusFlags[srcID], STATUS_DEAD + STATUS_KILLED)
            call thistype.throwEvent(source, ON_RESURRECT)
        endif
        set source          = null
    endmethod
    private static method onDeathEvent takes nothing returns nothing
        local unit source
        local integer srcID
        local boolean isAlive
        set source              = GetTriggerUnit()
        set srcID               = GetUnitId(source)
        //  Since this will run as well, check if the statusFlags
        //  of the unit are defined.
        if (statusFlags[srcID] == 0) then
            set source          = null
            return
        endif
        set statusFlags[srcID]  = SetFlag(statusFlags[srcID], STATUS_KILLED)
        set source              = null
    endmethod
    private static method onTransportEvent takes nothing returns nothing
        local unit passenger                = GetTriggerUnit()
        local unit vehicle                  = GetTransportUnit()
        local integer  passID               = GetUnitId(passenger)
        local thistype vehicleID            = thistype[vehicle]

        set thistype[passenger].transport   = vehicle
        if (vehicleID.transportGroup == null) then
            set vehicleID.transportGroup    = CreateGroup()
        endif
        call GroupAddUnit(vehicleID.transportGroup, passenger)
        set statusFlags[passID]             = SetFlag(statusFlags[passID], STATUS_TRANSPORTED)
        //  Ripped from Bribe's version of jesus4lyf's Transport
        call SetUnitX(passenger, WorldBounds.maxX)
        call SetUnitY(passenger, WorldBounds.maxY)

        //  Throw event
        call thistype.prepEvent(passenger)
        set transportA[index]               = vehicle
        call ON_LOAD.run()
        set transportA[index]               = null
        call thistype.releaseEvent()

        set vehicle                         = null
        set passenger                       = null
    endmethod
    private static method onUnloadEvent takes nothing returns nothing
        local unit passenger                = GetTriggerUnit()
        local unit vehicle
        local integer passID                = GetUnitId(passenger)
        local thistype vehicleID            = 0

        if (not IsFlagSet(statusFlags[passID], STATUS_TRANSPORTED)) then
            set passenger                   = null
            return
        endif
        set vehicle                         = thistype(passID).transport
        set vehicleID                       = thistype[vehicle]
        call GroupRemoveUnit(vehicleID.transportGroup, passenger)
        if (vehicleID.transportCount == 0) then
            call DestroyGroup(vehicleID.transportGroup)
            set vehicleID.transportGroup    = null
        endif
        set statusFlags[passID]             = UnsetFlag(statusFlags[passID], STATUS_TRANSPORTED)
        set thistype(passID).transport      = null

        call thistype.prepEvent(passenger)
        set transportA[index]               = vehicle
        call ON_UNLOAD.run()
        set transportA[index]               = null
        call thistype.releaseEvent()

        set passenger                       = null
        set vehicle                         = null
    endmethod
    private static method onForcedUnloadEvent takes nothing returns nothing
        local unit vehicle                  = GetIndexedUnit()
        local unit passenger
        local thistype vehicleID            = GetIndexedUnitId()
        local integer passID                = 0

        if (IsFlagSet(statusFlags[vehicleID], STATUS_TRANSPORTED)) then
            set passenger                   = vehicle
            set passID                      = integer(vehicleID)
            set vehicle                     = vehicleID.transport
            set vehicleID.transport         = null
            set vehicleID                   = thistype[vehicle]
            
            //  The vehicle has become the passenger
            set statusFlags[passID]         = UnsetFlag(statusFlags[passID], STATUS_TRANSPORTED)
            call GroupRemoveUnit(vehicleID.transportGroup, passenger)
            if (vehicleID.transportCount == 0) then
                call DestroyGroup(vehicleID.transportGroup)
                set vehicleID.transportGroup    = null
            endif

            //  Throw event here.
            call thistype.prepEvent(passenger)
            set transportA[index]           = vehicle
            call ON_UNLOAD.run()
            set transportA[index]           = null
            call thistype.releaseEvent()

            //  Reset variables
            set vehicle                     = passenger
            set vehicleID                   = thistype(passID)
            set passenger                   = null
            set passID                      = 0
        endif

        set statusFlags[vehicleID]          = 0
        if (vehicleID.transportCount == 0) then
            set vehicle                     = null
            return
        endif
        call thistype.prepEvent(vehicle)
        set transportA[index]               = vehicle
        loop
            set passenger                   = FirstOfGroup(vehicleID.transportGroup)
            call GroupRemoveUnit(vehicleID.transportGroup, passenger)
            exitwhen (passenger == null)

            set passID                      = GetUnitId(passenger)
            set statusFlags[passID]         = UnsetFlag(statusFlags[passID], STATUS_TRANSPORTED)
            set thistype(passID).transport  = null
            set unitA[index]                = passenger

            call ON_UNLOAD.run()
        endloop
        set transportA[index]               = null
        call thistype.releaseEvent()

        call DestroyGroup(vehicleID.transportGroup)
        set vehicleID.transportGroup        = null
        set vehicle                         = null
        set passenger                       = null
    endmethod
    private static method onUnitLeave takes nothing returns nothing
        local integer id        = GetIndexedUnitId()
        set statusFlags[id]     = 0
        set prevUnitID[id]      = 0
    endmethod
    private static method onUnitEnter takes nothing returns nothing
        local unit u            = GetIndexedUnit()
        local integer id        = GetUnitId(u)
        set statusFlags[id]     = STATUS_USED
        set prevUnitID[id]      = GetUnitTypeId(u)
        //  Unit was created as a corpse.
        call UnitAddAbility(u, DETECT_ABIL_ID)
        if (not UnitAlive(u)) then
            set statusFlags[id] = SetFlag(statusFlags[id], STATUS_DEAD)
        endif
        set u                   = null
    endmethod

    //  ========================================================
    //                  Initializing functions
    //  ========================================================
    private static method initDetector takes nothing returns nothing
        local trigger orderTrig     = CreateTrigger()
        local trigger deathTrig     = CreateTrigger()
        local trigger transTrig     = CreateTrigger()
        local trigger unloadTrig    = CreateTrigger()        
        call TriggerRegisterAnyUnitEventBJ(orderTrig, EVENT_PLAYER_UNIT_ISSUED_ORDER)
        call TriggerRegisterAnyUnitEventBJ(deathTrig, EVENT_PLAYER_UNIT_DEATH)
        call TriggerRegisterAnyUnitEventBJ(transTrig, EVENT_PLAYER_UNIT_LOADED)
        call TriggerRegisterEnterRegion(unloadTrig, WorldBounds.worldRegion, null)
        call TriggerAddCondition(orderTrig, Condition(function thistype.onUndefendOrder))
        call TriggerAddCondition(deathTrig, Condition(function thistype.onDeathEvent))
        call TriggerAddCondition(transTrig, Condition(function thistype.onTransportEvent))
        call TriggerAddCondition(unloadTrig, Condition(function thistype.onUnloadEvent))
        call OnUnitDeindex(function thistype.onForcedUnloadEvent)
    endmethod
    private static method initVars takes nothing returns nothing
        set ON_TRANSFORM    = EventListener.create()
        set ON_DEATH        = EventListener.create()
        set ON_RESURRECT    = EventListener.create()
        set ON_LOAD         = EventListener.create()
        set ON_UNLOAD       = EventListener.create()
    endmethod
    private static method init takes nothing returns nothing
        call OnUnitIndex(function thistype.onUnitEnter)
        call OnUnitDeindex(function thistype.onUnitLeave)
        call thistype.initVars()
        call thistype.initDetector()
    endmethod
    implement Init
endstruct

endlibrary