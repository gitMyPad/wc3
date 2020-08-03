do
    IsDestructableTree = setmetatable({}, protected_table())

    --[[
    *************************************************************************************
    *
    *   Detect whether a destructable is a tree or not.  
    *
    ***************************************************************************
    *
    *   Credits
    *
    *       To PitzerMike
    *       -----------------------
    *
    *           for IsDestructableTree
    *
    *************************************************************************************
    *
    *    Functions
    *
    *       function IsDestructableTree takes destructable d returns boolean
    *
    *       function IsDestructableAlive takes destructable d returns boolean
    *
    *       function IsDestructableDead takes destructable d returns boolean
    *
    *       function IsTreeAlive takes destructable tree returns boolean
    *           - May only return true for trees.          
    *
    *       function KillTree takes destructable tree returns boolean
    *           - May only kill trees.
    *
    **************************************************************************************
    *
    *   Translated to LUA.
    */
    ]]
    local m_dest_tree               = getmetatable(IsDestructableTree)
    m_dest_tree.HARVESTER_UNIT_ID   = FourCC('hpea')    --  human peasant
    m_dest_tree.HARVEST_ABILITY     = FourCC('Ahrl')    --  ghoul harvest
    m_dest_tree.HARVEST_ORDER_ID    = 0xD0032           -- harvest order ( 852018 )
    m_dest_tree.NEUTRAL_PLAYER      = Player(PLAYER_NEUTRAL_PASSIVE)

    Initializer.registerBJ("SYSTEM", function()
        m_dest_tree.harvester = CreateUnit(m_dest_tree.NEUTRAL_PLAYER, m_dest_tree.HARVESTER_UNIT_ID, 0, 0, 0)
        UnitAddAbility(m_dest_tree.harvester, m_dest_tree.HARVEST_ABILITY)
        UnitAddAbility(m_dest_tree.harvester, FourCC('Aloc'))
        ShowUnit(m_dest_tree.harvester, false)
    end)
    function m_dest_tree:__call(d)
        return (IssueTargetOrderById(m_dest_tree.harvester, m_dest_tree.HARVEST_ORDER_ID, d)) and (IssueImmediateOrderById(m_dest_tree.harvester, 851973))
    end
    function IsDestructableDead(d)
        return (GetWidgetLife(d) <= 0.405)
    end
    function IsDestructableAlive(d)
        return (GetWidgetLife(d) > .405)
    end
    function IsTreeAlive(tree)
        return IsDestructableAlive(tree) and IsDestructableTree(tree)
    end
    function KillTree(tree)
        if (IsTreeAlive(tree)) then
            KillDestructable(tree)
            return true
        end
        return false
    end
end