library GTimer requires TimerUtils, EventListener, Init

globals
    //  Use this for things that do not need to be too fluid
    //  in order to progress, such as auras.
    constant integer UPDATE_TICK    = 10
    //  Use this for things that demand fluidity in movement.
    constant integer GAME_TICK      = 32
endglobals

struct GTimer extends array
    private static boolean array isRegistered
    private static code onTimerCallback = null

    readonly real timeout
    private timer timer
    private EventListener handler
    private integer activeCallbacks

    static method operator [] takes integer tick returns GTimer
        return GTimer(IMaxBJ(tick, 0))
    endmethod

    method unregister takes EventResponder resp returns nothing
        call this.handler.unregister(resp)
    endmethod

    method releaseCallback takes EventResponder resp returns GTimer
        if (not resp.isEnabled()) then
            return this
        endif
        call resp.enable(false)
        set this.activeCallbacks    = this.activeCallbacks - 1
        if (this.activeCallbacks == 0) then
            call PauseTimer(this.timer)
        endif
        return this
    endmethod

    method requestCallback takes EventResponder resp returns GTimer
        if (resp.isEnabled()) then
            return this
        endif
        call resp.enable(true)
        set this.activeCallbacks    = this.activeCallbacks + 1
        if (this.activeCallbacks == 1) then
            call TimerStart(this.timer, this.timeout, true, GTimer.onTimerCallback)
        endif
        return this
    endmethod
    
    static method register takes integer tick, code callback returns EventResponder
        local GTimer this           = GTimer(tick)
        local EventResponder resp   = 0
        if (tick < 0) then
            return EventResponder(0)
        endif
        if (not GTimer.isRegistered[tick]) then
            set GTimer.isRegistered[tick]   = true
            set this.timeout                = 1.0 / I2R(tick)
            set this.timer                  = NewTimerEx(tick)
            set this.handler                = EventListener.create()
        endif
        set resp    = this.handler.register(callback)
        call resp.enable(false)
        return resp
    endmethod

    //  ==============================================================
    private static method onTimerExecute takes nothing returns nothing
        local GTimer this   = GetTimerData(GetExpiredTimer())
        call this.handler.run()
    endmethod

    private static method init takes nothing returns nothing
        set GTimer.onTimerCallback    = function GTimer.onTimerExecute
    endmethod
    implement Init
endstruct

endlibrary