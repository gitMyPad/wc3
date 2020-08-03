do
    local exp       = protected_table({
        MAX_RANGE   = 1200.00,   --  This is based on Gameplay Constants
        HERO_EXP    = {}
    })
    exp.eventUnit   = 0
    exp.xpAmount    = 0
    exp.xpGained    = 0

    local evt       = EventListener:create()
    local function filter_heroes(unit)
        return IsHeroUnitId(GetUnitTypeId(unit))
    end
    local function update_exp(unit)
        if not exp.HERO_EXP[unit] then return end

        local prev_xp       = exp.HERO_EXP[unit]
        exp.HERO_EXP[unit]  = GetHeroXP(unit)
        if exp.HERO_EXP[unit] ~= prev_xp then
            local prev_unit = exp.eventUnit
            local prev_gain = exp.xpGained
            local prev_amnt = exp.xpAmount

            exp.eventUnit   = unit
            exp.xpAmount    = exp.HERO_EXP[unit]
            exp.xpGained    = exp.HERO_EXP[unit] - prev_xp
            evt:execute(exp.eventUnit, exp.xpAmount, exp.xpGained)
            exp.eventUnit   = prev_unit
            exp.xpAmount    = prev_gain
            exp.xpGained    = prev_amnt
        end
    end

    local natives               = {}
    natives.SetHeroLevel        = SetHeroLevel
    natives.SetHeroXP           = SetHeroXP
    natives.AddHeroXP           = AddHeroXP
    natives.UnitStripHeroLevel  = UnitStripHeroLevel
    
    function SetHeroLevel(whichhero, level, showeyecandy)
        natives.SetHeroLevel(whichhero, level, showeyecandy)
        update_exp(whichhero)
    end
    function SetHeroXP(whichhero, newxpval, showeyecandy)
        natives.SetHeroXP(whichhero, newxpval, showeyecandy)
        update_exp(whichhero)
    end
    function AddHeroXP(whichhero, xptoadd, showeyecandy)
        natives.AddHeroXP(whichhero, xptoadd, showeyecandy)
        update_exp(whichhero)
    end
    function UnitStripHeroLevel(whichhero, howmanylevels)
        natives.UnitStripHeroLevel(whichhero, howmanylevels)
        update_exp(whichhero)
    end

    UnitDex.register("ENTER_EVENT", function(unit)
        if filter_heroes(unit) then
            exp.HERO_EXP[unit] = GetHeroXP(unit)
        end
    end)
    UnitDex.register("LEAVE_EVENT", function(unit)
        if exp.HERO_EXP[unit] then
            exp.HERO_EXP[unit] = nil
        end
    end)

    Initializer("SYSTEM", function()
        local grp   = CreateGroup()
        local enum  = exp.MAX_RANGE + 150.  --  Delta offset to cover niche cases.
        local function update()
            if exp.HERO_EXP[GetTriggerUnit()] then
                update_exp(GetTriggerUnit())
            end
        end
        local function enum_update()
            local uu    = GetEnumUnit()
            if exp.HERO_EXP[uu] then
                update_exp(uu)
            end
        end        
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, update)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, update)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_USE_ITEM, update)

        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_HERO_LEVEL, update)
        RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, function()
            local dead      = GetTriggerUnit()
            local cx, cy    = GetUnitX(dead), GetUnitY(dead)
            GroupEnumUnitsInRange(grp, cx, cy, enum, nil)
            ForGroup(grp, enum_update)
        end)
    end)
    function exp.register(func)
        evt:register(func)
    end
    ExperienceEvent = setmetatable({}, exp)
end