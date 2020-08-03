do
    local m_vers    = protected_table()
    m_vers.patch    = (BlzStartUnitAbilityCooldown and "1.32") or "1.31"
    VersionCheck    = setmetatable({}, m_vers)
end