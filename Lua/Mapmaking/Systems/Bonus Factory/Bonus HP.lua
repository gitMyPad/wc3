do
    local tb        = BonusFactory()
    local ptb       = {}
    tb.BONUS_ABIL   = FourCC("Z001")
    BonusHP         = setmetatable({}, tb)

    function tb._parse_modifier(whichunit, amount)
        if not ptb[whichunit] then
            ptb[whichunit]  = 0
        end
        amount  = math.floor(amount + 0.5)

        UnitAddAbility(whichunit, tb.BONUS_ABIL)
        local abil  = BlzGetUnitAbility(whichunit, tb.BONUS_ABIL)
        IncUnitAbilityLevel(whichunit, tb.BONUS_ABIL)
        BlzSetAbilityIntegerLevelField(abil, ABILITY_ILF_MAX_LIFE_GAINED, 0, -amount + ptb[whichunit])
        DecUnitAbilityLevel(whichunit, tb.BONUS_ABIL)
        UnitRemoveAbility(whichunit, tb.BONUS_ABIL)

        ptb[whichunit]  = amount
    end
    function tb._assign_base_value(whichunit)
        tb.set_base(whichunit, 0)
    end
    UnitDex.register("LEAVE_EVENT", function()
        ptb[whichunit]  = nil
    end)
end