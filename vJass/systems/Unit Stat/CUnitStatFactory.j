library CustomUnitStatFactory requires /*

    --------------
    */  Init    /*
    --------------

    --------------
    */  Alloc   /*
    --------------

    --------------
    */  ListT   /*
    --------------

    ------------------
    */  UnitDex     /*
    ------------------

    ----------------------
    */  EventListener   /*
    ----------------------
*/

globals
    private integer requestFlag                     = 0
    private EventListener onEnterHandler            = 0
    private EventListener onLeaveHandler            = 0
    //  Modifier types
    constant integer STAT_ADD                       = 1
    constant integer STAT_MULT                      = 2
    //  Request types
    public constant integer REQUEST_DIRECT_AMOUNT   = 1
    public constant integer REQUEST_MODIFY_ATTR     = 2
    public constant integer REQUEST_CHANGE_COUNTER  = 4
    //  Event types
    private constant integer EVENT_STAT_MODIFY      = 1
    private constant integer EVENT_STAT_ACTIVATE    = 2
    private constant integer EVENT_STAT_DEACTIVATE  = 4
endglobals

//  ================================================================
private struct CUnitStatHandler extends array
    //  This is defined through the generated module below.
    static EventResponder array modifyResponse
    static EventResponder array activationResponse
    static EventResponder array deactivationResponse

    //  Modify event values
    readonly static integer eventIndex          = 0
    readonly static integer array eventType
    readonly static unit array curUnit
    readonly static real array prevAmt
    readonly static real array curAmt
    readonly static CStat array curStat

    //  Activation and deactivation event values
    readonly static boolean array isActivating

    //  Called by the operator CStat:amount=
    static method prepModifyHandler takes unit whichUnit, real prev, real cur, CStat stat returns nothing
        set eventIndex              = eventIndex + 1
        set eventType[eventIndex]   = EVENT_STAT_MODIFY
        set curUnit[eventIndex]     = whichUnit
        set prevAmt[eventIndex]     = prev
        set curAmt[eventIndex]      = cur
        set curStat[eventIndex]     = stat
    endmethod
    //  Called by the method incActiveCounter and decActiveCounter.
    static method prepActivationHandler takes unit whichUnit, boolean state, CStat stat returns nothing
        set eventIndex                  = eventIndex + 1
        set isActivating[eventIndex]    = state
        set curUnit[eventIndex]         = whichUnit
        set curStat[eventIndex]         = stat
        if (state) then
            set eventType[eventIndex]   = EVENT_STAT_ACTIVATE
        else
            set eventType[eventIndex]   = EVENT_STAT_DEACTIVATE
        endif
    endmethod
    static method callModifyHandler takes integer modClass returns nothing
        call modifyResponse[modClass].run()
    endmethod
    static method callActivationHandler takes integer modClass returns nothing
        call activationResponse[modClass].run()
    endmethod
    static method callDeactivationHandler takes integer modClass returns nothing
        call deactivationResponse[modClass].run()
    endmethod
    static method releaseHandler takes nothing returns nothing
        set eventIndex  = IMaxBJ(eventIndex - 1, 0)
    endmethod

    private static method onEnter takes nothing returns nothing
        call onEnterHandler.run()
    endmethod
    private static method onLeave takes nothing returns nothing
        call onLeaveHandler.run()
    endmethod
    private static method init takes nothing returns nothing
        set onEnterHandler  = EventListener.create()
        set onLeaveHandler  = EventListener.create()
        call OnUnitIndex(function thistype.onEnter)
        call OnUnitDeindex(function thistype.onLeave)
    endmethod
    implement Init
endstruct

//  ================================================================
private function IsFlagRequested takes integer flag returns boolean
    return BlzBitAnd(requestFlag, flag) != 0
endfunction

//  ================================================================
//  While technically public functions, these should not be used
//  manually at any point, since the system requires that these
//  functions be accessible from the module side, which cannot be
//  possible when such functions are declared private.
//  ================================================================
public function AssignModifuncToClass takes integer classID, code callback returns nothing
    set CUnitStatHandler.modifyResponse[classID]        = EventResponder.create(callback)
endfunction
public function AssignActifuncToClass takes integer classID, code callback returns nothing
    set CUnitStatHandler.activationResponse[classID]    = EventResponder.create(callback)
endfunction
public function AssignDeactifuncToClass takes integer classID, code callback returns nothing
    set CUnitStatHandler.deactivationResponse[classID]  = EventResponder.create(callback)
endfunction
public function GetCurrentUnit takes nothing returns unit
    return CUnitStatHandler.curUnit[CUnitStatHandler.eventIndex]
endfunction
public function GetPrevAmount takes nothing returns real
    return CUnitStatHandler.prevAmt[CUnitStatHandler.eventIndex]
endfunction
public function GetCurrentAmount takes nothing returns real
    return CUnitStatHandler.curAmt[CUnitStatHandler.eventIndex]
endfunction
public function GetCurrentStat takes nothing returns CStat
    return CUnitStatHandler.curStat[CUnitStatHandler.eventIndex]
endfunction
public function GetStatActivationState takes nothing returns boolean
    return CUnitStatHandler.isActivating[CUnitStatHandler.eventIndex]
endfunction
public function SetRequestFlag takes integer flag returns nothing
    set requestFlag = BlzBitOr(requestFlag, flag)
endfunction
public function UnsetRequestFlag takes integer flag returns nothing
    set requestFlag = BlzBitAnd(requestFlag, -flag - 1)
endfunction
public function RegisterEnterHandler takes code func returns nothing
    call onEnterHandler.register(func)
endfunction
public function RegisterLeaveHandler takes code func returns nothing
    call onLeaveHandler.register(func)
endfunction
//  ================================================================

//  ================================================================
//! runtextmacro DEFINE_LIST("", "StatList", "integer")
struct CStat extends array
    implement AllocT

    private static TableArray hashMap   = 0
    method operator amount takes nothing returns real
        if (hashMap[3].integer[this] > 0) then
            return 0.0
        endif
        return hashMap[0].real[this]
    endmethod
    method operator modType takes nothing returns integer
        return hashMap[1].integer[this]
    endmethod
    private method operator activeCounter takes nothing returns integer
        return hashMap[2].integer[this]
    endmethod
    private method operator zeroCounter takes nothing returns integer
        return hashMap[3].integer[this]
    endmethod
    method operator owner takes nothing returns unit
        return hashMap[4].unit[this]
    endmethod
    method operator listPtr takes nothing returns StatListItem
        return hashMap[5].integer[this]
    endmethod
    method operator modClass takes nothing returns integer
        return hashMap[6].integer[this]
    endmethod
    method operator amount= takes real value returns nothing
        if (value == this.amount) then
            return
        endif
        //  If REQUEST_DIRECT_AMOUNT is flagged, that means
        //  the handlers that observe any changes will not
        //  be notified.

        //  Otherwise, if the modifier is suppressed via
        //  activate(false), any attempts at changing
        //  the value will not reflect on the target unit,
        //  but will still be honored.
        if ((IsFlagRequested(REQUEST_DIRECT_AMOUNT)) or /*
        */  (hashMap[2].integer[this] <= 0)) then
            set hashMap[0].real[this]       = value
            return
        endif
        call CUnitStatHandler.prepModifyHandler(hashMap[4].unit[this], hashMap[0].real[this], value, this)
        set hashMap[0].real[this]       = value
        call CUnitStatHandler.callModifyHandler(hashMap[6].integer[this])
        call CUnitStatHandler.releaseHandler()
    endmethod
    method operator modType= takes integer value returns nothing
        if (not IsFlagRequested(REQUEST_MODIFY_ATTR)) then
            return
        endif
        set hashMap[1].integer[this]    = value
    endmethod
    method operator activeCounter= takes integer value returns nothing
        if (not IsFlagRequested(REQUEST_MODIFY_ATTR)) then
            return
        endif
        set hashMap[2].integer[this]    = value
    endmethod
    method operator zeroCounter= takes integer value returns nothing
        if (not IsFlagRequested(REQUEST_CHANGE_COUNTER)) then
            return
        endif
        set hashMap[3].integer[this]    = value
    endmethod
    method operator owner= takes unit value returns nothing
        if (not IsFlagRequested(REQUEST_MODIFY_ATTR)) then
            return
        endif
        set hashMap[4].unit[this]       = value
    endmethod
    method operator listPtr= takes StatListItem value returns nothing
        if (not IsFlagRequested(REQUEST_MODIFY_ATTR)) then
            return
        endif
        set hashMap[5].integer[this]    = value
    endmethod
    method operator modClass= takes integer whichClass returns nothing
        if (not IsFlagRequested(REQUEST_MODIFY_ATTR)) then
            return
        endif
        set hashMap[6].integer[this]    = whichClass
    endmethod

    private method incActiveCounter takes nothing returns nothing
        local integer value             = hashMap[2].integer[this] + 1
        set hashMap[2].integer[this]    = value
        if (value == 1) then
            call CUnitStatHandler.prepActivationHandler(hashMap[4].unit[this], true, this)
            call CUnitStatHandler.callActivationHandler(hashMap[6].integer[this])
            call CUnitStatHandler.releaseHandler()
        endif
    endmethod
    private method decActiveCounter takes nothing returns nothing
        local integer value             = hashMap[2].integer[this] - 1
        set hashMap[2].integer[this]    = value
        //  Call activation and deactivation handlers.
        if (value == 0) then
            call CUnitStatHandler.prepActivationHandler(hashMap[4].unit[this], false, this)
            call CUnitStatHandler.callDeactivationHandler(hashMap[6].integer[this])
            call CUnitStatHandler.releaseHandler()
        endif
    endmethod
    method nullifiesProduct takes nothing returns boolean
        return this.zeroCounter > 0
    endmethod
    method isActive takes nothing returns boolean
        return this.activeCounter > 0
    endmethod

    method activate takes boolean flag returns nothing
        if (flag) then
            call this.incActiveCounter()
        else
            call this.decActiveCounter()
        endif
    endmethod
    method nullify takes boolean flag returns nothing
        if (not IsFlagRequested(REQUEST_CHANGE_COUNTER)) then
            return
        endif
        if (flag) then
            set hashMap[3].integer[this]    = hashMap[3].integer[this] + 1
        else
            set hashMap[3].integer[this]    = hashMap[3].integer[this] - 1
        endif
    endmethod

    method destroy takes nothing returns nothing
        if (this.modType == 0) then
            return
        endif
        call SetRequestFlag(REQUEST_MODIFY_ATTR)
        /*
        if (this.modType == STAT_ADD) then
            set this.amount = 0.0
        else
            set this.amount = 1.0
        endif
        */
        //  if (this.activeCounter > 0)
        if (hashMap[2].integer[this] > 0) then
            set hashMap[2].integer[this]  = 1
            call this.decActiveCounter()
        endif

        //  Clear out all mapped data.
        call hashMap[6].integer.remove(this)
        call hashMap[5].integer.remove(this)
        call hashMap[4].unit.remove(this)
        call hashMap[3].integer.remove(this)
        call hashMap[2].integer.remove(this)
        call hashMap[1].integer.remove(this)
        call hashMap[0].real.remove(this)
        call this.deallocate()
        call UnsetRequestFlag(REQUEST_MODIFY_ATTR)
    endmethod

    static method create takes unit whichUnit, integer manifest returns thistype
        local thistype this     = thistype.allocate()
        call SetRequestFlag(REQUEST_DIRECT_AMOUNT + REQUEST_MODIFY_ATTR)
        if (manifest == STAT_ADD) then
            set this.amount     = 0
        // else if (manifest == STAT_MULT)
        else
            set this.amount     = 1
        endif
        set this.modType        = manifest
        set this.activeCounter  = 1
        set this.zeroCounter    = 0
        set this.owner          = whichUnit
        set this.modClass       = 0
        call UnsetRequestFlag(REQUEST_DIRECT_AMOUNT + REQUEST_MODIFY_ATTR)
        return this
    endmethod
    private static method init takes nothing returns nothing
        set hashMap = TableArray[7]
    endmethod

    implement Init
endstruct

//  ================================================================
module CUnitStatFactory
    private boolean registered

    private StatList addList
    private StatList multList
    private StatList zeroList

    private real    pSum
    private real    pProduct
    private real    pBaseValue

    static method apply takes unit whichUnit, real value, integer modType returns CStat
        local CStat newStat = 0
        local thistype this = thistype(GetUnitId(whichUnit))
        if ((not this.registered) or (this == 0)) or /*
        */ ((modType != STAT_ADD) and (modType != STAT_MULT)) then
            return CStat(0)
        endif
        set newStat             = CStat.create(whichUnit, modType)

        call CustomUnitStatFactory_SetRequestFlag(REQUEST_MODIFY_ATTR)
        set newStat.modClass    = thistype.typeid
        call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_MODIFY_ATTR)

        set newStat.amount      = value
        return newStat
    endmethod

    //  @stub
    static if (not thistype.onApply.exists) then
    method onApply takes unit whichUnit, real amount returns nothing
    endmethod
    endif

    //  @stub
    static if not thistype.onBonusCalc.exists then 
    method onBonusCalc takes real base, real sum, real product, boolean zeroMultiple returns real
        if (zeroMultiple) then
            return sum
        endif
        return base*product + sum
    endmethod
    endif

    private method bonusCalc takes unit whichUnit returns nothing
        call this.onApply(whichUnit, this.onBonusCalc(this.pBaseValue, this.pSum, this.pProduct, not this.zeroList.empty()))
    endmethod

    static method getProduct takes unit whichUnit returns real
        return thistype(GetUnitId(whichUnit)).pProduct
    endmethod
    static method getSum takes unit whichUnit returns real
        return thistype(GetUnitId(whichUnit)).pSum
    endmethod
    static method getBaseValue takes unit whichUnit returns real
        return thistype(GetUnitId(whichUnit)).pBaseValue
    endmethod
    static method setBaseValueEx takes unit whichUnit, real value, boolean silentUpdate returns nothing
        local thistype this = thistype(GetUnitId(whichUnit))
        set this.pBaseValue = value
        if (not silentUpdate) then
            call this.bonusCalc(whichUnit)
        endif
    endmethod
    static method setBaseValue takes unit whichUnit, real value returns nothing
        call thistype.setBaseValueEx(whichUnit, value, false)
    endmethod

    static method register takes unit whichUnit returns boolean
        local thistype this = thistype(GetUnitId(whichUnit))
        if ((this.registered) or (this == 0)) then
            return false
        endif
        set this.registered = true
        set this.pBaseValue = 0.0
        set this.pSum       = 0.0
        set this.pProduct   = 1.0
        set this.addList    = StatList.create()
        set this.multList   = StatList.create()
        set this.zeroList   = StatList.create()
        //  Perhaps the base value is overridden here, eh?
        static if thistype.onRegister.exists then
            call thistype.onRegister(whichUnit)
        endif
        return true
    endmethod

    private static method onModify takes unit whichUnit, real pastValue, real curValue, CStat curStat returns nothing
        local thistype this     = thistype(GetUnitId(whichUnit))
        if (not curStat.isActive()) then
            return
        endif
        if (curStat.modType == STAT_ADD) then
            call CustomUnitStatFactory_SetRequestFlag(REQUEST_MODIFY_ATTR)
            if (curStat.listPtr == 0) then
                set curStat.listPtr = this.addList.push(curStat).last
                set this.pSum       = this.pSum + curValue
            else
                set this.pSum       = this.pSum - pastValue + curValue
            endif
            call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_MODIFY_ATTR)
            call this.bonusCalc(whichUnit)
            return
        endif
        if (curValue == 0.0) and (pastValue != 0.0) then
            call CustomUnitStatFactory_SetRequestFlag(REQUEST_CHANGE_COUNTER)
            if (not curStat.nullifiesProduct()) then
                call CustomUnitStatFactory_SetRequestFlag(REQUEST_MODIFY_ATTR)
                call this.multList.erase(curStat.listPtr)
                set curStat.listPtr = this.zeroList.push(curStat).last
                call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_MODIFY_ATTR)

                set this.pProduct   = this.pProduct / pastValue
                call curStat.nullify(true)
            endif
            call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_CHANGE_COUNTER)

        elseif (pastValue == 0.0) and (curValue != 0.0) then
            call CustomUnitStatFactory_SetRequestFlag(REQUEST_CHANGE_COUNTER)
            if (curStat.nullifiesProduct()) then
                call CustomUnitStatFactory_SetRequestFlag(REQUEST_MODIFY_ATTR)
                call this.zeroList.erase(curStat.listPtr)
                set curStat.listPtr = this.multList.push(curStat).last
                call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_MODIFY_ATTR)

                set this.pProduct   = this.pProduct * curValue
                call curStat.nullify(false)
            endif
            call CustomUnitStatFactory_UnsetRequestFlag(REQUEST_CHANGE_COUNTER)
        else
            set this.pProduct   = this.pProduct / pastValue * curValue
        endif
        call this.bonusCalc(whichUnit)
    endmethod

    private static method modify takes nothing returns nothing
        call thistype.onModify(CustomUnitStatFactory_GetCurrentUnit(), /*
                            */ CustomUnitStatFactory_GetPrevAmount(), /*
                            */ CustomUnitStatFactory_GetCurrentAmount(), /*
                            */ CustomUnitStatFactory_GetCurrentStat())
    endmethod

    private static method onActivate takes unit whichUnit, CStat curStat, thistype this returns nothing
        call CustomUnitStatFactory_SetRequestFlag(CustomUnitStatFactory_REQUEST_MODIFY_ATTR)
        if (curStat.modType == STAT_ADD) then
            set curStat.listPtr = this.addList.push(curStat).last
            set this.pSum       = this.pSum + curStat.amount
        else
            if (curStat.nullifiesProduct()) then
                set curStat.listPtr = this.zeroList.push(curStat).last
            else
                set curStat.listPtr = this.multList.push(curStat).last
                set this.pProduct   = this.pProduct * curStat.amount
            endif
        endif
        call this.bonusCalc(whichUnit)
        set curStat.listPtr = 0
        call CustomUnitStatFactory_UnsetRequestFlag(CustomUnitStatFactory_REQUEST_MODIFY_ATTR)
    endmethod

    private static method onDeactivate takes unit whichUnit, CStat curStat, thistype this returns nothing
        local StatListItem ptr  = curStat.listPtr
        call CustomUnitStatFactory_SetRequestFlag(CustomUnitStatFactory_REQUEST_MODIFY_ATTR)
        if (curStat.modType == STAT_ADD) then
            call this.addList.erase(curStat.listPtr)
            set this.pSum           = this.pSum - curStat.amount
        else
            // if curStat.zeroCounter > 0
            if (curStat.nullifiesProduct()) then
                call this.zeroList.erase(curStat.listPtr)
            else
                call this.multList.erase(curStat.listPtr)
                set this.pProduct   = this.pProduct / curStat.amount
            endif
        endif
        call this.bonusCalc(whichUnit)
        set curStat.listPtr     = 0
        call CustomUnitStatFactory_UnsetRequestFlag(CustomUnitStatFactory_REQUEST_MODIFY_ATTR)
    endmethod

    private static method activate takes nothing returns nothing
        local unit whichUnit    = CustomUnitStatFactory_GetCurrentUnit()
        local CStat curStat     = CustomUnitStatFactory_GetCurrentStat()
        local boolean state     = CustomUnitStatFactory_GetStatActivationState()
        local thistype this     = thistype(GetUnitId(whichUnit))
        if (state) then
            call thistype.onActivate(whichUnit, curStat, this)
        else
            call thistype.onDeactivate(whichUnit, curStat, this)
        endif
        set whichUnit   = null
    endmethod

    private static method onUnitEnter takes nothing returns nothing
        call thistype.register(GetIndexedUnit())
    endmethod

    private static method onUnitLeave takes nothing returns nothing
        local unit whichUnit    = GetIndexedUnit()
        local thistype this     = thistype(GetIndexedUnitId())
        local CStat curStat

        //  Empty all the nodes from each list
        //  ====================================================
        loop
            exitwhen this.addList.empty()
            set curStat = CStat(this.addList.first.data)
            call curStat.destroy()
        endloop
        loop
            exitwhen this.multList.empty()
            set curStat = CStat(this.multList.first.data)
            call curStat.destroy()
        endloop
        loop
            exitwhen this.zeroList.empty()
            set curStat = CStat(this.zeroList.first.data)
            call curStat.destroy()
        endloop
        //  ====================================================
        call this.zeroList.destroy()
        call this.multList.destroy()
        call this.addList.destroy()
        set this.registered     = false
        set this.pBaseValue     = 0.0
        set this.pSum           = 0.0
        set this.pProduct       = 0.0
        set this.addList        = 0
        set this.multList       = 0
        set this.zeroList       = 0
        static if thistype.onUnregister.exists then
            call thistype.onUnregister(whichUnit)
        endif
        set whichUnit   = null
    endmethod

    private static method onInit takes nothing returns nothing
        call CustomUnitStatFactory_AssignModifuncToClass(thistype.typeid, function thistype.modify)
        call CustomUnitStatFactory_AssignActifuncToClass(thistype.typeid, function thistype.activate)
        call CustomUnitStatFactory_AssignDeactifuncToClass(thistype.typeid, function thistype.activate)

        call CustomUnitStatFactory_RegisterEnterHandler(function thistype.onUnitEnter)
        call CustomUnitStatFactory_RegisterLeaveHandler(function thistype.onUnitLeave)
    endmethod
endmodule

endlibrary