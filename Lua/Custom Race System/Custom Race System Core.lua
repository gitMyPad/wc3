do
    local tb            = {}
    local raceContainer = {
        [RACE_HUMAN]        = {},
        [RACE_ORC]          = {},
        [RACE_UNDEAD]       = {},
        [RACE_NIGHTELF]     = {},
        [RACE_DEMON]        = {},
        [RACE_OTHER]        = {},
    }
    CustomRaceSystem    = setmetatable({}, tb)

    --  Define __index and __newindex metamethods.
    tb.__index          = function(t, k)
        if type(k) == 'string' and k:sub(1,1) == '_' and k:sub(1,2) ~= '__' then
            return nil
        end
        return tb[k]
    end
    tb.__newindex       = function(t, k, v)
        if tb[k] then
            return
        end
        rawset(t, k, v)
    end
    tb._hall            = {}
    tb._hallptr         = {}
    tb._hero            = {}
    tb._heroptr         = {}
    tb._container       = raceContainer
    tb._DEBUG           = false
    
    local function printAfter(delay, ...)
        if not tb._DEBUG then
            return
        end
        local t = {...}
        TimerStart(CreateTimer(), delay or 0, false, function()
            PauseTimer(GetExpiredTimer())
            DestroyTimer(GetExpiredTimer())
            --  Ensure that the entry is
            if t then
                print(table.unpack(t))
            end
            t = nil
        end)
    end
    local function addFaction(race, faction)
        local t             = raceContainer[race] or {}
        raceContainer[race] = t
        t[#t+1]             = faction
    end

    function tb.create(race, name)
        local o     = {}
        o.race      = race
        o.name      = name or ""
        o.hall      = {}
        o.hallptr   = {}
        o.hero      = {}
        o.heroptr   = {}

        addFaction(race, o)
        setmetatable(o, tb)
        return o
    end
    function tb:addHall(...)
        local t = {...}
        if #t < 1 then
            return
        end
        for i = 1, #t do
            local id    = (type(t[i]) == 'string' and FourCC(t[i])) or t[i]
            if not self.hallptr[id] then
                self.hall[#self.hall + 1]   = id
                self.hallptr[id]            = #self.hall
            end
            if not tb._hallptr[id] then
                tb._hall[#tb._hall + 1]     = id
                tb._hallptr[id]             = #tb._hall
            end
        end
    end
    function tb:addHero(...)
        local t = {...}
        if #t < 1 then
            return
        end
        for i = 1, #t do
            local id    = (type(t[i]) == 'string' and FourCC(t[i])) or t[i]
            if not self.heroptr[id] then
                self.hero[#self.hero + 1]   = id
                self.heroptr[id]            = #self.hero
            end
            if not tb._heroptr[id] then
                tb._hero[#tb._hero + 1]     = id
                tb._heroptr[id]             = #tb._hero
            end
        end
    end
    function tb:defSetup(func)
        self.setup          = func
    end
    function tb:defAISetup(func)
        self.aiSetup        = func
    end
    function tb:defRacePic(picPath)
        self.racePic        = picPath or ""
    end
    function tb:defDescription(desc)
        self.description    = desc or ""
    end
    function tb:defName(name)
        self.name           = name or ""
    end
end