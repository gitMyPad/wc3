do
    ---@class funcTable
    --- Stores all initializer functions
    --- to be executed at a later point in game.
    local funcTable = {
        system      = {},
        global      = {},
        trigger     = {},
        user        = {},
        game        = {},
    }
    local errorLog  = {}
    local _DEBUG    = false
    local pcall     = pcall
    local print     = print

    ---This function is used to store the list of errors to be
    ---printed all at once.
    ---@param event string
    ---@param func function
    ---@param i integer
    function funcTable._logError(event, func, i, errMsg)
        errorLog[#errorLog + 1] = "(\"" .. event .. "\") System initialization >> Function (" .. tostring(i) .. ") failed to initialize properly. "
                                  .. "\n\t" .. errMsg
    end

    function funcTable._printErrors()
        if (#errorLog <= 0) then
            return
        end
        if (_DEBUG) then
            errorLog = {}
            return
        end
        for i = 1,#errorLog do
            print(errorLog[i])
        end
        errorLog = {}
    end

    ---This function is used to execute initializer functions.
    ---@param event string
    function funcTable._run(event)
        if ((not funcTable[event]) or 
            (type(funcTable[event]) ~= "table")) then
            return
        end
        if (#funcTable[event] < 1) then
            funcTable[event] = nil
            return
        end
        -- Run all initializing functions.
        for i = 1, #funcTable[event] do
            local func = funcTable[event][i]
            local result = table.pack(pcall(func))
            if (not result[1]) then
                funcTable._logError(event, func, i, result[2])
            end
        end
        funcTable._printErrors()
    end

    function funcTable._register(event, func)
        if (type(func) ~= "function") then
            return
        end
        if (not funcTable[event]) then
            print("Initializer >> {Warning} '" .. event .. "' event does not exist")
            return
        end
        funcTable[event][#funcTable[event] + 1] = func
    end

    ---Runs at a point before all units are created
    ---@param func function
    function OnSystemInit(func)
        funcTable._register("system", func)
    end
    ---Runs at a point after all blizzard globals are initialized
    ---@param func function
    function OnGlobalInit(func)
        funcTable._register("global", func)
    end
    ---Runs at a point after all triggers are initialized
    ---@param func function
    function OnTriggerInit(func)
        funcTable._register("trigger", func)
    end
    ---Runs at a point after all map initialization triggers are initialized
    ---@param func function
    function OnUserInit(func)
        funcTable._register("user", func)
    end
    ---Runs at a point after the game has initialized.
    ---@param func function
    function OnGameInit(func)
        funcTable._register("game", func)
    end
    OnGameStart = OnGameInit

    ---Hook up system initialization to SetMapMusic
    do
        local _oldMusic = SetMapMusic
        function SetMapMusic(...)
            SetMapMusic = _oldMusic
            _oldMusic(...)
            funcTable._run("system")

            local _oldGlobals = InitGlobals
            function InitGlobals()
                InitGlobals = _oldGlobals
                _oldGlobals()

                funcTable._run("global")
                local _oldTrigger = InitCustomTriggers
                local _oldUser    = RunInitializationTriggers

                if _oldTrigger then
                    function InitCustomTriggers()
                        InitCustomTriggers = _oldTrigger
                        _oldTrigger()

                        funcTable._run("trigger")
                        if (not _oldUser) then
                            funcTable._run("user")
                        end
                    end
                else
                    funcTable._run("trigger")
                end

                if _oldUser then
                    function RunInitializationTriggers()
                        RunInitializationTriggers = _oldUser
                        _oldUser()

                        funcTable._run("user")
                    end
                else
                    funcTable._run("user")
                end
            end

            TimerStart(CreateTimer(), 0.00, false, function()
                PauseTimer(GetExpiredTimer())
                DestroyTimer(GetExpiredTimer())
                funcTable._run("game")
            end)
        end
    end
end
