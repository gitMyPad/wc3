library Dummy requires Table, Alloc, Init, WorldBounds, TimerUtils, EventListener

native UnitAlive takes unit id returns boolean

private module DummyModuleOps
    method operator x takes nothing returns real
        return GetUnitX(this.dummy)
    endmethod
    method operator y takes nothing returns real
        return GetUnitY(this.dummy)
    endmethod
    method operator z takes nothing returns real
        return GetUnitFlyHeight(this.dummy)
    endmethod
    method operator paused takes nothing returns boolean
        return IsUnitPaused(this.dummy)
    endmethod

    method operator x= takes real value returns nothing
        call SetUnitX(this.dummy, value)
    endmethod
    method operator y= takes real value returns nothing
        call SetUnitY(this.dummy, value)
    endmethod
    method operator z= takes real value returns nothing
        call SetUnitFlyHeight(this.dummy, value, 0.0)
    endmethod
    method operator paused= takes boolean flag returns nothing
        call PauseUnit(this.dummy, flag)
    endmethod

    method disableAbil takes integer abilID, boolean flag, boolean hide returns nothing
        call BlzUnitDisableAbility(this.dummy, abilID, flag, hide)
    endmethod
    method addAbil takes integer abilID returns boolean
        return UnitAddAbility(this.dummy, abilID)
    endmethod
    method removeAbil takes integer abilID returns boolean
        return UnitRemoveAbility(this.dummy, abilID)
    endmethod
    method setAbilLvl takes integer abilID, integer lvl returns nothing
        call SetUnitAbilityLevel(this.dummy, abilID, lvl)
    endmethod
    method incAbilLvl takes integer abilID, integer lvl returns nothing
        call IncUnitAbilityLevel(this.dummy, abilID)
    endmethod
    method decAbilLvl takes integer abilID, integer lvl returns nothing
        call DecUnitAbilityLevel(this.dummy, abilID)
    endmethod
    method issueOrderId takes integer order returns boolean
        return IssueImmediateOrderById(this.dummy, order)
    endmethod
    method issuePointOrderId takes integer order, real x, real y returns boolean
        return IssuePointOrderById(this.dummy, order, x, y)
    endmethod
    method issueTargetOrderId takes integer order, widget targ returns boolean
        return IssueTargetOrderById(this.dummy, order, targ)
    endmethod
endmodule

private module DummyModule
    implement Alloc

    private     static  constant    integer DUMMY_ID            = 'udum'
    private     static  constant    integer DUMMY_ANGLE_COUNT   = 8
    private     static  constant    real    DUMMY_ANGLE         = 360.0 / I2R(DUMMY_ANGLE_COUNT)
    private     static  constant    player  DUMMY_PLAYER        = Player(PLAYER_NEUTRAL_PASSIVE)
    private     static  TableArray  dummyList                   = 0
    private     static  Table       dummyMap                    = 0
    readonly    static  thistype    current                     = 0

    private     timer               recycleTimer
    private     EventResponder      recycleResp
    private     integer             listIndex
    readonly    unit                dummy
    integer     data

    implement DummyModuleOps

    //! textmacro DUMMY_SHOW_UNIT
            call SetUnitOwner(this.dummy, p, true)
            call SetUnitFacing(this.dummy, angle)
            call SetUnitX(this.dummy, x)
            call SetUnitY(this.dummy, y)
            call BlzUnitDisableAbility(this.dummy, 'Aloc', false, false)
            call ShowUnit(this.dummy, true)
            call IssueImmediateOrderById(this.dummy, 851972)
            call PauseUnit(this.dummy, false)
    //! endtextmacro
    //! textmacro DUMMY_HIDE_UNIT
            call PauseUnit(this.dummy, true)
            call IssueImmediateOrderById(this.dummy, 851972)
            call ShowUnit(this.dummy, false)
            call BlzUnitDisableAbility(this.dummy, 'Aloc', true, true)
            call SetUnitX(this.dummy, WorldBounds.minX)
            call SetUnitY(this.dummy, WorldBounds.minY)
            call SetUnitFacing(this.dummy, this.listIndex * DUMMY_ANGLE)
            call SetUnitOwner(this.dummy, DUMMY_PLAYER, true)
    //! endtextmacro

    private static method angle2Index takes real angle returns integer
        set angle               = ModuloReal(angle + DUMMY_ANGLE / 2.0, 360.0)
        return R2I(angle / DUMMY_ANGLE)
    endmethod

    private static method generate takes player p, real x, real y, real angle returns thistype
        local thistype this                     = thistype.allocate()
        set this.listIndex                      = -1
        set this.dummy                          = CreateUnit(p, DUMMY_ID, x, y, angle)
        set dummyMap[GetHandleId(this.dummy)]   = this
        call SetUnitPropWindow(this.dummy, 0.0)
        return this
    endmethod

    static method operator [] takes unit whichDummy returns thistype
        return dummyMap[GetHandleId(whichDummy)]
    endmethod

    private method destroy takes nothing returns nothing
        call dummyMap.remove(GetHandleId(this.dummy))
        call RemoveUnit(this.dummy)

        set this.dummy      = null
        set this.listIndex  = 0
        set this.data       = 0
        call this.deallocate()
    endmethod

    method recycle takes nothing returns nothing
        //  Find nearest index from facing angle
        local integer index                     = -1
        local integer maxIndex                  = 0

        //  Only destroy dummies if they are dead.
        if (not UnitAlive(this.dummy)) then
            call this.destroy()
            return
        endif
        if (this.listIndex >= 0) then
            return
        endif
        set index                               = angle2Index(GetUnitFacing(this.dummy))
        set maxIndex                            = dummyList[index].integer[0] + 1
        set dummyList[index].integer[0]         = maxIndex
        set dummyList[index].integer[maxIndex]  = this
        set this.listIndex                      = index
        set this.data                           = 0
        //! runtextmacro DUMMY_HIDE_UNIT()
    endmethod

    private static method onRecycle takes nothing returns nothing
        local thistype this                     = ReleaseTimer(GetExpiredTimer())
        set current                             = this
        call this.recycleResp.run()
        call this.recycleResp.destroy()
        set current                             = 0
        set this.recycleTimer                   = null
        set this.recycleResp                    = 0
        call QueueUnitAnimation(this.dummy, "stand")
        call this.recycle()
    endmethod

    method recycleTimed takes real delay, code callback returns boolean
        if (this.recycleTimer != null) or (this.listIndex >= 0) then
            return false
        endif
        set this.recycleTimer                   = NewTimerEx(this)
        set this.recycleResp                    = EventResponder.create(callback)
        call SetUnitAnimation(this.dummy, "death")
        call TimerStart(this.recycleTimer, delay, false, function thistype.onRecycle)
        return true
    endmethod

    static method request takes player p, real x, real y, real angle returns thistype
        local thistype this                     = 0
        local integer index                     = thistype.angle2Index(angle)
        if (dummyList[index].integer[0] <= 0) then
            set this                            = thistype.generate(p, x, y, angle)
        else
            set this                            = dummyList[index].integer[dummyList[index].integer[0]]
            set this.listIndex                  = -1
            set dummyList[index].integer[0]     = dummyList[index].integer[0] - 1
            //! runtextmacro DUMMY_SHOW_UNIT()
        endif
        return this
    endmethod

    private static method onInit takes nothing returns nothing
        set dummyList       = TableArray[DUMMY_ANGLE_COUNT]
        set dummyMap        = Table.create()
    endmethod
endmodule

struct Dummy extends array
    implement DummyModule
endstruct

endlibrary