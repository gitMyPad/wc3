library VolatileStruct  /*

     -------------------------------------------------------------------------------------
    |
    |   ----------------------------
    |       VolatileStruct          
    |           v.1.0.0
    |   ----------------------------
    |           - MyPad
    |
    |-------------------------------------------------------------------------------------
    |
    |   A module-based script that facilitates the automatic handling/cleanup of objects
    |   considered volatile. This also provides the allocation and deallocation scheme for
    |   the struct. In doing so, the module assumes that the implementing struct does not
    |   already contain these methods.
    |
    |   The module also implements two private pointers (next and prev) for exclusive use
    |   in the iteration of unlocked instances for cleanup.
    |
    |   Definition of Term/s:
    |       volatile - An object with an unpredictable (often short) lifetime that the
    |                  user is not expected to clean up by themselves.
    |
    |-------------------------------------------------------------------------------------
    |
    |   Modules:
    |
    |   module VStruct {
    |       static method allocate() -> thistype
    |           - Generates a new object, and starts up the cleanup timer
    |             if it hasn't already.
    |
    |       method locked() -> bool
    |           - Returns true if object is locked into existence.
    |           - The locking mechanism is based on a counter. If
    |             the counter value is 0 or less, the object is
    |             considered to be unlocked and will be picked up by
    |             the cleanup timer.
    |
    |       method lock(bool flag)
    |           - Locks/unlocks the object into/from existence.
    |             
    |       interface method onCleanup()
    |           - An optional method that runs upon the object
    |             being destroyed.
    |   }
    |
     -------------------------------------------------------------------------------------
*/

module VStruct
    private thistype allocHandler

    private integer lockCount

    private static integer  listSize        = 0
    private static timer    listTimer       = null
    private static code     listAction      = null

    private thistype        next
    private thistype        prev
    private boolean         inList
    private boolean         cleaningUp

    static if not thistype.RECYCLE_INTERVAL.exists then
    static constant method RECYCLE_INTERVAL takes nothing returns real
        return 180.0
    endmethod
    endif

    static if not thistype.RECYCLE_INSTANCES.exists then
    static constant method RECYCLE_INSTANCES takes nothing returns integer
        return 20
    endmethod
    endif
    
    method locked takes nothing returns boolean
        return (not this.cleaningUp) and (this.lockCount > 0)
    endmethod

    method lock takes boolean flag returns nothing
        local integer incr      = IntegerTertiaryOp(flag, 1, -1)
        local boolean affected  = false
        local integer steps     = 0
        local real remaining    = 0.0
        if (this.cleaningUp) then
            return
        endif
        set this.lockCount      = this.lockCount + incr
        set affected            = ((flag) and (this.lockCount == 1)) or /*
                                */((not flag) and (this.lockCount == 0))
        if ((flag) and (this.lockCount == 1)) then
            set this.inList     = false
            set this.next.prev  = this.prev
            set this.prev.next  = this.next
            set this.prev       = 0
            set this.next       = 0
            set listSize        = listSize - 1
            if (listSize == 0) then
                call PauseTimer(listTimer)
            endif

        elseif ((not flag) and (this.lockCount == 0)) then
            set this.inList     = true
            set this.next       = 0
            set this.prev       = this.next.prev
            set this.prev.next  = this
            set this.next.prev  = this
            set listSize        = listSize + 1
            if (listSize == 1) then
                call TimerStart(listTimer, RECYCLE_INTERVAL(), false, listAction)
            endif
        endif
        if (not affected) or (ModuloInteger(listSize, RECYCLE_INSTANCES()) != 0) then
            return
        endif
        set steps               = IMaxBJ(listSize / RECYCLE_INSTANCES(), 1)
        set remaining           = TimerGetRemaining(listTimer) * RECYCLE_INTERVAL() / I2R(steps)
        call PauseTimer(listTimer)
        call TimerStart(listTimer, 0.0, false, null)
        call PauseTimer(listTimer)
        call TimerStart(listTimer, remaining, false, listAction)
    endmethod

    private method destroy takes nothing returns nothing
        if (this.allocHandler != 0) then
            return
        endif
        if (this.inList) then
            set this.inList                 = false
            set this.next.prev              = this.prev
            set this.prev.next              = this.next
            set this.prev                   = 0
            set this.next                   = 0
            set listSize                    = listSize - 1
        endif
        set this.lockCount                  = 0
        set this.cleaningUp                 = true
        static if thistype.onCleanup.exists then
            call this.onCleanup()
        endif
        set this.cleaningUp                 = false
        set this.allocHandler               = thistype(0).allocHandler
        set thistype(0).allocHandler        = this
    endmethod

    static method allocate takes nothing returns thistype
        local thistype this                 = thistype(0).allocHandler
        if (this.allocHandler == 0) then
            set this                        = integer(this) + 1
            set thistype(0).allocHandler    = this
        else
            set thistype(0).allocHandler    = this.allocHandler
            set this.allocHandler           = 0
        endif
        set this.lockCount                  = 1
        call this.lock(false)
        return this
    endmethod

    private static method onRemoveObjects takes nothing returns nothing
        local thistype iter                 = thistype(0).next
        local thistype this                 = iter
        local integer removeCount           = 0
        local integer steps                 = 0
        local real remaining                = 0.0
        loop
            exitwhen (iter == 0) or (removeCount >= RECYCLE_INSTANCES())
            set iter                        = iter.next
            call this.destroy()
            set removeCount                 = removeCount + 1
            set this                        = iter
        endloop
        if (listSize <= 0) then
            return
        endif
        set steps                           = listSize / RECYCLE_INSTANCES()
        set remaining                       = RECYCLE_INTERVAL() / I2R(steps)
        call PauseTimer(listTimer)
        call TimerStart(listTimer, 0.0, false, null)
        call PauseTimer(listTimer)
        call TimerStart(listTimer, remaining, false, listAction)
    endmethod

    private static method onInit takes nothing returns nothing
        set listTimer                       = CreateTimer()
        set listAction                      = function thistype.onRemoveObjects
    endmethod
endmodule

endlibrary