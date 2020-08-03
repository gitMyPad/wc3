do
    local m_dmg         = getmetatable(DamageEvent)
    m_dmg.__metatable   = DamageEvent

    function UnitDamageTargetPure(source, target, amount)
        local old_pure      = m_dmg._pure_flag
        local result
        m_dmg._pure_flag    = true
        result              = UnitDamageTarget(source, target, amount, false, false,
                                            ATTACK_TYPE_NORMAL, DAMAGE_TYPE_UNIVERSAL,
                                            nil)
        m_dmg._pure_flag    = old_pure
        return result
    end
end