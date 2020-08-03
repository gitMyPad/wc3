do
    local tb            = BonusFactory()
    BonusMagicReduction = setmetatable({}, tb)

    function tb._parse_modifier(whichunit, amount)
    end
    function tb._assign_base_value(whichunit)
        tb.set_base(whichunit, 0)
    end

    DamageEvent.register_modifier("MODIFIER_EVENT_SYSTEM", function(targ)
        if IsPureDamage() then return;
        elseif IsPhysicalDamage() then return;
        end
        
        local ratio     = tb.get_product(targ)
        local amount    = tb.get_sum(targ)
        DamageEvent.current.dmg = math.max(DamageEvent.current.dmg*ratio - amount, 0)
    end)
end