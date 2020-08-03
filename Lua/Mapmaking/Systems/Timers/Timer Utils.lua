local tb        = {[0]=0}

tb._destroy     = DestroyTimer
tb._fields      = {}
tb._data        = {}

--  For doAfter, doUntil, and doRepeat
--  tb[1], tb[2] ... tb[n] = {}
tb._callback    = {}
tb._condition   = {}
tb._entrycount  = {}
tb._fieldcount  = 0

function GetTimerData(whichtimer)
    return tb._data[whichtimer]
end
function SetTimerData(whichtimer, data)
    tb._data[whichtimer]  = data
end

local function alloc_entries(whichtimer, ...)
    local j = select('#', ...)
    while tb._fieldcount < j do
        tb._fieldcount      = tb._fieldcount + 1
        tb[tb._fieldcount]  = {}
    end
    tb._entrycount[whichtimer]  = j
    if j < 1 then return;
    end

    local i = 1
    while i <= j do
        tb[i][whichtimer]   = select(i, ...)
        i = i + 1
    end
end
local function pop_entries(whichtimer)
    local j = #tb._fields
    while j > 0 do
        if tb[j][whichtimer] then
            tb._fields[j]   = tb[j][whichtimer]
        else
            tb._fields[j]   = nil
        end
        j = j - 1
    end
    while j < tb._entrycount[whichtimer] do
        j               = j + 1
        tb._fields[j]   = tb[j][whichtimer]
    end
end
local function clear_entries(whichtimer)
    while tb._entrycount[whichtimer] > 0 do
        local j = tb._entrycount[whichtimer]
        tb[j][whichtimer]           = nil
        tb._entrycount[whichtimer]  = tb._entrycount[whichtimer] - 1
    end
    tb._entrycount[whichtimer]  = nil
    tb._callback[whichtimer]    = nil
    tb._condition[whichtimer]   = nil
end
local function assign_callback(whichtimer, func, cond)
    tb._callback[whichtimer]    = func
    tb._condition[whichtimer]   = cond
end

function DestroyTimer(whichtimer)
    tb._destroy(whichtimer)
    tb._data[whichtimer]  = nil
    if tb._callback[whichtimer] then
        clear_entries(whichtimer)
    end
end

function tb.singular_callback()
    local t = GetExpiredTimer()
    
    pop_entries(t)
    if tb._entrycount[t] > 0 then
        tb._callback[t](table.unpack(tb._fields))
    else
        tb._callback[t]()
    end

    clear_entries(t)
    DestroyTimer(t)
end
function tb.repeated_callback()
    local t         = GetExpiredTimer()
    local cond      = tb._condition[t]
    local is_func   = is_function(cond)

    pop_entries(t)
    if (is_func and not cond()) or ((not is_func) and cond) then
        if tb._entrycount[t] > 0 then
            tb._callback[t](table.unpack(tb._fields))
        else
            tb._callback[t]()
        end
        return
    end
    PauseTimer(t)
    clear_entries(t)
    DestroyTimer(t)
end

function doAfter(dur, func, ...)
    if dur < 0. then
        func(...)
        return
    end

    local t = CreateTimer()
    alloc_entries(t, ...)
    assign_callback(t, func)

    TimerStart(t, dur, false, tb.singular_callback)
    return t
end
function doUntil(intv, cond, func, ...)
    local is_func = is_function(cond)
    if intv < 0. then
        if (is_func and not cond()) or ((not is_func) and cond) then
            func(...)
        end
        return
    end

    local t = CreateTimer()
    alloc_entries(t, ...)
    assign_callback(t, func, cond)
    TimerStart(t, intv, true, tb.repeated_callback)
    return t
end
function doRepeat(intv, func, ...)
    return doUntil(intv, true, func, ...)
end