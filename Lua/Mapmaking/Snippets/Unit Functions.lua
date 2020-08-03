do
    local tb    = {}
    tb.DELTA    = 0.01
    tb.FACTOR   = 100

    function GetUnitMaxHP(whichunit)
        local curHP     = GetWidgetLife(whichunit)
        local maxHP     = BlzGetUnitMaxHP(whichunit)
        local amount    
        SetWidgetLife(whichunit, maxHP)
        while true do
            amount  = GetWidgetLife(whichunit)
            SetWidgetLife(whichunit, amount*tb.FACTOR)
            if math.abs(GetWidgetLife(whichunit) - amount) <= tb.DELTA then break
            end
        end
        SetWidgetLife(whichunit, curHP)
        return amount
    end
    function GetUnitMaxMana(whichunit)
        local curMP     = GetUnitState(whichunit, UNIT_STATE_MANA)
        local maxMP     = BlzGetUnitMaxMana(whichunit)
        local amount    
        SetUnitState(whichunit, UNIT_STATE_MANA, maxMP)
        while true do
            amount  = GetUnitState(whichunit, UNIT_STATE_MANA)
            SetUnitState(whichunit, UNIT_STATE_MANA, maxMP*tb.FACTOR)
            if math.abs(GetUnitState(whichunit, UNIT_STATE_MANA) - amount) <= tb.DELTA then break
            end
        end
        SetWidgetLife(whichunit, curMP)
        return amount
    end

    function UnitStopMovement(whichunit, hide)
        hide    = (hide == nil and true) or hide
        BlzUnitDisableAbility(whichunit, FourCC("Amov"), true, hide)
    end
    function UnitStartMovement(whichunit, hide)
        hide    = (hide == nil and false) or hide
        BlzUnitDisableAbility(whichunit, FourCC("Amov"), false, hide)
    end
    function UnitSuspendAttack(whichunit, hide)
        hide    = (hide == nil and true) or hide
        BlzUnitDisableAbility(whichunit, FourCC("Aatk"), true, hide)
    end
    function UnitRestoreAttack(whichunit, hide)
        hide    = (hide == nil and false) or hide
        BlzUnitDisableAbility(whichunit, FourCC("Aatk"), false, hide)
    end
end