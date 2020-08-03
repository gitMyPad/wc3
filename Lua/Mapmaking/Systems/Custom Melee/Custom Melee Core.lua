do
    local tb    = protected_table()
    tb._race    = {
        [RACE_HUMAN]        = {},
        [RACE_ORC]          = {},
        [RACE_UNDEAD]       = {},
        [RACE_NIGHTELF]     = {},
        [RACE_DEMON]        = {},
        [RACE_OTHER]        = {},
    }
    tb._hall    = {pointer={}}
    tb._hero    = {pointer={}}
    CustomMelee = setmetatable({}, tb)

    function tb._new(o)
        o           = o or {}
        o.race      = 0
        o.name      = 0
        o.setup     = 0
        o.ai_script = 0
        o.hall_list = {pointer={}}
        o.hero_list = {pointer={}}
        setmetatable(o, tb)
        return o
    end
    function tb:_get_random_hero(whichplayer, hero_x, hero_y)
        local v     = VersionGet()
        local roll  = math.random(1, #self.hero_list)
        local owner = GetPlayerId(whichplayer)
    
        -- Translate the roll into a unitid.
        local pick  = self.hero_list[roll]
        local hero  = CreateUnit(whichplayer, pick, hero_x, hero_y, bj_UNIT_FACING)
        if bj_meleeGrantHeroItems then
            if hero and (bj_meleeTwinkedHeroes[owner] < bj_MELEE_MAX_TWINKED_HEROES) then
                UnitAddItemById(hero, FourCC('stwp'))
                bj_meleeTwinkedHeroes[owner] = bj_meleeTwinkedHeroes[owner] + 1
            end
        end
        return hero
    end

    function tb.add_faction(race, factionname)
        local o = tb._new()
        o.race  = race
        o.name  = factionname
        o.setup = 0
        tb._race[race][#tb._race[race] + 1] = o
        return o
    end
    function tb:add_heroID(...)
        local t = {...}
        if #t == 0 then return;
        end

        for i = 1, #t do
            t[i]    = ((type(t[i]) == 'string') and FourCC(t[i])) or t[i]
            if not self.hero_list.pointer[t[i]] then
                self.hero_list[#self.hero_list + 1] = t[i]
                self.hero_list.pointer[t[i]]        = #self.hero_list
            end
            if not tb._hero.pointer[t[i]] then
                tb._hero[#tb._hero + 1] = t[i]
                tb._hero.pointer[t[i]]  = #tb._hero
            end
        end
    end
    function tb:add_hallID(...)
        local t = {...}
        if #t == 0 then return;
        end

        for i = 1, #t do
            t[i]    = ((type(t[i]) == 'string') and FourCC(t[i])) or t[i]
            if not self.hall_list.pointer[t[i]] then
                self.hall_list[#self.hall_list + 1] = t[i]
                self.hall_list.pointer[t[i]]        = #self.hall_list
            end
            if not tb._hall.pointer[t[i]] then
                tb._hall[#tb._hall + 1] = t[i]
                tb._hall.pointer[t[i]]  = #tb._hall
            end
        end
    end
    function tb:remove_hallID(...)
        local t = {...}
        --  Assume that the parameters passed are raw codes.
        if #t == 0 then return;
        end
        for i = 1, #t do
            t[i]   = ((type(t[i]) == 'string') and FourCC(t[i])) or t[i]
            if self.hall_list.pointer[t[i]] then
                local j = self.hall_list.pointer[t[i]]
                while j < #self.hall_list do
                    self.hall_list[j]   =  self.hall_list[j + 1]
                    self.hall_list.pointer[self.hall_list[j + 1]]   = j
                    j   = j + 1
                end
                self.hall_list[#self.hall_list] = nil
            end
            if tb._hall.pointer[t[i]] then
                local j = tb._hall.pointer[t[i]]
                while j < #tb._hall do
                    tb._hall[j]   =  tb._hall[j + 1]
                    tb._hall.pointer[tb._hall[j + 1]]   = j
                    j   = j + 1
                end
                tb._hall[#tb._hall] = nil
            end
        end
    end
    function tb:remove_heroID(...)
        local t = {...}
        --  Assume that the parameters passed are raw codes.
        if #t == 0 then return;
        end
        for i = 1, #t do
            t[i]   = ((type(t[i]) == 'string') and FourCC(t[i])) or t[i]
            if self.hero_list.pointer[t[i]] then
                local j = self.hero_list.pointer[t[i]]
                while j < #self.hero_list do
                    self.hero_list[j]   =  self.hero_list[j + 1]
                    self.hero_list.pointer[self.hero_list[j + 1]]   = j
                    j   = j + 1
                end
                self.hero_list[#self.hero_list] = nil
            end
            if tb._hero.pointer[t[i]] then
                local j = tb._hero.pointer[t[i]]
                while j < #tb._hero do
                    tb._hero[j]   =  tb._hero[j + 1]
                    tb._hero.pointer[tb._hero[j + 1]]   = j
                    j   = j + 1
                end
                tb._hero[#tb._hero] = nil
            end
        end
    end

    function tb:config_setup(func)
        if not is_function(func) then return;
        end
        self.setup  = func
    end
    function tb:ai_setup(melee_ai)
        if type(melee_ai) ~= 'string' then return;
        end
        self.ai_script  = melee_ai
    end
    function tb:generate_setup(func)
        local t = {}
        return function(whichplayer, startloc, doheroes, docamera, dopreload)
            t.random_flag   = IsMapFlagSet(MAP_RANDOM_HERO)
            t.peon_x, t.peon_y, t.hero_x, t.hero_y = func(whichplayer, startloc,
                                                          doheroes, docamera, dopreload)
            if doheroes then
                if t.random_flag then
                    tb._get_random_hero(self, whichplayer, t.hero_x, t.hero_y)
                else
                    SetPlayerState(whichplayer, PLAYER_STATE_RESOURCE_HERO_TOKENS, bj_MELEE_STARTING_HERO_TOKENS)
                end
            end
            if (docamera) then
                -- Center the camera on the initial Peasants.
                SetCameraPositionForPlayer(whichplayer, t.peon_x, t.peon_y)
                SetCameraQuickPositionForPlayer(whichplayer, t.peon_x, t.peon_y)
            end
        end
    end
end