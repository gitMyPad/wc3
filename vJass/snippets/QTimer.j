library QTimer requires /*

    ==================
    */  Table,      /*
    ==================
        - Bribe
        - link: https://www.hiveworkshop.com/threads/snippet-new-table.188084/

    ==================
    */  Alloc,      /*
    ==================
        - Sevion
        - link: https://www.hiveworkshop.com/threads/snippet-alloc.192348/

    ==================
    */  ListT,      /*
    ==================
        - Linked list library custom built for this system.
        - Slightly modified to provide more features than the original.

     ===================
    |                   |
    |   QTimer :        |
    |                   |
    |=======================================================================
    |
    |    A Timer library dedicated to providing queued timer functionality
    |    within a single object. Useful for creating engaging cinematics,
    |    or for creating meaningful queue-based game mechanics.
    |
    |    A notable example is Dota's Burning Spear (Huskar). This mechanic
    |    deals damage over time and stacks indefinitely. This system can
    |    perfectly recreate that mechanic with a bit of ingenuity, and in
    |    the test map, a sample script is shown demonstrating the Dota 2's
    |    iteration of Burning Spear.
    |
    |=======================================================================
    |           |
    |   API     |
    |           |
    |=======================================================================
    |
    |   QTimer.create()
    |       - Creates a new QTimer instance.
    |
    |   QTimer(this).destroy()
    |       - Destroys the QTimer instance. This also causes any lingering
    |         callback to be executed immediately. The number of times the
    |         callback "executes" is provided by the static member curCount.
    |       - Can safely be called while a callback function is being executed.
    |
    |   QTimer(this).repeat(real dur, code callback, integer data, integer count)
    |       - Causes the QTimer instance to repeat the callback function
    |         at most <count> times. If count is <= 0, the callback function
    |         will be repeated indefinitely.
    |       - When the QTimer instance is destroyed, callback functions which
    |         repeat indefinitely will execute only once. Callback functions
    |         which repeat for a certain number of times will be executed
    |         for the remaining amount of times.
    |
    |   QTimer(this).start(real dur, code callback, integer data)
    |       - A wrapper for QTimer(this).repeat with 1 as the last parameter.
    |
    |   QTimer(this).pause()
    |       - Pauses the QTimer. 
    |
    |   QTimer(this).resume()
    |       - Resumes the QTimer if there are any remaining callbacks to
    |         be executed and if the QTimer has already started.
    |
    |===============
    |               |
    |   Members     |
    |               |
    |=======================================================================
    |
    |   QTimer(this).paused
    |       - Not to be confused with the method, this tells the user
    |         if the timer is currently paused or not.
    |
    |   QTimer(this).elapsed    <operator>
    |       - This returns the exact amount of time that has elapsed
    |         since the start of the timer (does not count time when
    |         it is paused.)
    |
     =======================================================================
*/

private keyword QTimerListItem

private function IsEqual takes real a, real b returns boolean
    return RAbsBJ(a - b) <= 0.0001
endfunction

//  This module is implemented by the generated struct QTimerList
//  provided it exists.
private module QTimerListExtras
    method switch takes QTimerListItem node, QTimerListItem other returns thistype
        local QTimerListItem temp   = node.prev
        local QTimerListItem oTemp  = other.prev
        if (not this.inList(node)) or (not this.inList(other)) then
            return this
        endif
        //  Consider the case when both nodes are adjacent to each other
        if (node.next == other) or (node.prev == other) then
            if (node.next == other) then
                set other.prev  = node.prev
                set node.next   = other.next
                set node.prev   = other
                set other.next  = node
            else
                set node.prev   = other.prev
                set other.next  = node.next
                set other.prev  = node
                set node.next   = other
            endif
        else
            set temp.next       = node.next
            set oTemp.next      = other.next
            set node.next       = oTemp.next
            set other.next      = temp.next
            set node.prev       = oTemp
            set other.prev      = temp
        endif
        set node.next.prev  = node
        set node.prev.next  = node
        set other.next.prev = other
        set other.prev.next = other
        return this
    endmethod
    method move takes QTimerListItem node, QTimerListItem other, boolean shift returns thistype
        if (not this.inList(node)) or (not this.inList(other)) then
            return this
        endif
        set node.next.prev  = node.prev
        set node.prev.next  = node.next
        if shift then
            set node.next   = other.next
            set node.prev   = other
        else
            set node.next   = other
            set node.prev   = other.prev
        endif
        set node.next.prev  = node
        set node.prev.next  = node
        return this
    endmethod
endmodule

//! runtextmacro DEFINE_LIST("private", "QTimerList", "integer")

private module QInit
    private static method onInit takes nothing returns nothing
        call thistype.init()
    endmethod
endmodule

private struct QTimerNode extends array
    implement Alloc

    private boolean destroying
    QTimer          parent
    QTimerListItem  ptr
    real            timeStamp
    real            duration
    trigger         callback
    integer         data
    integer         ticks
    integer         executions

    static method create takes nothing returns thistype
        local thistype this     = thistype.allocate()
        set this.callback       = CreateTrigger()
        return this
    endmethod

    method destroy takes nothing returns nothing
        if this.callback == null then
            return
        endif
        call DestroyTrigger(this.callback)
        set this.parent     = 0
        set this.ptr        = 0
        set this.data       = 0
        set this.ticks      = 0
        set this.executions = 0
        set this.timeStamp  = 0.0
        set this.duration   = 0.0
        set this.callback   = null
        call this.deallocate()
    endmethod
endstruct

struct QTimer extends array
    private static constant boolean DEBUG_ALLOC = true
    implement Alloc

    private static Table timerMap   = 0

    //  state members
    readonly static thistype current    = 0
    readonly static integer  curNode    = 0
    readonly static integer  curData    = 0
    readonly static integer  curCount   = 0
    readonly static integer  execCount  = 0
    static   boolean stopExecution      = false

    //  class members
    private     QTimerList list
    private     real       curDur
    private     timer      timer
    private     boolean    inCallback
    private     boolean    started
    private     boolean    destroying
    readonly    boolean    paused
    boolean     singleton

    private method sort takes QTimerNode obj returns nothing
        local QTimerListItem iter   = 0
        local QTimerListItem temp   = 0
        local QTimerNode comp       = 0

        if this.list.size() < 1 then
            set obj.ptr     = this.list.push(obj).last
            return
        endif
        if QTimerNode(this.list.last.data).timeStamp <= obj.timeStamp then
            set obj.ptr     = this.list.push(obj).last
            return
        elseif QTimerNode(this.list.first.data).timeStamp > obj.timeStamp then
            set obj.ptr     = this.list.unshift(obj).first
            return
        endif
        set iter    = this.list.last.prev
        set comp    = QTimerNode(iter.data)
        loop
            exitwhen this.list.terminated(iter)
            if comp.timeStamp >= obj.timeStamp then
                exitwhen true
            endif
            set iter    = iter.prev
            set comp    = QTimerNode(iter.data)
        endloop
        set obj.ptr     = this.list.push(obj).last
        call this.list.move(obj.ptr, iter, true)
    endmethod

    private method execute takes QTimerNode obj, integer count, integer data, trigger callback returns boolean
        local thistype prevCur      = thistype.current
        local integer prevData      = thistype.curData
        local integer prevCount     = thistype.curCount
        local integer prevExec      = thistype.execCount
        local integer prevNode      = thistype.curNode
        local boolean prevStop      = thistype.stopExecution
        local boolean result
        set thistype.current        = this
        set thistype.curData        = data
        set thistype.curCount       = count
        set thistype.stopExecution  = prevStop
        set thistype.execCount      = obj.executions
        set thistype.curNode        = obj

        call TriggerEvaluate(callback)
        set result                  = thistype.stopExecution

        set thistype.curNode        = prevNode
        set thistype.execCount      = prevExec
        set thistype.stopExecution  = prevStop
        set thistype.current        = prevCur
        set thistype.curData        = prevData
        set thistype.curCount       = prevCount
        return result
    endmethod

    method operator elapsed takes nothing returns real
        if this.inCallback then
            return this.curDur
        endif
        return this.curDur + TimerGetElapsed(this.timer)
    endmethod

    private method removeList takes nothing returns nothing
        local QTimerListItem iter   = 0
        local QTimerNode obj        = 0
        local QTimerNode comp       = 0
        local integer    count      = 0
        local QTimerList list
        if this.list == 0 then
            return
        endif
        set list        = this.list
        set this.list   = 0
        if list.size() < 1 then
            call list.destroy()
            return
        endif
        if this.singleton then
            set iter            = this.list.first
            set obj             = QTimerNode(iter.data)
            set count           = IMaxBJ(obj.ticks, 1)

            set iter            = iter.next
            set comp            = QTimerNode(iter.data)
            loop
                exitwhen list.terminated(iter)
                set iter        = iter.next
                set count       = count + IMaxBJ(comp.ticks, 1)

                call list.erase(comp.ptr)
                call comp.destroy()
                set comp        = QTimerNode(iter.data)
            endloop
            set obj.executions  = obj.executions + count
            set obj.ticks       = 0
            call list.erase(obj.ptr)
            call this.execute(obj, list.size(), obj.data, obj.callback)
            call obj.destroy()
            call list.destroy()
            return
        endif
        loop
            exitwhen list.empty()
            set obj             = QTimerNode(list.last.data)
            set count           = IMaxBJ(obj.ticks, 1)
            set obj.executions  = obj.executions + count
            call list.erase(obj.ptr)
            call this.execute(obj, count, obj.data, obj.callback)
            call obj.destroy()
        endloop
        call list.destroy()
    endmethod

    method destroy takes nothing returns nothing
        if this.timer == null then
            return
        endif
        if this.inCallback then
            set this.destroying = true
            return
        endif
        call PauseTimer(this.timer)
        call DestroyTimer(this.timer)
        set this.timer      = null

        call this.removeList()
        call thistype.timerMap.remove(GetHandleId(this.timer))

        set this.curDur     = 0.0
        set this.inCallback = false
        set this.started    = false
        set this.destroying = false
        set this.paused     = false
        set this.singleton  = false
        call this.deallocate()
    endmethod

    private method processOnElapsed takes QTimerNode obj returns nothing
        local real stamp        = obj.timeStamp
        local boolean interrupt

        set obj.ticks           = IMaxBJ(obj.ticks - 1, -1)
        set obj.executions      = obj.executions + 1
        call this.list.erase(obj.ptr)

        set interrupt           = this.execute(obj, 1, obj.data, obj.callback)
        if (this.destroying) or (obj.ticks == 0) or /*
        */ (interrupt) then
            call obj.destroy()
            return
        endif

        set obj.timeStamp       = stamp + obj.duration
        call this.sort(obj)
    endmethod

    private static method onElapsed takes nothing returns nothing
        local thistype this     = thistype.timerMap[GetHandleId(GetExpiredTimer())]
        local QTimerNode obj    = 0
        local QTimerNode comp   = 0
        local real stamp        = 0.0
        set this.curDur         = this.curDur + TimerGetTimeout(this.timer)

        set this.inCallback     = true
        set obj                 = QTimerNode(this.list.first.data)
        set stamp               = obj.timeStamp
        call this.processOnElapsed(obj)
        loop
            exitwhen this.list.empty() or this.destroying
            set comp            = QTimerNode(this.list.first.data)
            if not IsEqual(stamp, comp.timeStamp) then
                exitwhen true
            endif
            call this.processOnElapsed(comp)
        endloop
        set this.inCallback     = false

        if this.destroying then
            call this.destroy()
            return
        endif
        if this.paused then
            return
        endif
        if not this.list.empty() then
            set obj             = QTimerNode(this.list.first.data)
            call TimerStart(this.timer, obj.timeStamp - this.curDur, false, function thistype.onElapsed)
            return
        endif
        set this.started        = false
        set this.paused         = true
        set this.curDur         = 0.0
    endmethod

    method pause takes nothing returns boolean
        if (this.paused) or (this.destroying) then
            return false
        endif
        set this.paused = true
        if (not this.inCallback) then
            set this.curDur = this.curDur + TimerGetElapsed(this.timer)
        endif
        call PauseTimer(this.timer)
        call TimerStart(this.timer, 0.00, false, null)
        call PauseTimer(this.timer)
        return true
    endmethod

    method resume takes nothing returns boolean
        local QTimerNode obj    = 0
        if (not this.started) or (this.destroying) or /*
        */ (not this.paused) then
            return false
        endif
        set obj         = QTimerNode(this.list.first.data)
        set this.paused = false
        call TimerStart(this.timer, obj.timeStamp - this.curDur, false, function thistype.onElapsed)
        return true
    endmethod

    method repeat takes real dur, code callback, integer data, integer count returns boolean
        local QTimerNode obj    = 0
        //  When the number of ticks is less than 0, the callback
        //  will repeat indefinitely.
        if count <= 0 then
            set count   = -1
        endif
        if (this.timer == null) or (this.destroying) then
            return false
        endif
        set this.paused     = false
        set this.started    = true
        
        set dur             = RMaxBJ(dur, 0.0)
        set obj             = QTimerNode.create()
        set obj.duration    = dur
        set obj.timeStamp   = dur + this.elapsed
        set obj.parent      = this
        set obj.data        = data
        set obj.ticks       = count
        call TriggerAddCondition(obj.callback, Condition(callback))
        call this.sort(obj)

        if (not this.inCallback) then
            call this.pause()
            call this.resume()
        endif
        return true
    endmethod

    method start takes real dur, code callback, integer data returns boolean
        return this.repeat(dur, callback, data, 1)
    endmethod

    static method create takes nothing returns QTimer
        local QTimer this                       = QTimer.allocate()
        set this.list                           = QTimerList.create()
        set this.timer                          = CreateTimer()
        set this.curDur                         = 0.0
        set this.paused                         = true
        set this.started                        = false
        set this.inCallback                     = false
        set timerMap[GetHandleId(this.timer)]   = this
        return this
    endmethod

    private static method init takes nothing returns nothing
        set thistype.timerMap   = Table.create()
    endmethod
    implement QInit
endstruct

endlibrary