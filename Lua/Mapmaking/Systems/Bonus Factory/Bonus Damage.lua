do
    local tb    = BonusFactory({
        BASE_ABIL   = FourCC("Z002")
    })
    BonusDamage  = setmetatable({}, tb)

    function tb._parse_modifier(whichunit, amount)
        local abil  = BlzGetUnitAbility(whichunit, tb.BASE_ABIL)
        BlzSetAbilityIntegerLevelField(abil, ABILITY_ILF_ATTACK_BONUS, 0,
                                       math.floor(amount + 0.5))
        IncUnitAbilityLevel(whichunit, tb.BASE_ABIL)
        DecUnitAbilityLevel(whichunit, tb.BASE_ABIL)
    end
    function tb._assign_base_value(whichunit)
        UnitAddAbility(whichunit, tb.BASE_ABIL)
        UnitMakeAbilityPermanent(whichunit, true, tb.BASE_ABIL)
        tb.set_base(whichunit, 0)
    end
end