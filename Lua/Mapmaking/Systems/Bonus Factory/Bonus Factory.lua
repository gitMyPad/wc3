do
    local tb        = protected_table()
    BonusFactory    = setmetatable({}, tb)

    tb.SUM          = {}
    tb.PRODUCT      = {}
    tb.ADD          = tb.SUM
    tb.MUL          = tb.PRODUCT

    function tb:__call(o, func)
        o           = protected_table(o)
        o._sum      = {}
        o._product  = {}
        o._base     = {}
        o._access   = {[tb.SUM] = o._sum, [tb.PRODUCT] = o._product}
        o._def      = {[tb.SUM] = 0, [tb.PRODUCT] = 1}

        o._access[tb.SUM]       = o._sum
        o._access[tb.PRODUCT]   = o._product

        if is_function(func) then
            o._parse_modifier = func
        end
        function o._assign_bonus_value(whichunit)
            o._sum[whichunit]       = {list = SimpleList(), total = 0}
            o._product[whichunit]   = {list = SimpleList(), total = 1, zeros = 0}
        end
        function o._assign_base_value(whichunit)
            o.set_base(whichunit, 1)
        end
        function o._apply_modifier(whichunit)
            local result    = o._base[whichunit]
            if o._product[whichunit].zeros > 0 then
                result  = o._sum[whichunit].total
            else
                result  = result*o._product[whichunit].total + o._sum[whichunit].total
            end
            if o._parse_modifier then
                o._parse_modifier(whichunit, result)
            end
        end
        function o:_set_modifier(prev_amt, amt, ignore)
            if self.bonus_type == tb.SUM then
                o._sum[self.unit].total     = o._sum[self.unit].total - prev_amt + amt
            elseif self.bonus_type == tb.PRODUCT then
                if (amt == 0) then
                    if not self.zeroed then
                        o._product[self.unit].zeros = o._product[self.unit].zeros + 1
                        self.zeroed = true
                    end
                    return
                end
                if self.zeroed then
                    o._product[self.unit].zeros = o._product[self.unit].zeros - 1
                    self.zeroed = false
                end
                o._product[self.unit].total = o._product[self.unit].total/prev_amt*amt
            end
            self.amount = amt
            if not ignore then
                o._apply_modifier(self.unit)
            end
        end
        function o._insert_bonus(whichunit, oo)
            o._access[oo.bonus_type][whichunit].list:insert(oo)
            o._set_modifier(oo, o._def[oo.bonus_type], oo.amount)
        end
        --  Never apply a modifier to the base directly.
        function o:apply_bonus(whichunit, amount, bonustype)
            bonustype       = tb[bonustype] or tb.SUM
            local oo    = {
                unit        = whichunit,
                amount      = amount,
                bonus_type  = bonustype,
                zeroed      = false,
            }
            o._insert_bonus(whichunit, oo)
            setmetatable(oo, o)
            return oo
        end
        function o:set_bonus(amount, ignore)
            o._set_modifier(self, self.amount, amount, ignore)
        end
        function o.set_base(whichunit, amount)
            o._base[whichunit]  = amount
            o._apply_modifier(whichunit)
        end
        function o.get_base(whichunit)
            return o._base[whichunit] or 0
        end
        function o.get_sum(whichunit)
            return o._sum[whichunit].total
        end
        function o.get_product(whichunit)
            if o._product[whichunit].zeros > 0 then
                return 0
            end
            return o._product[whichunit].total
        end
        function o:remove_bonus(ignore)
            if not self.amount then return;
            end

            self:set_bonus(o._def[self.bonus_type], ignore)
            o._access[self.bonus_type][self.unit].list:remove(self)
            
            self.bonus_type = nil
            self.amount     = nil
            self.zeroed     = nil
            self.unit       = nil
        end
        o.destroy = o.remove_bonus

        UnitDex.register("ENTER_EVENT", function()
            local unit = UnitDex.eventUnit
            o._assign_bonus_value(unit)
            if o._assign_base_value then
                o._assign_base_value(unit)
            end
        end)
        UnitDex.register("LEAVE_EVENT", function()
            local unit      = UnitDex.eventUnit
            for modifier in o._sum[unit].list:iterator() do
                modifier:remove_bonus(true)
            end
            for modifier in o._product[unit].list:iterator() do
                modifier:remove_bonus(true)
            end
            o._sum[unit].list:destroy()
            o._product[unit].list:destroy()
            o._sum[unit]        = nil
            o._product[unit]    = nil
            o._base[unit]       = nil
        end)
        return o
    end
end