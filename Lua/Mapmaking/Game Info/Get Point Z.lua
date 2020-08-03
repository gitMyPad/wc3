do
    local _DUMMY
    Initializer("SYSTEM", function()
        _DUMMY  = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('uloc'), 0, 0, 0)
        ShowUnit(_DUMMY, false)
    end)

    function GetZ(x, y)
        SetUnitX(_DUMMY, x)
        SetUnitY(_DUMMY, y)
        return BlzGetUnitZ(_DUMMY)
    end
    GetCoordinateZ  = GetZ
    GetPointZ       = GetZ
end