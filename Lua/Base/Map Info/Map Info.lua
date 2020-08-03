do
    local _SetMapName           = SetMapName
    local _SetMapDescription    = SetMapDescription
    local mapname
    local desc

    function SetMapName(name)
        mapname = GetLocalizedString(name)
        _SetMapName(name)
    end
    function SetMapDescription(description)
        desc = GetLocalizedString(description)
        _SetMapDescription(description)
    end
    function GetMapName(name)
        return mapname
    end
    function GetMapDescription(description)
        return desc
    end
end