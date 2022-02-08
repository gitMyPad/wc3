library Init

module Init
    private static method onTimerInit takes nothing returns nothing
        call PauseTimer(GetExpiredTimer())
        call DestroyTimer(GetExpiredTimer())
        static if thistype.timerInit.exists then
            call thistype.timerInit()
        endif
    endmethod
    private static method onInit takes nothing returns nothing
        static if thistype.timerInit.exists then
            local timer t = CreateTimer()
            call TimerStart(t, 0.00, false, function thistype.onTimerInit)
            set t = null
        endif
        static if thistype.init.exists then
            call thistype.init()
        endif
    endmethod
endmodule

endlibrary