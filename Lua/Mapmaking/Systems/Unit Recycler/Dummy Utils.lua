--[[
    DummyUtils
        - Inspired by Nestharus' dummy allocation and deallocation algorithm.
            an O(1) complexity algorithm.
        - Also inspired by Flux's Dummy Recycler
]]
do
    local m_utils           = protected_table()
    local list              = {upper=LinkedList:create(), lower=LinkedList:create(), pointer={}, angle={}}
    local dummy_flag        = {}
    local total_count       = 0
    --local SetUnitFacing     = BlzSetUnitFacingEx or _G['SetUnitFacing']
    DummyUtils              = setmetatable({}, m_utils)

    m_utils._operational    = false
    m_utils.DUMMY_TYPE      = FourCC('dumi')
    --  PRELOAD_AMOUNT/LIST_COUNT will always round up to an integer.
    m_utils.PRELOAD_AMOUNT  = 64
    m_utils.LIST_COUNT      = 8
    m_utils.FACING_OFFSET   = 360/m_utils.LIST_COUNT
    m_utils.PLAYER          = Player(PLAYER_NEUTRAL_PASSIVE)

    for id = 1, m_utils.LIST_COUNT do
        list[id]                = LinkedList()--:create()
        list.angle[id]          = id * m_utils.FACING_OFFSET
        list.pointer[id]        = select(2, list.upper:insert(id))
        list.pointer[list[id]]  = list.upper
    end

    function m_utils._on_request(dummy, player, x, y, z, facing)
        --  Preparing the unit
        SetUnitX(dummy, x); SetUnitY(dummy, y); SetUnitFlyHeight(dummy, z, 0.00);
        ShowUnit(dummy, true); PauseUnit(dummy, false);
        UnitRemoveAbility(dummy, FourCC("Aloc")); UnitAddAbility(dummy, FourCC("Aloc"));
        SetUnitOwner(dummy, player, true); SetUnitFacing(dummy, facing);
        BlzUnitDisableAbility(dummy, FourCC("Aatk"), false, false)        
    end
    function m_utils._on_recycle(dummy, facing, tx, ty)
        SetUnitX(dummy, tx); SetUnitY(dummy, ty);
        SetUnitFacing(dummy, facing); SetUnitOwner(dummy, m_utils.PLAYER, true);
        ShowUnit(dummy, false); PauseUnit(dummy, true);
        BlzUnitDisableAbility(dummy, FourCC("Aatk"), true, false)
    end

    do
        local t = {}
        Initializer("SYSTEM", function()
            t.rectX = WorldRect.rectMinX
            t.rectY = WorldRect.rectMinY
            t.temp  = math.max(m_utils.PRELOAD_AMOUNT, 1)/m_utils.LIST_COUNT
            t.temp  = math.ceil(t.temp)
            for i = 1, m_utils.LIST_COUNT do
                local dummy
                for j = 1, t.temp do
                    dummy   = CreateUnit(m_utils.PLAYER, m_utils.DUMMY_TYPE, t.rectX, t.rectY, list.angle[i])
                    if not dummy then
                        print_after(0.00, "DummyUtils.initialization >> Dummy could not be created.")
                        break
                    end
                    PauseUnit(dummy, true); ShowUnit(dummy, false);
                    BlzUnitDisableAbility(dummy, FourCC("Aatk"), true, false)
                    list[i]:insert(dummy)

                    dummy_flag[dummy]   = "free"
                    total_count         = total_count + 1
                end
                if not dummy then break;
                end
            end
            if total_count <= 0 then return;
            end
            m_utils._operational = true
        end)

        function m_utils._internal_req(player, x, y, z, facing)
            if total_count <= 0 then return nil;
            end

            local j = math.floor(facing/m_utils.FACING_OFFSET + 0.5)
            if j <= 0 then
                j = m_utils.LIST_COUNT
            end

            local dummy, pointer    = list[j]:first()

            list[j]:remove(pointer)
            total_count     = total_count - 1

            m_utils._on_request(dummy, player, x, y, z, facing)
            dummy_flag[dummy]           = "used"
            if list.pointer[list[j]] == list.upper then
                --  Located in the upper list.
                list.upper:remove(list.pointer[j])
                list.pointer[j]         = select(2, list.lower:insert(j))
                list.pointer[list[j]]   = list.lower
            else
                local k                         = list.upper:first()
                local nextDummy, nextPointer    = list[k]:first()
                SetUnitFacing(nextDummy, list.angle[j])
                list[k]:remove(nextPointer)
                list[j]:insert(nextDummy)

                list.upper:remove(list.pointer[k])
                list.pointer[k]         = select(2, list.lower:insert(k))
                list.pointer[list[k] ]   = list.lower
            end
            if #list.upper <= 0 then
                local swap              = list.upper
                list.upper, list.lower  = list.lower, swap
            end
            return dummy
        end
        function m_utils.request(player, x, y, z, facing)
            player          = player or m_utils.PLAYER
            x, y, z, facing = x or 0, y or 0, z or 0, facing or 0
            if not m_utils._operational then 
                print("DummyUtils.request >> System is not operational.")
                return nil
            end

            local dummy     = m_utils._internal_req(player, x, y, z, facing)
            if dummy then
                bj_lastCreatedUnit, dummy   = dummy, nil
                return bj_lastCreatedUnit
            end
            
            dummy =  CreateUnit(player, m_utils.DUMMY_TYPE, x, y, facing)
            SetUnitFlyHeight(dummy, z, 0.0)
            dummy_flag[dummy]  = "used"
            bj_lastCreatedUnit = dummy
            return bj_lastCreatedUnit
        end
        function m_utils.recycle(dummy)
            if not m_utils._operational then
                print("DummyUtils.recycle >> System is not operational.")
                return false
            end
            if (not dummy_flag[dummy]) or (dummy_flag[dummy] == "free") then return false;
            end

            --  Populate the lower list first.
            if #list.lower <= 0 then
                local swap              = list.upper
                list.upper, list.lower  = list.lower, swap
            end
            local j, pointer        = list.lower:first()
            m_utils._on_recycle(dummy, list.angle[j], t.rectX, t.rectY)

            list[j]:insert(dummy)
            dummy_flag[dummy]       = "free"
            total_count             = total_count + 1

            list.lower:remove(pointer)
            list.pointer[j]         = select(2, list.upper:insert(j))
            list.pointer[list[j] ]   = list.upper
            return true
        end
    end
end