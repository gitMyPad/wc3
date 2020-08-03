do
    local m_rect        = protected_table()
    WorldRect           = setmetatable({}, m_rect)
    m_rect.__metatable  = WorldRect
    Initializer("SYSTEM", function()
        m_rect.reg         = CreateRegion()
        m_rect.rect        = GetWorldBounds()
        m_rect.rectMaxX    = GetRectMaxX(m_rect.rect)
        m_rect.rectMaxY    = GetRectMaxY(m_rect.rect)
        m_rect.rectMinX    = GetRectMinX(m_rect.rect)
        m_rect.rectMinY    = GetRectMinY(m_rect.rect)
        m_rect.rectX       = GetRectCenterX(m_rect.rect)
        m_rect.rectY       = GetRectCenterY(m_rect.rect)

        RegionAddRect(m_rect.reg, m_rect.rect)
    end)
end