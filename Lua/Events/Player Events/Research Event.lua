do
    local tb        = protected_table()
    local native    = {}
    local ltb       = {stack = AllocTableEx(2)}
    ResearchEvent   = setmetatable({}, tb)

    tb._data        = {}
    tb._tech        = {list = LinkedList(), pointer = {}}
    tb._player_tech = {}
    tb._construct   = {}
    tb._handler     = EventListener:create()

    --  All elements in the variable argument list
    --  are assumed to be integers via FourCC
    function tb:add_unittype(...)
        local t = {...}
        if #t == 0 then return;
        end
        for i = 1, #t do
            local elem  = t[i]
            if not self.unittype.pointer[elem] then
                self.unittype.pointer[elem] = select(2,self.unittype.list:insert(elem))
            end
        end
    end
    function tb:remove_unittype(...)
        local t = {...}
        if #t == 0 then return;
        end
        for i = 1, #t do
            local elem  = t[i]
            if self.unittype.pointer[elem] then
                self.unittype.list:remove(self.unittype.pointer[elem])
                self.unittype.pointer[elem] = nil
            end
        end
    end
    --  Function arguments
    --  (techid, curunit, curlevel[, prevlevel])
    function tb.register(techid, func, ...)
        if type(techid) ~= 'number' then return;
        elseif not is_function(func) then return;
        end

        if not tb._data[techid] then
            tb._data[techid] = {
                unittype    = {list = LinkedList(), pointer = {}},
                callbacks   = EventListener:create()
            }
            setmetatable(tb._data[techid], tb)
            tb._tech.pointer[techid]    = select(2, tb._tech.list:insert(techid))
        end
        tb._data[techid]:add_unittype(...)
        tb._data[techid].callbacks:register(func)
        return tb._data[techid]
    end
    function tb.subscribe(func)
        tb._handler:register(func)
    end

    function tb._run_callback()
        local enum, enumtype; enum = GetEnumUnit(); enumtype = GetUnitTypeId(enum);
        if ltb.self.unittype.pointer[enumtype] then
            ltb.self.callbacks:execute(ltb.techid, enum, ltb.cur_level, ltb.prev_level)
        end
    end
    function tb:_do_callback(player, techid, cur_level, prev_level)
        local grp       = CreateGroup()
        local prev      = ltb.stack.request()

        prev.self       = ltb.self
        prev.prev_level = ltb.prev_level
        prev.cur_level  = ltb.cur_level
        prev.techid     = ltb.techid


        ltb.techid      = techid
        ltb.cur_level   = cur_level
        ltb.prev_level  = prev_level
        ltb.self        = self
        GroupEnumUnitsOfPlayer(grp, player, nil)
        ForGroup(grp, tb._run_callback)
        DestroyGroup(grp)

        ltb.self        = prev.self
        ltb.prev_level  = prev.prev_level
        ltb.cur_level   = prev.cur_level
        ltb.techid      = prev.techid
        ltb.stack.restore(prev)
    end
    function tb._do_generic_callback(player, techid, eventtype)
        eventtype = eventtype or ""
        tb._handler:execute(player, techid, eventtype)
    end
    function tb:_internal_check(player, techid)
        local cur_level     = GetPlayerTechCount(player, techid, true)
        local player_id     = GetPlayerId(player)
        local prev_level    = tb._player_tech[techid][player_id]
        if prev_level == cur_level then return;
        end
        tb._player_tech[techid][player_id]  = cur_level
        tb._do_callback(self, player, techid, cur_level, prev_level)
    end
    function tb._check_techid(player, techid)
        if not tb._data[techid] then return;
        end
        tb._internal_check(tb._data[techid], player, techid)
    end

    native.dec      = BlzDecPlayerTechResearched
    native.inc      = AddPlayerTechResearched
    native.set      = SetPlayerTechResearched

    function BlzDecPlayerTechResearched(player, techid, levels)
        native.dec(player, techid, levels)
        tb._do_generic_callback(player, techid)
        tb._check_techid(player, techid)
    end
    function AddPlayerTechResearched(player, techid, levels)
        native.inc(player, techid, levels)
        tb._do_generic_callback(player, techid)
        tb._check_techid(player, techid)
    end
    function SetPlayerTechResearched(player, techid, level)
        native.set(player, techid, level)
        tb._do_generic_callback(player, techid)
        tb._check_techid(player, techid)
    end

    Initializer("SYSTEM", function()
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_RESEARCH_FINISH, function()
            local player, techid    = GetTriggerPlayer(), GetResearched()
            tb._do_generic_callback(player, techid, "finish")
            tb._check_techid(player, techid)
        end)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_RESEARCH_START, function()
            local player, techid    = GetTriggerPlayer(), GetResearched()
            tb._do_generic_callback(player, techid, "start")
        end)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_RESEARCH_CANCEL, function()
            local player, techid    = GetTriggerPlayer(), GetResearched()
            tb._do_generic_callback(player, techid, "cancel")
        end)

        for techid in tb._tech.list:iterator() do
            tb._player_tech[techid] = {}
        end
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local p = Player(i)
            for techid in tb._tech.list:iterator() do
                tb._player_tech[techid][i]  = GetPlayerTechCount(p, techid, true)
                if tb._player_tech[techid][i] ~= 0 then
                    tb._do_callback(tb._data[techid], p, techid, tb._player_tech[techid][i], 0)
                end
            end
        end
    end)

    function tb._attempt_callback(whichunit, reverse_arg)
        local unittype = GetUnitTypeId(whichunit)
        local i = GetPlayerId(GetOwningPlayer(whichunit))
        for techid in tb._tech.list:iterator() do
            local self      = tb._data[techid]
            local cur_level = tb._player_tech[techid][i]
            if self.unittype.pointer[unittype] and (cur_level ~= 0) then
                if reverse_arg then
                    self.callbacks:execute(techid, whichunit, 0, cur_level)
                else
                    self.callbacks:execute(techid, whichunit, cur_level, 0)
                end
            end
        end
    end
    UnitDex.register("ENTER_EVENT", function()
        local unit = UnitDex.eventUnit
        if tb._construct[unit] then return;
        end
        tb._attempt_callback(unit, false)
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local unit = UnitDex.eventUnit
        if tb._construct[unit] then
            tb._construct[unit] = nil
            return
        end
        tb._attempt_callback(unit, true)
    end)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_START, function()
        tb._construct[GetConstructingStructure()] = true
    end)
    RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, function()
        local unit = GetConstructedStructure()
        tb._construct[unit] = nil
        tb._attempt_callback(unit, false)
    end)
end