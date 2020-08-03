do
    local m_reg                 = protected_table()
    RegisterAnyPlayerUnitEvent  = setmetatable({}, m_reg)
    m_reg.__metatable           = RegisterAnyPlayerUnitEvent
    do
        local trig      
        local tb        = {}
        local function is_player_event(event)
            return tostring(event):sub(1,15) == 'playerunitevent'
        end
        Initializer("SYSTEM", function()
            trig        = CreateTrigger()
            TriggerAddAction(trig, function()
                local event = GetTriggerPlayerUnitEventId()
                tb[event]:execute()
            end)
        end)
        function m_reg:__call(event, func)
            if not is_player_event(event) then return;
            end
            if not trig then Initializer.register(function() self(event, func); end, "SYSTEM"); return;
            end
            if not tb[event] then
                tb[event] = EventListener:create()
                for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
                    local p = Player(i)
                    TriggerRegisterPlayerUnitEvent(trig, p, event, nil)
                end
            end
            tb[event]:register(func)
        end
    end
end