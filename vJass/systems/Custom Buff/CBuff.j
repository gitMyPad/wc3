library CBuff requires /*

    ---------------------------
    */  Table, ListT, Alloc  /*
    ---------------------------

    --------------------------------------
    */  UnitDex, GTimer, DamageHandler  /*
    --------------------------------------

     ---------------------------------------------------------------
    |
    |       CBuff
    |           - MyPad
    |           - v.1.2.0
    |
    |---------------------------------------------------------------
    |
    |   A library that makes handling custom buffs relatively easy
    |   with much of the groundwork automated by the system.
    |
    |   All metadata information regarding the buff itself is handled
    |   by the CustomBuff class, such as stacking, unstacking, buff
    |   monitoring, static interval ticks, dynamic interval ticks,
    |   moment of buff inclusion, and removal.
    |
    |   On the other hand, all in-game processes such as timed duration
    |   of buffs are handled by the Buff class.
    |
    |---------------------------------------------------------------
    |
    |   API:
    |
    |   class CustomBuff {
    |   ================================================================
    |       static method register(int abilID, int buffID, int behavior) -> CustomBuff
    |           - Creates a new Custom Buff instance.
    |           - It is recommended to do this at the start of the game,
    |             since these objects are permanent.
    |           - One instance per class is enough for your needs.
    |           - {Added in 1.1.0} Additional behavior can be specified,
    |             such as automatic Buff instance removal upon detection
    |             of actual buff removal.
    |
    |       method setIntervalListener(real interval, code callback)
    |           - Tells the system to run the specified callback function
    |             every interval seconds, as long as the target unit
    |             still has the buff.
    |
    |       method setStackIntervalListener(real interval, code callback) 
    |           - Tells the system to run the specified callback function
    |             every interval seconds for each stack added.
    |           - The timer for this starts at the moment a stack is added
    |             and ends when the stack is removed.
    |
    |       method setAddListener(code callback)
    |           - Runs at the moment the buff is added to the unit.
    |
    |       method setStackListener(code callback)
    |           - Runs at the moment a stack of the buff is added
    |             to the unit.
    |           - Runs after setAddListener if the buff is newly
    |             added to the unit.
    |
    |       method setStackListener(code callback)
    |           - Runs at the moment a stack of the buff is added
    |             to the unit.
    |           - Runs after setAddListener if the buff is newly
    |             added to the unit.
    |
    |       method setUnstackListener(code callback)
    |           - Runs at the moment a stack of the buff is removed
    |             from the unit.
    |           - Runs before setRemoveListener if the buff is removed
    |             from the unit.
    |
    |       method setMonitorListener(code callback)
    |           - Runs UPDATE_TICK (10) times every second while the buff
    |             is still present on the unit.
    |   ================================================================
    |   }
    |
    |   class Buff {
    |   ================================================================
    |    -----------
    |   | Methods:  |
    |    -----------
    |       static method apply(unit whichUnit, CustomBuff whichBuff)
    |           - Applies a new Buff instance based on the CustomBuff
    |             object.
    |
    |       static method applyTimed(unit whichUnit, CustomBuff whichBuff, real dur)
    |           - Applies a timed new Buff instance based on the CustomBuff
    |             object. Expires after dur seconds.
    |           - Setting dur to a negative value will make this behave
    |             as Buff.apply.
    |           - Attempting to apply a physical CustomBuff to a unit
    |             that's ethereal will result in an invalid Buff instance (0).
    |
    |       static method has(unit whichUnit, CustomBuff whichBuff) -> bool
    |           - Checks if unit has a Buff instance based on the CustomBuff.
    |
    |    -----------
    |   | Members:  |
    |    -----------
    |       readonly integer stack
    |           - The number of stacks a Buff currently has.
    |       integer data
    |           - Misc data associated with the Buff.
    |       integer level (operator)
    |           - The current level of the ability associated with the Buff.
    |
    |       readonly unit unit
    |           - The affected unit of a Buff.
    |       readonly CustomBuff cbuff
    |           - The CustomBuff object the Buff is based on.
    |
    |       readonly static Buff current
    |           - The affected Buff instance in every callback.
    |
    |       readonly static integer prevStackCount
    |           - The amount of stacks the current Buff had
    |             before the event.
    |           - Only meaningful in stack and unstack events.
    |
    |       readonly static integer stackIncrement
    |           - The change in the amount of stacks from the
    |             previous amount to the current amount.
    |           - Only meaningful in stack and unstack events.
    |
    |       readonly static TimedBuffData lastData
    |       readonly static TimedBuffData curData
    |           - The timed buff data associated with the Buff,
    |             which holds additional parameters.
    |            ---------------
    |           | Parameters:   |
    |            ---------------
    |               integer data
    |                   - Custom data associated with the TimedBuffData.
    |               readonly integer stackCount
    |                   - The number of times the TimedBuffData object
    |                     has triggered the stackInterval event.
    |               readonly Buff buff
    |                   - A relay pointer referring to the current
    |                     Buff.
    |           ----------------------------------------------------
    |           - Only meaningful in the stack, unstack, interval
    |             and stack interval events.
    |   ================================================================
    |   }
    |
    |   module CustomBuffHandler {
    |       interface static method onBuffAdd()
    |       interface static method onBuffStack()
    |       interface static method onBuffUnstack()
    |       interface static method onBuffMonitor()
    |       interface static method onBuffTick()
    |       interface static method onBuffStackTick()
    |       interface static method onBuffRemove()
    |           - Optional methods to implement in your class.
    |
    |       static method DEBUFF_ABIL_ID() -> integer
    |           - The base ability ID for the included CustomBuff object.
    |
    |       static method DEBUFF_BUFF_ID() -> integer
    |           - The buff ID the included CustomBuff object.
    |
    |       stub static method STATIC_INTERVAL() -> real
    |           - The interval to be used by onBuffTick().
    |           - Default of 1.0
    |
    |       stub static method STACK_INTERVAL() -> real
    |           - The interval to be used by onBuffStackTick().
    |           - Default of 1.0
    |
    |       stub static method BEHAVIOR_ID() -> integer
    |           - Specifies additional traits about the custom buff.
    |           - By default, it operates independently of the
    |             associated buff id.
    |           
    |           Behavior table:
    |               - CustomBuff.BEHAVIOR_NO_BUFF       -> Does not check for the buff's presence.
    |               - CustomBuff.BEHAVIOR_DISPELLABLE   -> Buff is dispelled whenever a unit is
    |                                                      hit with a dispel spell.
    |               - CustomBuff.BEHAVIOR_PHYSICAL      -> Buff is dispelled whenever a unit becomes
    |                                                      ethereal.
    |               - CustomBuff.BEHAVIOR_POSITIVE      -> Buff is considered a positive effect.
    |
    |       static method applyBuff(unit whichUnit, real dur) -> Buff
    |           - Applies a Buff instance based on the included CustomBuff object.
    |
    |       static method has(unit whichUnit) -> boolean
    |           - Checks if the unit has a Buff based on the CustomBuff object.
    |   }
    |
     ---------------------------------------------------------------
*/

native UnitAlive takes unit id returns boolean

globals
    private integer codeflag                = 0
    private constant integer SYSTEM_FLAG    = 1
    constant integer BUFF_MAX_LEVEL         = 100
endglobals

private function B2S takes boolean flag returns string
    if (flag) then
        return "true"
    endif
    return "false"
endfunction

private struct CustomBuffPrio extends array
    static Table prioMap        = 0
    static Table behaviorMap    = 0
    static integer curIndex     = 0

    method operator priority takes nothing returns integer
        return prioMap.integer[BUFF_MAX_LEVEL*(integer(this) - 1) + curIndex]
    endmethod
    method operator behavior takes nothing returns integer
        return behaviorMap.integer[BUFF_MAX_LEVEL*(integer(this) - 1) + curIndex]
    endmethod
    method operator priority= takes integer value returns nothing
        set prioMap.integer[BUFF_MAX_LEVEL*(integer(this) - 1) + curIndex]      = value
    endmethod
    method operator behavior= takes integer value returns nothing
        set behaviorMap.integer[BUFF_MAX_LEVEL*(integer(this) - 1) + curIndex]  = value
    endmethod

    private static method init takes nothing returns nothing
        set prioMap             = Table.create()
        set behaviorMap         = Table.create()
    endmethod
    implement Init
endstruct

//  ===================================
//      A class that handles
//      the bundle of ability IDs
//      along with their respective
//      buff IDs
//  ====================================
struct CustomBuff extends array
    implement Alloc

    //  Response mask enums
    readonly static constant integer MASK_INTERVAL          = 1
    readonly static constant integer MASK_REMOVAL           = 2
    readonly static constant integer MASK_ADD               = 4
    readonly static constant integer MASK_MONITOR           = 8
    readonly static constant integer MASK_STACK             = 16
    readonly static constant integer MASK_UNSTACK           = 32
    readonly static constant integer MASK_STACK_INTERVAL    = 64

    readonly static constant integer BEHAVIOR_NO_BUFF       = 1
    readonly static constant integer BEHAVIOR_DISPELLABLE   = 2
    readonly static constant integer BEHAVIOR_PHYSICAL      = 4
    readonly static constant integer BEHAVIOR_POSITIVE      = 8

    //  Used as the last parameter for Buff.dispelEx
    readonly static constant integer BUFF_TYPE_POSITIVE     = 1
    readonly static constant integer BUFF_TYPE_NEGATIVE     = 2
    readonly static constant integer BUFF_TYPE_BOTH         = 3

    //  Class members
    private static Table abilMap        = 0
    private static Table prioMap        = 0

    //  Primary info
    readonly integer abilID
    readonly integer buffID
    readonly integer maxLevel

    //  Buff response mask
    readonly integer respMask

    //  Tick callback info
    private EventResponder intervalResp
    private EventResponder stackIntervalResp
    readonly real interval
    readonly real stackInterval

    //  Add callback info
    private EventResponder addResp

    //  Remove callback info
    private EventResponder removeResp

    //  Monitor callback info
    private EventResponder monitorResp

    //  Stack callback info
    private EventResponder stackResp
    private EventResponder unstackResp

    method setIntervalListener takes real interval, code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_INTERVAL)
        set this.interval   = interval
        call this.intervalResp.change(callback)
    endmethod

    method setStackIntervalListener takes real interval, code callback returns nothing
        set this.respMask       = BlzBitOr(this.respMask, MASK_STACK_INTERVAL)
        set this.stackInterval  = interval
        call this.stackIntervalResp.change(callback)
    endmethod

    method setAddListener takes code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_ADD)
        call this.addResp.change(callback)
    endmethod
    
    method setRemoveListener takes code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_REMOVAL)
        call this.removeResp.change(callback)
    endmethod

    method setMonitorListener takes code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_MONITOR)
        call this.monitorResp.change(callback)
    endmethod

    method setStackListener takes code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_STACK)
        call this.stackResp.change(callback)
    endmethod

    method setUnstackListener takes code callback returns nothing
        set this.respMask   = BlzBitOr(this.respMask, MASK_UNSTACK)
        call this.unstackResp.change(callback)
    endmethod

    //  ====================================================
    //  Technically private methods, since they're only called by
    //  the CustomBuffHandler class below.
    method runIntervalListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.intervalResp.run()
    endmethod

    method runAddListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.addResp.run()
    endmethod

    method runRemoveListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.removeResp.run()
    endmethod

    method runMonitorListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.monitorResp.run()
    endmethod

    method runStackListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.stackResp.run()
    endmethod

    method runStackIntervalListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.stackIntervalResp.run()
    endmethod

    method runUnstackListener takes nothing returns nothing
        if (BlzBitAnd(codeflag, SYSTEM_FLAG) == 0) then
            return
        endif
        call this.unstackResp.run()
    endmethod

    method operator [] takes integer level returns CustomBuffPrio
        set CustomBuffPrio.curIndex     = IMaxBJ(IMinBJ(level, BUFF_MAX_LEVEL), 1)
        return CustomBuffPrio(this)
    endmethod

    method isMaskFlagged takes integer mask returns boolean
        return BlzBitAnd(this.respMask, mask) != 0
    endmethod

    method isBehaviorFlagged takes integer level, integer behavior returns boolean
        return BlzBitAnd(this[level].behavior, behavior) != 0
    endmethod

    private method initProperties takes integer priority, integer behavior returns nothing
        local integer i                 = 1
        loop
            exitwhen (i >= this.maxLevel)
            set this[i].priority        = priority
            set this[i].behavior        = behavior
            set i                       = i + 1
        endloop
        if (i <= BUFF_MAX_LEVEL) then
            set this[i].priority        = -1
            set this[i].behavior        = behavior
        endif
    endmethod

    static method register takes integer abilID, integer buffID, integer behavior, integer maxLevel, integer priority returns thistype
        local thistype this                 = abilMap[abilID]
        set maxLevel                        = IMinBJ(IMaxBJ(maxLevel, 1), BUFF_MAX_LEVEL)
        if (this == 0) then
            set this                        = thistype.allocate()
            set abilMap[abilID]             = this
            set this.abilID                 = abilID
            set this.buffID                 = buffID
            set this.maxLevel               = maxLevel
            set this.stackIntervalResp      = EventResponder.create(null)
            set this.intervalResp           = EventResponder.create(null)
            set this.addResp                = EventResponder.create(null)
            set this.removeResp             = EventResponder.create(null)
            set this.monitorResp            = EventResponder.create(null)
            set this.stackResp              = EventResponder.create(null)
            set this.unstackResp            = EventResponder.create(null)
            call this.initProperties(IMaxBJ(priority, 1), behavior)
        endif
        return this
    endmethod

    //  ====================================================
    private static method init takes nothing returns nothing
        set abilMap = Table.create()
    endmethod
    implement Init
endstruct

//! runtextmacro DEFINE_LIST("private", "BuffList", "integer")
//! runtextmacro DEFINE_LIST("private", "UnitList", "unit")

private struct BuffData extends array
    //  Handles unit to CustomBuff maps
    readonly Table unitHashMap
    readonly BuffList buffList
    integer  monitorPtr

    static method operator [] takes unit whichUnit returns thistype
        return thistype(GetUnitId(whichUnit))
    endmethod

    static method register takes unit whichUnit returns thistype
        local thistype this = GetUnitId(whichUnit)
        if (this.buffList != 0) then
            return this
        endif
        set this.buffList       = BuffList.create()
        set this.unitHashMap    = Table.create()
        return this
    endmethod

    method unregister takes nothing returns nothing
        call this.unitHashMap.destroy()
        call this.buffList.destroy()
        set this.monitorPtr     = 0
        set this.buffList       = 0
        set this.unitHashMap    = 0
    endmethod
endstruct

struct TimedBuffData extends array
    implement Alloc

    readonly timer stackedTimer
    readonly timer timer
    readonly Buff buff
    integer data
    integer stackCount
    IntegerListItem ptr

    method destroy takes nothing returns nothing
        call ReleaseTimer(this.stackedTimer)
        call ReleaseTimer(this.timer)
        set this.timer      = null
        set this.buff       = 0
        set this.data       = 0
        set this.ptr        = 0
        call this.deallocate()
    endmethod
    static method create takes Buff source, integer data returns thistype
        local thistype this     = thistype.allocate()
        set this.buff           = source
        set this.data           = data
        set this.timer          = NewTimerEx(this)
        set this.stackedTimer   = NewTimerEx(this)
        set this.ptr            = 0
        return this
    endmethod
endstruct

struct Buff extends array
    implement Alloc

    private  static code onInstanceTimer        = null
    private  static code onTimedRemove          = null
    private  static code onStackInterval         = null
    private  static UnitList monitorGroup       = 0
    private  static EventResponder monitorResp  = 0

    readonly static Buff current                = 0
    readonly static CustomBuff currentType      = 0
    readonly static integer prevStackCount      = 0
    readonly static integer stackIncrement      = 0
    readonly static TimedBuffData lastData      = 0

    private  IntegerList    timedBuffList
    readonly CustomBuff     cbuff
    readonly unit           unit
    readonly BuffListItem   buffListPtr

    readonly integer        stack
    integer                 data

    private timer staticTimer

    //  ====================================================
    //              Convenience operators
    //  ====================================================
    static method operator curData takes nothing returns TimedBuffData
        return lastData
    endmethod

    //  ====================================================
    //      Code flag manipulators
    //  ====================================================
    private static method setCodeFlag takes integer mask returns nothing
        set codeflag    = BlzBitOr(codeflag, mask)
    endmethod
    private static method unsetCodeFlag takes integer mask returns nothing
        set codeflag    = BlzBitAnd(codeflag, -mask - 1)
    endmethod
    private static method isCodeFlagSet takes integer mask returns boolean
        return BlzBitAnd(codeflag, mask) != 0
    endmethod

    //  ====================================================
    //          Monitor and Release methods
    //  ====================================================
    private static method monitorUnit takes unit whichUnit returns nothing
        local BuffData temp = BuffData[whichUnit]
        if (temp.monitorPtr != 0) then
            return
        endif
        set temp.monitorPtr = monitorGroup.push(whichUnit).last
        if (monitorGroup.size() == 1) then
            call GTimer[UPDATE_TICK].requestCallback(monitorResp)
        endif
    endmethod
    private static method releaseUnit takes unit whichUnit returns nothing
        local BuffData temp = BuffData[whichUnit]
        if (temp.monitorPtr == 0) then
            return
        endif
        call monitorGroup.erase(temp.monitorPtr)
        call temp.unregister()
        if (monitorGroup.empty()) then
            call GTimer[UPDATE_TICK].releaseCallback(monitorResp)
        endif
    endmethod

    //  ====================================================
    //          Accessible API
    //  ====================================================
    method operator level takes nothing returns integer
        return GetUnitAbilityLevel(this.unit, this.cbuff.abilID)
    endmethod

    method operator level= takes integer newLevel returns nothing
        if (this.level == newLevel) then
            return
        endif
        call BlzUnitDisableAbility(this.unit, this.cbuff.abilID, true, true)
        call UnitRemoveAbility(this.unit, this.cbuff.buffID)
        call SetUnitAbilityLevel(this.unit, this.cbuff.abilID, newLevel)
        call BlzUnitDisableAbility(this.unit, this.cbuff.abilID, false, false)
    endmethod

    method operator [] takes integer index returns CustomBuffPrio
        set CustomBuffPrio.curIndex     = IMaxBJ(IMinBJ(index, BUFF_MAX_LEVEL), 1)
        return CustomBuffPrio(this.cbuff)
    endmethod

    private static method invokeCallback takes Buff this, CustomBuff whichBuff, integer callbackType returns nothing
        local Buff prev             = current
        local CustomBuff prevType   = currentType
        local integer prevCFlag     = codeflag
        set current                 = this
        set currentType             = whichBuff
        //  switch (callbackType) {case: ...}
        call Buff.setCodeFlag(SYSTEM_FLAG)
        if (callbackType == CustomBuff.MASK_INTERVAL) then
            call whichBuff.runIntervalListener()
        elseif (callbackType == CustomBuff.MASK_STACK_INTERVAL) then
            call whichBuff.runStackIntervalListener()
        elseif (callbackType == CustomBuff.MASK_ADD) then
            call whichBuff.runAddListener()
        elseif (callbackType == CustomBuff.MASK_MONITOR) then
            call whichBuff.runMonitorListener()
        elseif (callbackType == CustomBuff.MASK_REMOVAL) then
            call whichBuff.runRemoveListener()
        elseif (callbackType == CustomBuff.MASK_STACK) then
            call whichBuff.runStackListener()
        elseif (callbackType == CustomBuff.MASK_UNSTACK) then
            call whichBuff.runUnstackListener()
        endif
        set codeflag                = prevCFlag
        set currentType             = prevType
        set current                 = prev
    endmethod

    static method has takes unit whichUnit, CustomBuff whichBuff returns boolean
        return (BuffData[whichUnit].unitHashMap != 0) and /*
            */ (BuffData[whichUnit].unitHashMap.has(whichBuff))
    endmethod

    private method validForDispel takes integer removeType returns boolean
        set removeType          = BlzBitAnd(removeType, CustomBuff.BUFF_TYPE_BOTH)
        if (removeType == CustomBuff.BUFF_TYPE_BOTH) then
            return true
        endif
        if (removeType == CustomBuff.BUFF_TYPE_POSITIVE) then
            return this.cbuff.isBehaviorFlagged(this.level, CustomBuff.BEHAVIOR_POSITIVE)
        endif
        return not this.cbuff.isBehaviorFlagged(this.level, CustomBuff.BEHAVIOR_POSITIVE)
    endmethod

    static method dispelEx takes unit whichUnit, integer priority, boolean strongDispel, integer removeType returns nothing
        local BuffData temp         = BuffData[whichUnit]
        local BuffListItem iter     = 0
        if (temp.buffList == 0) then
            return
        endif
        set iter                    = temp.buffList.first
        loop
            exitwhen (iter == 0)
            set current = Buff(iter.data)
            set iter    = iter.next

            //  ===================================
            //      Strong dispels can remove
            //      Buffs that are not considered
            //      dispellable, but only if
            //      the priority is equal to or
            //      greater than the Buff's priority
            //  ===================================
            if (((strongDispel) or /*
            */ (current.cbuff.isBehaviorFlagged(current.level, CustomBuff.BEHAVIOR_DISPELLABLE))) and /*
            */ (current.cbuff[current.level].priority <= priority)) and /*
            */ (current.validForDispel(removeType)) then
                //  Dispel buff.
                call current.removeEx(current.stack)
            endif
        endloop
        //  ===================================
        //  Remove this unit from the list if empty.
        if (temp.buffList.empty()) then
            call Buff.releaseUnit(tempUnit)
        endif
    endmethod

    static method dispel takes unit whichUnit, integer priority, boolean strongDispel returns nothing
        call Buff.dispelEx(whichUnit, priority, strongDispel, CustomBuff.BUFF_TYPE_BOTH)
    endmethod

    static method applyTimed takes unit whichUnit, CustomBuff whichBuff, real dur returns Buff
        local BuffData temp             = BuffData.register(whichUnit)
        local Buff this                 = temp.unitHashMap[whichBuff]
        local TimedBuffData prevData    = lastData 
        local integer stackQt           = prevStackCount
        if (whichBuff == 0) or /*
        */ (whichBuff.isBehaviorFlagged(this.level, CustomBuff.BEHAVIOR_PHYSICAL) and /*
        */ (IsUnitType(whichUnit, UNIT_TYPE_ETHEREAL))) then
            return this
        endif
        if (this == 0) then
            set this                    = Buff.allocate()
            set this.cbuff              = whichBuff
            set this.unit               = whichUnit
            set this.buffListPtr        = temp.buffList.push(this).last
            set this.stack              = 0
            set this.timedBuffList      = IntegerList.create()

            if (whichBuff.isMaskFlagged(CustomBuff.MASK_ADD)) then
                call Buff.invokeCallback(this, whichBuff, CustomBuff.MASK_ADD)
            endif
            if (whichBuff.isMaskFlagged(CustomBuff.MASK_INTERVAL)) then
                set this.staticTimer    = NewTimerEx(this)
                call TimerStart(this.staticTimer, whichBuff.interval, true, Buff.onInstanceTimer)
            endif
            call UnitAddAbility(whichUnit, whichBuff.abilID)
            call UnitMakeAbilityPermanent(whichUnit, true, whichBuff.abilID)
            call Buff.monitorUnit(whichUnit)

            set temp.unitHashMap[whichBuff] = this
        endif
        set lastData            = 0
        set stackIncrement      = 1
        set prevStackCount      = this.stack
        set this.stack          = this.stack + 1
        //  If duration is <= 0.0, it is considered permanent.
        if (dur > 0.0) then
            set lastData        = TimedBuffData.create(this, 0)
            set lastData.ptr    = this.timedBuffList.push(lastData).last
            if (whichBuff.isMaskFlagged(CustomBuff.MASK_STACK_INTERVAL)) then
                call TimerStart(lastData.stackedTimer, whichBuff.stackInterval, true, Buff.onStackInterval)
            endif
            call TimerStart(lastData.timer, dur, false, Buff.onTimedRemove)
        endif
        if (whichBuff.isMaskFlagged(CustomBuff.MASK_STACK)) then
            call Buff.invokeCallback(this, whichBuff, CustomBuff.MASK_STACK)
        endif
        set prevStackCount  = stackQt
        set lastData        = prevData
        return this
    endmethod

    static method apply takes unit whichUnit, CustomBuff whichBuff returns Buff
        return Buff.applyTimed(whichUnit, whichBuff, -1.0)
    endmethod

    private method removeEx takes integer stacks returns nothing
        local BuffData temp             = 0
        local CustomBuff lastBuff       = 0
        local integer stackQt           = 0
        local TimedBuffData prevData    = 0
        //  Check if object is already destroyed.
        if (this.cbuff == 0) then
            return
        endif
        set stackQt         = prevStackCount
        set stackIncrement  = -stacks
        set prevStackCount  = this.stack
        set this.stack      = IMaxBJ(this.stack - stacks, 0)
        if (this.cbuff.isMaskFlagged(CustomBuff.MASK_UNSTACK)) then
            call Buff.invokeCallback(this, this.cbuff, CustomBuff.MASK_UNSTACK)
        endif
        set prevStackCount  = stackQt
        if (this.stack > 0) then
            return
        endif

        //  ======================================
        //      Proceed with destruction
        //  ======================================
        set temp        = BuffData[this.unit]
        set lastBuff    = this.cbuff
        set this.cbuff  = 0
        call temp.buffList.erase(this.buffListPtr)
        call temp.unitHashMap.remove(lastBuff)

        //  ======================================
        //      Clean up all associated timed
        //      instances.
        //  ======================================
        set prevData        = lastData
        loop
            exitwhen this.timedBuffList.empty()
            set lastData    = this.timedBuffList.last.data
            call this.timedBuffList.erase(lastData.ptr)
            call lastData.destroy()
        endloop
        set lastData        = prevData
        call this.timedBuffList.destroy()

        if (this.staticTimer != null) then
            call ReleaseTimer(this.staticTimer)
        endif
        call UnitRemoveAbility(this.unit, lastBuff.buffID)
        call UnitRemoveAbility(this.unit, lastBuff.abilID)
        if (lastBuff.isMaskFlagged(CustomBuff.MASK_REMOVAL)) then
            call Buff.invokeCallback(this, lastBuff, CustomBuff.MASK_REMOVAL)
        endif
        set this.staticTimer    = null
        set this.unit           = null
        set this.stack          = 0
        set this.data           = 0
        set this.buffListPtr    = 0
        set this.timedBuffList  = 0
        call this.deallocate()
    endmethod

    method remove takes nothing returns nothing
        call this.removeEx(1)
    endmethod

    //  ====================================================
    private static unit tempUnit    = null
    static method onMonitorUnitBuff takes unit whichUnit returns nothing
        local boolean isDead        = (not UnitAlive(tempUnit))
        local BuffData temp         = BuffData[tempUnit]
        local BuffListItem iter     = temp.buffList.first
        loop
            exitwhen (iter == 0)
            set current             = Buff(iter.data)
            set iter                = iter.next

            //  ===================================
            if (isDead) or /*
            */ ((not current.cbuff.isBehaviorFlagged(current.level, CustomBuff.BEHAVIOR_NO_BUFF)) and /*
            */ (GetUnitAbilityLevel(tempUnit, current.cbuff.buffID) == 0)) or /*
            */ ((current.cbuff.isBehaviorFlagged(current.level, CustomBuff.BEHAVIOR_PHYSICAL)) and /*
            */ (IsUnitType(tempUnit, UNIT_TYPE_ETHEREAL))) then
                //  Dispel buff.
                call current.removeEx(current.stack)

            elseif (current.cbuff.isMaskFlagged(CustomBuff.MASK_MONITOR)) then
                //  Monitor the situation.
                call Buff.invokeCallback(current, current.cbuff, CustomBuff.MASK_MONITOR)
            endif
        endloop
        //  ===================================
        //  Remove this unit from the list if empty.            
        if (temp.buffList.empty()) then
            call thistype.releaseUnit(tempUnit)
        endif
    endmethod

    private static method onMonitorBuffs takes nothing returns nothing
        local UnitListItem i        = monitorGroup.first
        loop
            exitwhen (i == 0)
            set tempUnit            = i.data
            set i                   = i.next

            //  ===================================
            call Buff.onMonitorUnitBuff(tempUnit)
        endloop
    endmethod

    private static method onUnitLeave takes nothing returns nothing
        local unit prevUnit     = GetIndexedUnit()
        local BuffData temp     = BuffData[prevUnit]
        local BuffListItem iter = 0
        if (temp.monitorPtr == 0) then
            set prevUnit        = null
            return
        endif

        set iter            = temp.buffList.first
        loop
            exitwhen (iter == 0)
            set current     = Buff(iter.data)
            set iter        = iter.next

            //  ===================================
            //  Dispel buff.
            call current.removeEx(current.stack)
        endloop
        //  ===================================
        //  Remove this unit from the list if empty.            
        if (temp.buffList.empty()) then
            call Buff.releaseUnit(tempUnit)
        else
            //  Hopefully, this doesn't happen.
            //  Otherwise, it's nice to include this
            //  when it does occur.
            call BJDebugMsg("CBuff {EVENT_UNIT_LEAVE} >> |cffff4040Error!|r - Buff list isn't empty!")
        endif
        set prevUnit        = null
    endmethod

    private static method onInstanceExpire takes nothing returns nothing
        local Buff this                 = GetTimerData(GetExpiredTimer())
        call Buff.invokeCallback(this, this.cbuff, CustomBuff.MASK_INTERVAL)
    endmethod

    private static method onTimedExpire takes nothing returns nothing
        local TimedBuffData data        = GetTimerData(GetExpiredTimer())
        local TimedBuffData prevData    = lastData
        local Buff this                 = data.buff
        set lastData                    = data
        call this.timedBuffList.erase(data.ptr)
        call data.destroy()
        call this.removeEx(1)
        set lastData                    = prevData
    endmethod

    private static method onStackIntervalExpire takes nothing returns nothing
        local TimedBuffData data        = GetTimerData(GetExpiredTimer())
        local TimedBuffData prevData    = lastData
        local Buff this                 = data.buff
        set data.stackCount             = data.stackCount + 1
        set lastData                    = data
        call Buff.invokeCallback(this, this.cbuff, CustomBuff.MASK_INTERVAL)
        set lastData                    = prevData
    endmethod

    //  ====================================================
    private static method init takes nothing returns nothing
        set monitorGroup    = UnitList.create()
        set monitorResp     = GTimer.register(UPDATE_TICK, function Buff.onMonitorBuffs)
        set onInstanceTimer = function Buff.onInstanceExpire
        set onTimedRemove   = function Buff.onTimedExpire
        set onStackInterval = function Buff.onStackIntervalExpire
        call OnUnitDeindex(function Buff.onUnitLeave)
    endmethod
    implement Init
endstruct

module CustomBuffHandler
    private static CustomBuff base  = 0

    static if (not thistype.MAX_LEVEL.exists) then
    static method MAX_LEVEL takes nothing returns integer
        return 1
    endmethod
    endif

    static if (not thistype.PRIORITY_VALUE.exists) then
    static method PRIORITY_VALUE takes integer level returns integer
        return 1
    endmethod
    endif

    static if (not thistype.BEHAVIOR_ID.exists) then
    static method BEHAVIOR_ID takes integer level returns integer
        return CustomBuff.BEHAVIOR_NO_BUFF + CustomBuff.BEHAVIOR_POSITIVE
    endmethod
    endif

    static if (not thistype.DEBUFF_ABIL_ID.exists) then
    static method DEBUFF_ABIL_ID takes nothing returns integer
        return 0
    endmethod
    endif

    static if (not thistype.DEBUFF_BUFF_ID.exists) then
    static method DEBUFF_BUFF_ID takes nothing returns integer
        return 0
    endmethod
    endif

    static if (not thistype.STATIC_INTERVAL.exists) then
    static method STATIC_INTERVAL takes nothing returns real
        return 1.0
    endmethod
    endif

    static if (not thistype.STACK_INTERVAL.exists) then
    static method STACK_INTERVAL takes nothing returns real
        return 1.0
    endmethod
    endif

    static method applyBuff takes unit whichUnit, real dur returns Buff
        return Buff.applyTimed(whichUnit, base, dur)
    endmethod

    static method has takes unit whichUnit returns boolean
        return Buff.has(whichUnit, base)
    endmethod

    private static method onInit takes nothing returns nothing
        local integer i     = 2
        set base            = CustomBuff.register(DEBUFF_ABIL_ID(), DEBUFF_BUFF_ID(), /*
                                                */BEHAVIOR_ID(1), MAX_LEVEL(), PRIORITY_VALUE(1))
        static if thistype.onBuffAdd.exists then
            call base.setAddListener(function thistype.onBuffAdd)
        endif
        static if thistype.onBuffStack.exists then
            call base.setStackListener(function thistype.onBuffStack)
        endif
        static if thistype.onBuffUnstack.exists then
            call base.setUnstackListener(function thistype.onBuffUnstack)
        endif
        static if thistype.onBuffMonitor.exists then
            call base.setMonitorListener(function thistype.onBuffMonitor)
        endif
        static if thistype.onBuffTick.exists then
            call base.setIntervalListener(STATIC_INTERVAL(), function thistype.onBuffTick)
        endif
        static if thistype.onBuffStackTick.exists then
            call base.setStackIntervalListener(STACK_INTERVAL(), function thistype.onBuffStackTick)
        endif
        static if thistype.onBuffRemove.exists then
            call base.setRemoveListener(function thistype.onBuffRemove)
        endif
        loop
            exitwhen (i > base.maxLevel)
            set base[i].behavior    = BEHAVIOR_ID(i)
            set i                   = i + 1
        endloop
    endmethod
endmodule

endlibrary