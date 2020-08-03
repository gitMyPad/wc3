do
    local m_obj = getmetatable(ObjectReader)
    Initializer("SYSTEM", function()

        function m_obj.extract_icon(obj_id)
            return m_obj.extract(obj_id, ABILITY_SLF_ICON_NORMAL, 1)
        end
    end)
end