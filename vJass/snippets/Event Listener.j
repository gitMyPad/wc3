library EventListener requires /*

    --------------
    */  Table   /*
    --------------

    --------------
    */  ListT   /*
    --------------

    --------------
    */  Init    /*
    --------------

     -------------------------------------
    |
    |   EventListener   - vJASS
    |
    |-------------------------------------
    |
    |   Originally based on a previous attempt in Pseudo-Var event,
    |   which itself was inspired by jesus4lyf's Event, this
    |   system brings the ability to control the maximum depth of
    |   recursion of custom events, the maximum callback depth of
    |   callback functions within custom events, and the ability
    |   to trace back which callback functions were running at a
    |   certain depth, in addition to the ability to create and
    |   register custom events.
    |
    |   The system allows the unregistration of callbacks, albeit
    |   with some quirks. While an EventListener is executing its
    |   responders (callback functions), any attempts to unregister
    |   a given callback will be delayed up until all of the responders
    |   have been executed and the depth of the EventListener has
    |   returned to 0. However, the specified callback will
    |   not run in subsequent executions. This is to avoid data-race
    |   conditions that may result in the execution of the responders
    |   ending abruptly.
    |
    |   The system also allows the registration of callbacks as well.
    |   When registering a callback function to an event while the
    |   event is executing its responders, the callback function will
    |   NOT be immediately executed as well. However, it will be
    |   executed in subsequent attempts.
    |
    |   Events can also be destroyed. When destroying an event which
    |   is currently executing or is in the callback stack, the event
    |   will suspend ALL subsequent responder (callback) executions.
    |   Thus, it is safe to use even in cases where data-races might
    |   occur.
    |
    |   Also comes with the EventResponder class, which can be
    |   used to execute callback functions.
    |
    |-----------------------------------------------------------------
    |
    |   API
    |
    |-----------------------------------------------------------------
    |
    |   class EventListener {
    |       static method create()
    |       method destroy()
    |           - constructor and destructor functions
    |
    |       method register(code callback) -> EventResponder {int}
    |           - Returns a generated EventResponder associated with callback.
    |
    |       method unregister(EventResponder response) -> bool
    |           - Unregisters the EventResponder from the event.
    |           - Returns false if event is currently in the callback stack.
    |           - Otherwise, returns false if response is not found in
    |             the list.
    |           - Destroys response object if found and returns true/
    |
    |       method run()
    |           - Executes all EventResponders in the list
    |           - Respects each EventResponder's state.
    |
    |       method getMaxRecursionDepth() -> int
    |       method setMaxRecursionDepth(int value)
    |           - Gets and sets the recursion depth of the event.
    |
    |       method getMaxCallbackDepth() -> int
    |       method setMaxCallbackDepth(int value)
    |           - Gets and sets the recursion depth of all callbacks
    |             associated with the event.
    |           - Prevents a callback from exceeding the recursion depth
    |             specified for it, even if the event can recursively
    |             go deeper.
    |
    |       method getCurrentCallback() -> EventResponder {int}
    |           - Returns the most recent EventResponder of the event.
    |
    |       method getDepthCallback(int depth) -> EventResponder {int}
    |           - Returns the EventResponder of the event at the specified
    |             depth.
    |           - Has a time complexity of O(N), so use wisely.
    |
    |       method getCurrentDepth() -> int
    |           - Returns the current depth of the event.
    |   }
    |
    |   class EventResponder {
    |       static method create(code callback)
    |       method destroy()
    |           - constructor and destructor functions
    |       
    |       method refresh(code callback) -> this
    |           - Changes callback function to specified callback.
    |           - Also enables the EventResponder if it was disabled
    |             via enable(false) and vice versa.
    |
    |       method change(code callback) -> this
    |           - Also changes callback function to specified callback.
    |           - Respects the active status of the EventResponder.
    |       
    |       method run() -> this
    |           - Evaluates the trigger handling the callback function.
    |
    |       method enable(bool flag) -> this
    |           - Enables or disables the EventResponder.
    |           - Operates based on active counter.
    |               - An active counter of 1 or higher will require
    |                 more calls to enable(false) to effectively disable
    |                 and vice versa.
    |
    |       method conditionalRun() -> this
    |           - Evaluates the trigger handling the callback function.
    |           - Respects the active status of the EventResponder.
    |
    |       method isEnabled() -> bool
    |           - Returns true if enabled; false otherwise.
    |
    |        ----------------------
    |       |
    |       |       Fields:
    |       |
    |        ----------------------
    |
    |       integer data
    |           - Custom value that can be explicitly defined
    |             by the user.
    |           - Consider this field as private when the
    |             EventResponder is generated by an EventListener.
    |   }
    |   
     -----------------------------------------------------------------
*/

//! runtextmacro DEFINE_LIST("private", "EventResponderList", "integer")

struct EventResponder extends array
    private static TableArray parameterMap  = 0

    implement AllocT

    //  ====================================================    //
    //                    Operator API                          //
    //  ====================================================    //
    method operator data takes nothing returns integer
        return parameterMap[0].integer[this]
    endmethod
    method operator data= takes integer newValue returns nothing
        set parameterMap[0].integer[this] = newValue
    endmethod
    private method clear_data takes nothing returns nothing
        call parameterMap[0].integer.remove(this)
    endmethod
    
    private method operator trigger takes nothing returns trigger
        return parameterMap[1].trigger[this]
    endmethod
    private method operator trigger= takes trigger newTrigger returns nothing
        set parameterMap[1].trigger[this] = newTrigger
    endmethod
    private method clear_trigger takes nothing returns nothing
        call parameterMap[1].trigger.remove(this)
    endmethod

    private method operator activeCount takes nothing returns integer
        return parameterMap[2].integer[this]
    endmethod
    private method operator activeCount= takes integer newValue returns nothing
        set parameterMap[2].integer[this] = newValue
    endmethod
    private method clear_activeCount takes nothing returns nothing
        call parameterMap[2].integer.remove(this)
    endmethod
    
    //  ====================================================    //
    //                      Public API                          //
    //  ====================================================    //
    method destroy takes nothing returns nothing
        if (not parameterMap[1].trigger.has(this)) then
            return
        endif
        call DisableTrigger(this.trigger)
        call DestroyTrigger(this.trigger)
        call this.clear_data()
        call this.clear_trigger()
        call this.clear_activeCount()
        call this.deallocate()
    endmethod
    method refresh takes code newCallback returns thistype
        call DestroyTrigger(this.trigger)
        set this.trigger        = CreateTrigger()
        set this.activeCount    = 1
        call TriggerAddCondition(this.trigger, Condition(newCallback))
        return this
    endmethod
    method change takes code newCallback returns thistype
        local integer prevCount = this.activeCount
        call this.refresh(newCallback)
        set this.activeCount    = prevCount
        if this.activeCount <= 0 then
            call DisableTrigger(this.trigger)
        endif
        return this
    endmethod
    method run takes nothing returns thistype
        call TriggerEvaluate(this.trigger)
        return this
    endmethod
    method enable takes boolean flag returns thistype
        if (flag) then
            set this.activeCount    = this.activeCount + 1
        else
            set this.activeCount    = this.activeCount - 1
        endif
        if this.activeCount == 0 then
            call DisableTrigger(this.trigger)
        elseif this.activeCount == 1 then
            call EnableTrigger(this.trigger)
        endif
        return this
    endmethod
    method conditionalRun takes nothing returns thistype
        if (this.activeCount > 0) then
            call TriggerEvaluate(this.trigger)
        endif
        return this
    endmethod

    //  ====================================================    //
    //                      Getter API                          //
    //  ====================================================    //
    method isEnabled takes nothing returns boolean
        return this.activeCount > 0
    endmethod
    
    //  ====================================================    //
    //                   Constructor API                        //
    //  ====================================================    //
    static method create takes code callback returns thistype
        local thistype this     = allocate()
        set this.trigger        = CreateTrigger()
        set this.activeCount    = 1
        call TriggerAddCondition(this.trigger, Condition(callback))
        return this
    endmethod

    //  ====================================================    //
    private static method init takes nothing returns nothing
        set parameterMap    = TableArray[3]
    endmethod
    implement Init
endstruct

private struct EVLCallbackData extends array
    readonly static constant integer STATUS_CODE_NORMAL         = 0
    readonly static constant integer STATUS_CODE_HALTED         = 1
    readonly static constant integer STATUS_CODE_INTERRUPTED    = 2

    private static EventResponder executor          = 0
    private static Table activeCallbackStack        = 0
    private static Table destroyedCallbackStack     = 0

    //  Value is initialized in EventListener.
    static  code removeCallback                     = null
    static  code destroyCallback                    = null
    readonly static integer totalRecursionDepth     = 0
    readonly static thistype array activeObject
    readonly static EventResponder array activeCallback

    readonly static thistype deadObject             = 0
    
    integer destroyStack
    integer recursionDepth
    integer maxRecursionDepth
    integer maxCallbackStackDepth

    static method operator [] takes integer this returns thistype
        return thistype(this)
    endmethod
    static method operator curCallback takes nothing returns EventResponder
        return activeCallback[totalRecursionDepth]
    endmethod
    static method updateCallback takes EventResponder response returns nothing
        local EventResponder prevResponse       = activeCallback[totalRecursionDepth]
        if (prevResponse != 0) then
            set activeCallbackStack.integer[prevResponse]   = activeCallbackStack.integer[prevResponse] - 1
            if (activeCallbackStack.integer[prevResponse] <= 0) then
                call activeCallbackStack.remove(prevResponse)
                if destroyedCallbackStack.integer[prevResponse] > 0 then
                    call destroyedCallbackStack.remove(prevResponse)
                    call executor.refresh(removeCallback).run()
                endif
            endif
        endif
        set activeCallback[totalRecursionDepth] = response
        if (response != 0) then
            set activeCallbackStack.integer[response]   = activeCallbackStack.integer[response] + 1
        endif
    endmethod
    static method execute takes nothing returns integer
        local thistype this             = activeObject[totalRecursionDepth]
        local EventResponder response   = activeCallback[totalRecursionDepth]

        //  When the instance is destroyed, prevent any future executions.
        //  When a callback is queued for termination, prevent
        //  subsequent execution.
        if (this.destroyStack > 0) then
            return STATUS_CODE_HALTED
        endif
        if (destroyedCallbackStack.integer[response] > 0) then
            return STATUS_CODE_INTERRUPTED
        endif
        //  Prevent an infinite loop by checking through here.
        if ((this.maxRecursionDepth > 0) and (this.recursionDepth > this.maxRecursionDepth)) or /*
        */ ((this.maxCallbackStackDepth > 0) and (activeCallbackStack.integer[response] > this.maxCallbackStackDepth)) then
            return STATUS_CODE_INTERRUPTED
        endif
        call response.conditionalRun()
        return STATUS_CODE_NORMAL
    endmethod

    static method safeCallbackRemove takes thistype this, EventResponder response returns integer
        //  This function should return a status code.
        //  Check if EventResponder is currently an active instance.
        if activeCallbackStack.integer[response] > 0 then
            //  Response is definitely active.
            set destroyedCallbackStack.integer[response]    = destroyedCallbackStack.integer[response] + 1
            return 1
        endif
        return 0
    endmethod
    static method safeDestroy takes thistype this returns integer
        //  This function should return a status code.
        //  Check if EventResponder is currently an active instance.
        set this.destroyStack   = this.destroyStack + 1
        return 0
    endmethod

    static method push takes thistype this returns nothing
        set totalRecursionDepth = totalRecursionDepth + 1
        set this.recursionDepth = this.recursionDepth + 1
        set activeObject[totalRecursionDepth]   = this
    endmethod
    static method pop takes thistype this returns boolean
        local thistype lastDeadObj              = deadObject
        set activeObject[totalRecursionDepth]   = 0
        set activeCallback[totalRecursionDepth] = 0
        set this.recursionDepth = this.recursionDepth - 1
        set totalRecursionDepth = totalRecursionDepth - 1
        if (this.destroyStack > 0) and (this.recursionDepth < 1) then
            set deadObject      = this
            call executor.refresh(destroyCallback).run()
            set deadObject      = lastDeadObj
            return false
        endif
        return true
    endmethod
    static method queryCurrentCallback takes thistype this returns EventResponderListItem
        local integer i = totalRecursionDepth
        if this.recursionDepth < 1 then
            return 0
        endif
        loop
            exitwhen (i < 1) or (activeObject[i] == this)
            set i   = i - 1
        endloop
        return activeCallback[i]
    endmethod
    static method queryDepthCallback takes thistype this, integer depth returns EventResponderListItem
        local integer i = 1
        if ((depth < 1) or (depth > this.maxRecursionDepth) or /*
        */  (this.recursionDepth < 1)) then
            return 0
        endif
        loop
            exitwhen (i > totalRecursionDepth)
            if (activeObject[i] == this) then
                set depth   = depth - 1
                exitwhen (depth < 1)
            endif
            set i   = i + 1
        endloop
        if (i > totalRecursionDepth) then
            return 0
        endif
        return activeCallback[i]
    endmethod

    method isActive takes nothing returns boolean
        return this.recursionDepth > 0
    endmethod

    private static method init takes nothing returns nothing
        set activeCallbackStack     = Table.create()
        set destroyedCallbackStack  = Table.create()
        set executor                = EventResponder.create(null)
    endmethod
    implement Init
endstruct

struct EventListener extends array
    implement Alloc

    private EventResponderList list

    //  ====================================================    //
    //                   Operational API                        //
    //  ====================================================    //
    method register takes code callback returns EventResponder
        local EventResponder response   = EventResponder.create(callback)
        set response.data               = this.list.push(response).last
        return response
    endmethod
    method unregister takes EventResponder response returns boolean
        local boolean result    = false
        if EVLCallbackData(this).isActive() then
            call EVLCallbackData.safeCallbackRemove(this, response)
            return false
        endif
        set result = this.list.erase(response.data)
        if result then
            call response.destroy()
        endif
        return result
    endmethod
    method run takes nothing returns thistype
        local EventResponderListItem iter       = this.list.first
        local EventResponderListItem iterLast   = this.list.last
        call EVLCallbackData.push(this)
        loop
            call EVLCallbackData.updateCallback(EventResponder(iter.data))
            exitwhen (EVLCallbackData.execute() == EVLCallbackData.STATUS_CODE_HALTED)
            exitwhen (iter  == iterLast)
            set iter        = iter.next
        endloop
        call EVLCallbackData.updateCallback(0)
        //  Depending on whether the instance is destroyed mid-execution
        //  or not, return a valid result regardless.
        if (not EVLCallbackData.pop(this)) then
            return 0
        endif
        return this
    endmethod

    //  ====================================================    //
    //                   Constructor API                        //
    //  ====================================================    //
    static method create takes nothing returns thistype
        local thistype this = allocate()
        set this.list       = EventResponderList.create()
        set EVLCallbackData(this).maxRecursionDepth     = 0
        set EVLCallbackData(this).maxCallbackStackDepth = 0
        return this
    endmethod
    private method destroyResponderList takes nothing returns nothing
        local EventResponderListItem iter   = this.list.first
        local EventResponder response       = EventResponder(iter.data)
        loop
            exitwhen this.list.empty()
            call this.list.erase(response.data)
            call response.destroy()

            set iter        = this.list.first
            set response    = EventResponder(iter.data)
        endloop
        call this.list.destroy()
    endmethod
    method destroy takes nothing returns nothing
        if this.list == 0 then
            return
        endif
        if EVLCallbackData(this).isActive() then
            call EVLCallbackData.safeDestroy(this)
            return
        endif
        call this.destroyResponderList()
        set EVLCallbackData(this).destroyStack          = 0
        set EVLCallbackData(this).recursionDepth        = 0
        set EVLCallbackData(this).maxRecursionDepth     = 0
        set EVLCallbackData(this).maxCallbackStackDepth = 0
        set this.list   = 0
        call this.deallocate()
    endmethod

    //  ====================================================    //
    //              Getter and Setter API                       //
    //  ====================================================    //
    method getMaxRecursionDepth takes nothing returns integer
        return EVLCallbackData(this).maxRecursionDepth
    endmethod
    method setMaxRecursionDepth takes integer depth returns nothing
        set EVLCallbackData(this).maxRecursionDepth = IMaxBJ(depth, 0)
    endmethod

    method getMaxCallbackDepth takes nothing returns integer
        return EVLCallbackData(this).maxCallbackStackDepth
    endmethod
    method setMaxCallbackDepth takes integer depth returns nothing
        set EVLCallbackData(this).maxCallbackStackDepth = IMaxBJ(depth, 0)
    endmethod

    method getCurrentCallback takes nothing returns EventResponder
        return EVLCallbackData.queryCurrentCallback(this)
    endmethod
    method getDepthCallback takes integer depth returns EventResponder
        return EVLCallbackData.queryDepthCallback(this, depth)
    endmethod
    method getCurrentDepth takes nothing returns integer
        return EVLCallbackData(this).recursionDepth
    endmethod

    //  ====================================================    //
    //              Dynamic Class instances                     //
    //  ====================================================    //
    static method operator event takes nothing returns thistype
        return thistype(EVLCallbackData.activeObject[EVLCallbackData.totalRecursionDepth])
    endmethod
    static method operator callback takes nothing returns EventResponder
        return EVLCallbackData.activeCallback[EVLCallbackData.totalRecursionDepth]
    endmethod

    //  ====================================================    //
    private static method onRemoveCallback takes nothing returns nothing
        local thistype this             = thistype(EVLCallbackData.activeObject[EVLCallbackData.totalRecursionDepth])
        local EventResponder response   = EVLCallbackData.activeCallback[EVLCallbackData.totalRecursionDepth]
        if this.list.remove(EventResponderListItem(response.data)) then
            call response.destroy()
        endif
    endmethod
    private static method onDestroyCallback takes nothing returns nothing
        local thistype this = thistype(EVLCallbackData.deadObject)
        call this.destroy()
    endmethod

    private static method init takes nothing returns nothing
        set EVLCallbackData.removeCallback  = function thistype.onRemoveCallback
        set EVLCallbackData.destroyCallback = function thistype.onDestroyCallback
    endmethod
    implement Init
endstruct

endlibrary