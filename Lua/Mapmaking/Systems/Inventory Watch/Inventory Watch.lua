do
    local tb        = AllocTableEx(50)
    tb._BASE        = 852001    -- base index translation
    tb._removed     = {}
    tb.table        = {}
    tb.items        = {[0] = {}}
    InventoryWatch  = setmetatable({}, tb)

    function GetUnitItemIdCount(whichunit, itemid)
        return tb.table[whichunit][itemid] or 0
    end
    function GetUnitItemCount(whichunit)
        return tb.items[0][whichunit] or 0
    end

    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function()
        local unit  = GetManipulatingUnit()
        local item  = GetManipulatedItem()
        local flag  = BlzGetItemBooleanField(item, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED)
        if flag then return;
        end

        local id    = GetItemTypeId(item)
        --  Always ensure the object exists.
        tb.table[unit]          = tb.table[unit] or tb.request()

        tb.items[0][unit]       = tb.items[0][unit] or 0
        tb.items[0][unit]       = tb.items[0][unit] + 1
        tb.table[unit][id]      = tb.table[unit][id] or 0
        tb.table[unit][id]      = tb.table[unit][id] + 1
    end)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function()
        local unit  = GetManipulatingUnit()
        local item  = GetManipulatedItem()
        local flag  = BlzGetItemBooleanField(item, ITEM_BF_USE_AUTOMATICALLY_WHEN_ACQUIRED)
        if flag then return;
        elseif not tb.table[unit] then return;
        end
        
        local id    = GetItemTypeId(item)
        --  Always assume that the object exists
        tb.items[0][unit]       = tb.items[0][unit] - 1
        tb.table[unit][id]      = tb.table[unit][id] - 1
        if tb.table[unit][id] <= 0 then
            tb.table[unit][id]  = nil
        end
    end)
    UnitDex.register("ENTER_EVENT", function(unit)
        tb.table[unit]      = tb.table[unit] or tb.request()
        tb.items[0][unit]   = tb.items[0][unit] or 0
    end)
    UnitDex.register("LEAVE_EVENT", function(unit)
        tb.restore(tb.table[unit])
        tb.items[0][unit]   = nil
        tb.table[unit]      = nil
    end)
end