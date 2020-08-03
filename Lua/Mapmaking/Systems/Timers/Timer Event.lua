local tb    = protected_table({
    _stamp  = {}
})
TimerEvent  = setmetatable({}, tb)

--  iters refers to number of iterations per second.
--  iters will always be coerced to an integer
local function toint(iters)
    return (type(iters) ~= 'number' and 1) or math.floor(iters + 0.5)
end
function tb.register(iters, func)
    iters   = toint(iters)

    --  Initialize tb._stamp[iters] if not initialized already
    if not tb._stamp[iters] then
        tb._stamp[iters]    = {
            event           = EventListener:create(),
            timer           = CreateTimer(),
            running         = false,
            active_context  = 0,
            interval        = 1/iters,
        }
        SetTimerData(tb._stamp[iters].timer, iters)
    end
    tb._stamp[iters].event:register(func)
    tb._stamp[iters].event:disable(func)
end
function tb._check(iters, func)
    if not tb._stamp[iters] then return false;
    elseif not tb._stamp[iters].event:is_registered(func) then return false;
    end
    return true
end
function tb._on_callback_execute()
    local iters = GetTimerData(GetExpiredTimer())
    tb._stamp[iters].event:execute()
end
function tb.activate(iters, func)
    iters   = toint(iters)

    if not tb._check(iters, func) then return;
    elseif tb._stamp[iters].event:is_enabled(func) then return;
    end
    tb._stamp[iters].active_context = tb._stamp[iters].active_context + 1
    tb._stamp[iters].event:enable(func)

    --  Start the timer if it hasn't started yet.
    if tb._stamp[iters].running then return;
    end
    tb._stamp[iters].running = true
    TimerStart(tb._stamp[iters].timer, tb._stamp[iters].interval, true, tb._on_callback_execute)
end
function tb.deactivate(iters, func)
    iters   = toint(iters)

    if not tb._check(iters, func) then return;
    elseif not tb._stamp[iters].event:is_enabled(func) then return;
    elseif not tb._stamp[iters].running then return;
    end

    tb._stamp[iters].active_context = tb._stamp[iters].active_context - 1
    tb._stamp[iters].event:disable(func)

    --  Pause the timer if there are no more active instances.
    if tb._stamp[iters].active_context > 0 then return;
    end
    tb._stamp[iters].running = false
    PauseTimer(tb._stamp[iters].timer)
end
function tb.is_active(iters)
    iters   = toint(iters)

    if not tb._stamp[iters] then return false;
    end
    return tb._stamp[iters].running
end