do
    local m_obj             = protected_table()
    ObjectReader            = setmetatable({}, m_obj)

    m_obj.BASE_ABIL_ID      = FourCC("ANfd")
    m_obj._database         = {}
    m_obj._natives          = {
        abilityrealfield                = BlzGetAbilityRealField,
        abilityintegerfield             = BlzGetAbilityIntegerField,
        abilitystringfield              = BlzGetAbilityStringField,
        abilitybooleanfield             = BlzGetAbilityBooleanField,
        abilityreallevelfield           = BlzGetAbilityRealLevelField,
        abilityintegerlevelfield        = BlzGetAbilityIntegerLevelField,
        abilitystringlevelfield         = BlzGetAbilityStringLevelField,
        abilitybooleanlevelfield        = BlzGetAbilityBooleanLevelField,
        abilityreallevelarrayfield      = BlzGetAbilityRealLevelArrayField,
        abilityintegerlevelarrayfield   = BlzGetAbilityIntegerLevelArrayField,
        abilitystringlevelarrayfield    = BlzGetAbilityStringLevelArrayField,
        abilitybooleanlevelarrayfield   = BlzGetAbilityBooleanLevelArrayField,
    }

    --  ObjectReader.read returns a string value.
    function m_obj.read(obj_id, field, format)
        obj_id  = ((type(obj_id) == 'number') and CC2Four(obj_id)) or obj_id
        format  = format or ""
        if not m_obj.BASE_ABIL_TEXT then
            m_obj.BASE_ABIL_TEXT = BlzGetAbilityExtendedTooltip(m_obj.BASE_ABIL_ID, 0)
        end
        if not m_obj._database[obj_id] then
            m_obj._database[obj_id] = {}
        end
        if not m_obj._database[obj_id][field] then
            local str       = "<" .. obj_id .. "," .. field .. format .. ">"

            BlzSetAbilityExtendedTooltip(m_obj.BASE_ABIL_ID, str, 0)
            local result    = BlzGetAbilityExtendedTooltip(m_obj.BASE_ABIL_ID, 0)
            BlzSetAbilityExtendedTooltip(m_obj.BASE_ABIL_ID, m_obj.BASE_ABIL_TEXT, 0)

            m_obj._database[obj_id][field] = result
            return result
        end
        return m_obj._database[obj_id][field]
    end
    function m_obj.extract(obj_id, field)
    end

    Initializer("SYSTEM", function()
        local dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC("uloc"), 
                                    WorldRect.rectMinX, WorldRect.rectMinY, 0)
        PauseUnit(dummy, false)
        ShowUnit(dummy, false)

        function m_obj.extract(obj_id, field, lvl, index)
            local result
            lvl     = lvl or 0
            lvl     = lvl - 1
            index   = index or 0

            local added     = UnitAddAbility(dummy, obj_id)
            local abil      = BlzGetUnitAbility(dummy, obj_id)
            local colon_pos = tostring(field):find(':')
            local str       = tostring(field):sub(1, colon_pos - 1)
            if not m_obj._natives[str] then
                print("ObjectReader.extract >> Field entry is invalid.")
                print("ObjectReader.extract >> type of entry:", str)
                return nil
            end
            if not str:find('level') then
                result  = m_obj._natives[str](abil, field)
            elseif str:find('array') then
                result  = m_obj._natives[str](abil, field, lvl, index)
            else
                result  = m_obj._natives[str](abil, field, lvl)
            end
            if added then
                UnitRemoveAbility(dummy, obj_id)
            end
            return result
        end
    end)
end