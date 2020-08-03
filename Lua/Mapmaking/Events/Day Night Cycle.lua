do
    local tb    = protected_table()
    tb._DAY     = 6
    tb._NIGHT   = 18
    tb._IS_DAY  = false
    tb._handler = EventListener:create()
    DNCycle     = setmetatable({}, tb)

    function tb.register(func)
        tb._handler:register(func)
    end
    function tb.deregister(func)
        tb._handler:deregister(func)
    end
    
    function tb.is_daytime()
        return tb._IS_DAY
    end
    function tb.is_nighttime()
        return not tb._IS_DAY
    end

    Initializer("SYSTEM", function()
        local trig  = CreateTrigger()
        TriggerRegisterGameStateEvent(trig, GAME_STATE_TIME_OF_DAY, LESS_THAN, tb._DAY)
        TriggerRegisterGameStateEvent(trig, GAME_STATE_TIME_OF_DAY, GREATER_THAN, tb._DAY)
        TriggerRegisterGameStateEvent(trig, GAME_STATE_TIME_OF_DAY, LESS_THAN, tb._NIGHT)
        TriggerRegisterGameStateEvent(trig, GAME_STATE_TIME_OF_DAY, GREATER_THAN, tb._NIGHT)
        TriggerAddCondition(trig, Condition(function()
            local time          = math.floor(GetFloatGameState(GAME_STATE_TIME_OF_DAY) + 0.5)
            local old_status    = tb._IS_DAY
            local flag
            --  Night time
            if (time < tb._DAY) or (time >= tb._NIGHT) then
                flag    = false
            else
                flag    = true
            end
            if old_status  ~= flag then
                tb._IS_DAY  = flag
                --  Throw event
                tb._handler:execute(flag)
            end
        end))
    end)
end