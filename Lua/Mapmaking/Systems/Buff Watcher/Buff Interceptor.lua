do
    local tb        = getmetatable(BuffWatcher)
    local list      = LinkedList()
    local buffs     = SimpleList()
    tb._aphandler   = EventListener:create()

    local add_unit  
    Initializer("SYSTEM", function()
        local u_list    = SimpleList()
        local t         = CreateTimer()
        TimerStart(t, 0.00, false, function()
            for unit, pointer in u_list:iterator() do
                for buffid in buffs:iterator() do
                    tb._evaluate_buff(unit, buffid)
                end
                for buffid in list:iterator() do
                    tb._evaluate_buff(unit, buffid)
                end
                u_list:remove(pointer)
            end
            list:clear()
        end)
        PauseTimer(t)

        add_unit = function(unit)
            if u_list:is_in(unit) then return;
            end
            u_list:insert(unit)
            ResumeTimer(t)
        end
    end)

    function tb.register_buff(whichbuff)
        whichbuff = (type(whichbuff) == 'string' and FourCC(whichbuff)) or whichbuff

        if type(whichbuff) ~= 'number' then return;
        elseif buffs:is_in(whichbuff) then return;
        end
        buffs:insert(whichbuff)
    end
    function tb._on_apply(unit, buff, buffer)
        tb._aphandler:execute(unit, buff, buffer)
    end
    function tb._evaluate_buff(targ, buffid)
        if (GetUnitAbilityLevel(targ, buffid) == 0) then return;
        end 
        if (not tb._u_buff_list[targ]) or (not tb._u_buff_list[targ][buffid]) then
            local buffer = tb.watch(targ, buffid)
            tb._on_apply(targ, buffid, buffer)
        end
    end
    function tb.register_function(func)
        tb._aphandler:register(func)
    end

    --  Catch the moment the buffed unit is "damaged"
    DamageEvent.register_modifier("MODIFIER_EVENT_SYSTEM", function(targ, src, dmg)
        if dmg ~= 0.00 then return;
        elseif DamageEvent.current.atktype ~= ATTACK_TYPE_NORMAL then return;
        elseif (DamageEvent.current.dmgtype ~= DAMAGE_TYPE_UNKNOWN)
            and (DamageEvent.current.dmgtype ~= DAMAGE_TYPE_NORMAL) then return;
        end
        --  Check the source and target for any lost or gained buffs.
        if tb._u_buff_list[src] then
            for self in tb._u_buff_list[src].list:iterator() do
                if GetUnitAbilityLevel(src, self.buff) == 0 then
                    list:insert(self.buff)
                    tb._destroy(self)
                end
            end
        end
        add_unit(targ)
    end)
end