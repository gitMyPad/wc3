do
    local tb        = protected_table()
    local techid    = {}
    local techused  = {}
    tb._pointer     = {}
    tb._selves      = SimpleList()
    tb._handler     = EventListener:create()
    TieredResearch  = setmetatable({}, tb)

    for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
        techused[i] = {}
    end

    function tb:add(levels, ...)
        levels  = levels or 1
        levels  = math.max(math.floor(levels), 1)

        local j = select('#', ...)
        if j <= 0 then return;
        end

        local self      = {list = SimpleList(), max = levels, handler = EventListener:create()}
        setmetatable(self, tb)
        tb._selves:insert(self)
        for i = 1, j do
            techid[i]   = select(i, ...)
            techid[i]   = (type(techid[i]) == 'string' and FourCC(techid[i])) or techid[i]
            if not tb._pointer[techid[i]] then
                tb._pointer[techid[i]]  = self
                self.list:insert(techid[i])
            end
            techid[i]   = nil
        end
        if Initializer.initialized("SYSTEM") then
            for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
                local usedlvl   = 0
                local player    = Player(i)
                for tech in self.list:iterator() do
                    usedlvl     = usedlvl + GetPlayerTechCount(player, tech, true)
                end
                techused[i][self]   = usedlvl
                tb._attempt_restrict(self, nil, i)
            end
        end
        return self
    end
    function tb:_attempt_restrict(tech, id)
        local usedlvl   = techused[id][self]
        local player    = Player(id)
        local lvl       = 0
        for research in self.list:iterator() do
            lvl     = lvl + GetPlayerTechCount(player, research, true)
            if research == tech then
                lvl = lvl + 1
            end
        end
        usedlvl             = lvl
        techused[id][self]  = usedlvl
        for research in self.list:iterator() do
            local lvl   = GetPlayerTechCount(player, research, true)
            if research == tech then
                lvl     = lvl + 1
            end
            SetPlayerTechMaxAllowed(player, research, self.max - usedlvl + lvl)
        end
        local is_max    = (not tech) and (usedlvl == self.max)
        self.handler:execute(player, usedlvl, is_max)
    end
    function tb:register(func)
        self.handler:register(func)
    end
    function tb.subscribe(func)
        tb._handler:register(func)
    end
    ResearchEvent.subscribe(function(player, tech, eventtype)
        if not tb._pointer[tech] then return;
        end

        local id    = GetPlayerId(player)
        local self  = tb._pointer[tech]
        if eventtype == "start" then
            tb._attempt_restrict(self, tech, id)
        else
            tb._attempt_restrict(self, nil, id)
        end
    end)

    Initializer("SYSTEM", function()
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local player    = Player(i)
            for self in tb._selves:iterator() do
                local usedlvl   = 0
                for tech in self.list:iterator() do
                    usedlvl     = usedlvl + GetPlayerTechCount(player, usedlvl, true)
                end
                techused[i][self]   = usedlvl
                tb._attempt_restrict(self, nil, i)
            end
        end
    end)
end