do
    local tb            = protected_table()
    CustomBuff.UnitInfo = setmetatable({}, tb)
    CustomBuffSystem    = CustomBuff.UnitInfo

    local mtb           = {}
    mtb.lists           = {}
    mtb.disp_counter    = {}

    function tb._add(whichunit, bufficon, buffname, buffdesc)
        local o             = {}
        o.icon_path         = bufficon
        o.icon_name         = buffname
        o.icon_desc         = buffdesc
        o.unit              = whichunit
        mtb.disp_counter[o] = 0
        setmetatable(o, tb)
        return o
    end
    function tb:_is_valid()
        return mtb.disp_counter[self] ~= nil
    end
    function tb.add(whichunit, bufficon, buffname, buffdesc)
        if not mtb.lists[whichunit] then
            mtb.lists[whichunit]    = SimpleList()
        end
        local o     = tb._add(whichunit, bufficon, buffname, buffdesc)
        mtb.lists[whichunit]:insert(o)
        return o
    end
    function tb:destroy()
        if not tb._is_valid(self) then return;
        end
        mtb.lists[self.unit]:remove(self)
        self.icon_path  = nil
        self.icon_name  = nil
        self.icon_desc  = nil
        self.unit       = nil
        mtb.disp_counter[self] = nil
    end
    function tb:show_icon(flag)
        if not tb._is_valid(self) then return;
        end
        if flag then
            mtb.disp_counter[self]  = mtb.disp_counter[self] + 1
        else
            mtb.disp_counter[self]  = mtb.disp_counter[self] - 1
        end
    end
    function tb:is_visible(flag)
        if not tb._is_valid(self) then return false;
        end
        return mtb.disp_counter[self] >= 0
    end
    function tb.get_list(whichunit)
        return mtb.lists[whichunit]
    end
    tb.remove   = tb.destroy

    UnitDex.register("LEAVE_EVENT", function()
        local unit = UnitDex.eventUnit
        if not mtb.lists[unit] then return;
        end
        for self in mtb.lists[unit] do
            self:destroy()
        end
        mtb.lists[unit]:destroy()
        mtb.lists[unit] = nil
    end)
end