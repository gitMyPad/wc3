library TimerUtils requires /*

    --------------
    */  Table   /*
    --------------

    --------------
    */  Init    /*
    --------------

*/

globals
    private Table tData         = 0
    private timer tempTimer     = null
endglobals

private struct S extends array
    private static method init takes nothing returns nothing
        set tData   = Table.create()
    endmethod
    implement Init
endstruct

function NewTimerEx takes integer data returns timer
    set tempTimer   = CreateTimer()
    set tData[GetHandleId(tempTimer)]   = data
    return tempTimer
endfunction

function NewTimer takes nothing returns timer
    return NewTimerEx(0)
endfunction

function ReleaseTimer takes timer t returns integer
    local integer data  = tData[GetHandleId(t)]
    call tData.remove(GetHandleId(t))
    call PauseTimer(t)
    call DestroyTimer(t)
    return data
endfunction

function GetTimerData takes timer t returns integer
    return tData[GetHandleId(t)]
endfunction

function SetTimerData takes timer t, integer value returns nothing
    set tData[GetHandleId(t)] = value
endfunction

endlibrary