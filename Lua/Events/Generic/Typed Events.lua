do
    GetTriggerPlayerUnitEventId = setmetatable({}, {__call = function(t)
        local str = GetTriggerEventId()
        if not t[str] then
            t[str] = ConvertPlayerUnitEvent(GetHandleId(str))
        end
        return t[str]
    end})
    GetTriggerUnitEventId = setmetatable({}, {__call = function(t)
        local str = GetTriggerEventId()
        if not t[str] then
            t[str] = ConvertUnitEvent(GetHandleId(str))
        end
        return t[str]
    end})
end