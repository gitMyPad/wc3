do
    local m_init        = protected_table()
    local list          = {
        SYSTEM          = {},
        TRIGGER         = {},
        USER            = {},
        TIMER           = {},
    }
    local results       = {
        SYSTEM          = {},
        TRIGGER         = {},
        USER            = {},
        TIMER           = {},
    }
    local flags         = {}
    Initializer         = setmetatable({}, m_init)
    m_init.__metatable  = Initializer

    function m_init.register(func, prio)
        if not is_function(func) then return end
        if ((type(prio) ~= "string") or (not list[prio])) then
            prio = "USER"
        end
        list[prio][#list[prio] + 1] = func
    end
    function m_init.initialized(prio)
        prio = ((not list[prio]) and "USER") or prio
        return flags[prio]
    end

    function m_init.registerBJ(prio, func) m_init.register(func, prio) end
    function m_init:__call(prio, func) m_init.register(func, prio) end

    local function exec(prio)
        local i     = 1
        while true do
            results[prio][i]   = select(1, pcall(list[prio][i]))
            if not results[prio][i] then
                results[prio][i]   = "Initializer.result {" .. prio .. "} >> " .. tostring(list[prio][i]) ..
                                     " failed to initialize. Index position (" .. tostring(i) .. ")"
            else
                results[prio][i]   = nil
            end
            i                       = i + 1
            if i > #list[prio] then break end
        end
        flags[prio] = true
    end

    -- Initialize the functions
    local _SetMapMusic = SetMapMusic
    function SetMapMusic(musicname, random, index)
        SetMapMusic = _SetMapMusic
        _SetMapMusic(musicname, random, index)

        TimerStart(CreateTimer(), 0.00, false, function()
            exec("TIMER")
            PauseTimer(GetExpiredTimer())
            DestroyTimer(GetExpiredTimer())
        end)
        exec("SYSTEM")
        local hasCustomInit = RunInitializationTriggers ~= nil
        local tempVar       = ""
        local tempCustomTriggers
        if hasCustomInit then
            tempCustomTriggers = RunInitializationTriggers
            tempVar            = "RunInitializationTriggers"
        else
            tempCustomTriggers = InitGlobals
            tempVar            = "InitGlobals"
        end
        _G[tempVar]            = function()
            exec("TRIGGER")
            tempCustomTriggers()
            _G[tempVar] = tempCustomTriggers
            exec("USER")
        end
    end
end