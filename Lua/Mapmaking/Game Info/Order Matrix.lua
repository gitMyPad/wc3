OrderMatrix = setmetatable({}, protected_table())
do
    local order         = OrderMatrix
    local m_order       = getmetatable(order)
    local meta_target   = {__mode='v'}
    local meta_point    = {x={}, y={}}
    local meta_order    = {}
    local meta_order_id = {}
    local meta_order_tp = {}
    m_order.MAX_ORDERS  = 8
    m_order.NO_TARGET   = setmetatable({}, {__tostring=function(t) return "No Target" end})
    m_order.NO_POINT    = Location(0, 0)
    m_order.IMMEDIATE   = setmetatable({}, {__tostring=function(t) return "Immediate" end})
    m_order.POINT       = setmetatable({}, {__tostring=function(t) return "Point" end})
    m_order.TARGET      = setmetatable({}, {__tostring=function(t) return "Target" end})

    m_order.__metatable = order
    meta_target.__index = function(t, k)
        return m_order.NO_TARGET
    end
    meta_point.x.__index = function(t, k)
        return 0
    end
    meta_point.y.__index = function(t, k)
        return 0
    end
    meta_order.__index = function(t, k)
        return "No order"
    end
    meta_order_id.__index = function(t, k)
        return 0
    end
    meta_order_tp.__index = function(t, k)
        return "No order type"
    end

    local function new_table(id)
        m_order[id]             = {}
        m_order[id].point       = {x = setmetatable({}, meta_point.x), y = setmetatable({}, meta_point.y)}
        m_order[id].target      = setmetatable({}, meta_target)
        m_order[id].orderId     = setmetatable({}, meta_order_id)
        m_order[id].order       = setmetatable({}, meta_order)
        m_order[id].orderType   = setmetatable({}, meta_order_tp)
    end
    local function is_unit(whichunit)
        return select(1, pcall(GetUnitTypeId, whichunit))
    end

    local old_index     = m_order.__index
    function m_order.__index(t, k)
        if is_unit(k) then
            local id = k
            local result = old_index(t, id)
            if result == nil then
                new_table(id)
                result   = old_index(t, id)
            end
            return result
        end
        return old_index(t, k)
    end
    Initializer("SYSTEM", function()
        local lt    = {}
        local func  = function()
            lt.eventType    = GetTriggerPlayerUnitEventId()
            lt.target       = GetOrderTargetUnit() or GetOrderTargetDestructable() or GetOrderTargetItem() or m_order.NO_TARGET
            lt.point        = GetOrderPointLoc() or m_order.NO_POINT
            if lt.point ~= m_order.NO_POINT then
                RemoveLocation(lt.point)
                lt.point_x, lt.point_y = GetOrderPointX(), GetOrderPointY()
            else
                lt.point_x, lt.point_y  = 0, 0
            end
            if lt.eventType == EVENT_PLAYER_UNIT_ISSUED_ORDER then
                lt.orderType    = m_order.IMMEDIATE
            elseif lt.eventType == EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER then
                lt.orderType    = m_order.POINT
            else
                lt.orderType    = m_order.TARGET
            end
            lt.orderId          = GetIssuedOrderId()
            lt.result, lt.value = pcall(OrderId2String, lt.orderId)
            if lt.result then
                lt.order        = ((lt.value ~= "") and lt.value) or "cannot convert order"
            else
                lt.order        = "cannot convert order"
            end

            lt.id               = GetTriggerUnit()
            table.insert(m_order[lt.id].point.x, 1, lt.point_x)
            table.insert(m_order[lt.id].point.y, 1, lt.point_y)
            table.insert(m_order[lt.id].target, 1, lt.target)
            table.insert(m_order[lt.id].orderId, 1, lt.orderId)
            table.insert(m_order[lt.id].order, 1, lt.order)
            table.insert(m_order[lt.id].orderType, 1, lt.orderType)

            if #m_order[lt.id].point.x > m_order.MAX_ORDERS then
                table.remove(m_order[lt.id].order)
                table.remove(m_order[lt.id].target)
                table.remove(m_order[lt.id].orderId)
                table.remove(m_order[lt.id].orderType)
                table.remove(m_order[lt.id].point.x)
                table.remove(m_order[lt.id].point.y)
            end
        end

        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, func)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, func)
    end)
    UnitDex.register("ENTER_EVENT", function()
        local id    = UnitDex.eventUnit
        if not m_order[id] then
            new_table(id)
        end
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local id                = UnitDex.eventUnit
        m_order[id].point       = nil
        m_order[id].order       = nil
        m_order[id].target      = nil
        m_order[id].orderId     = nil
        m_order[id].orderType   = nil
        m_order[id]             = nil
    end)

    function m_order.reorder(unit, index)
        local orderInfo = OrderMatrix[unit]
        if not orderInfo.orderId[index] then
            return false
        end
        if orderInfo.orderType[index] == OrderMatrix.IMMEDIATE then
            IssueImmediateOrderById(unit, orderInfo.orderId[index])
        elseif orderInfo.orderType[index] == OrderMatrix.POINT then
            IssuePointOrderById(unit, orderInfo.orderId[index], orderInfo.point.x[index], orderInfo.point.y[index])
        else
            IssueTargetOrderById(unit, orderInfo.orderId[index], orderInfo.target[index])
        end
        return true
    end
end