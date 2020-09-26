do
    local tb                = getmetatable(CustomRaceSystem)
    local melee             = {}
    CustomRace              = setmetatable({}, tb)
    CustomRace.faction      = {}
    CustomRace.countdown    = {
        TICKS               = 3,
        INTERVAL            = 1.00,
        INCLUDE_EXTRA_TICK  = true,
        Z_OFFSET            = 800.00,
    }

    function melee.generateTick()
        local snd   = CreateSound( "Sound\\Interface\\BattleNetTick.wav", false, false, false, 10, 10, "" )
        SetSoundParamsFromLabel( snd, "ChatroomTimerTick" )
        SetSoundDuration( snd, 476 )
        return snd
    end
    function melee.generateHorn()
        local snd   = CreateSound( "Sound\\Ambient\\DoodadEffects\\TheHornOfCenarius.wav", false, false, false, 10, 10, "DefaultEAXON" )
        SetSoundParamsFromLabel( snd, "HornOfCenariusSound" )
        SetSoundDuration( snd, 12120 )
        return snd
    end
    function melee.playSound(snd)
        StartSound(snd)
        KillSoundWhenDone(snd)
    end
    function melee.grantItemsToHero(whichhero)
        if not IsUnitType(whichhero, UNIT_TYPE_HERO) then
            return
        end
        local owner = GetPlayerId(GetOwningPlayer(whichhero))
        -- If we haven't twinked N heroes for this player yet, twink away.
        if (bj_meleeTwinkedHeroes[owner] < bj_MELEE_MAX_TWINKED_HEROES) then
            UnitAddItemById(whichhero, FourCC('stwp'))
            bj_meleeTwinkedHeroes[owner] = bj_meleeTwinkedHeroes[owner] + 1
        end
    end
    function melee.clearNearbyUnits(locx, locy, range)
        local grp   = CreateGroup()
        GroupEnumUnitsInRange(grp, locx, locy, range, nil)
        ForGroup(grp, function()
            local filterUnit    = GetEnumUnit()
            local owner         = GetOwningPlayer(filterUnit)
            if (owner == Player(PLAYER_NEUTRAL_AGGRESSIVE)) then
                -- Remove any Neutral Hostile units from the area.
                RemoveUnit(filterUnit)
            elseif (owner == Player(PLAYER_NEUTRAL_PASSIVE)) and
                    not IsUnitType(filterUnit, UNIT_TYPE_STRUCTURE) then
                -- Remove non-structure Neutral Passive units from the area.
                RemoveUnit(filterUnit)
            end
        end)
        DestroyGroup(grp)
    end

    local function forAllPlayers(func)
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            func(i, Player(i))
        end
    end
    local function startingVis()
        SetFloatGameState(GAME_STATE_TIME_OF_DAY, bj_MELEE_STARTING_TOD)
    end
    local function startingHeroLimit()
        forAllPlayers(function(id, player)
            SetPlayerTechMaxAllowed(player, FourCC('HERO'), bj_MELEE_HERO_LIMIT)
            for i = 1, #tb._hero do
                SetPlayerTechMaxAllowed(player, tb._hero[i], bj_MELEE_HERO_TYPE_LIMIT)
            end
        end)
    end
    local function grantHeroItems()
        local trig  = CreateTrigger()
        TriggerAddCondition(trig, Condition(function()
            melee.grantItemsToHero(GetTrainedUnit())
        end))
        forAllPlayers(function(id, player)
            if id >= bj_MAX_PLAYERS then
                return
            end
            TriggerRegisterPlayerUnitEvent(trig, player, EVENT_PLAYER_UNIT_TRAIN_FINISH, nil)
        end)

        trig        = CreateTrigger()
        TriggerRegisterPlayerUnitEvent(trig, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL, filterMeleeTrainedUnitIsHeroBJ)
        TriggerAddAction(trig, function()
            melee.grantItemsToHero(GetSoldUnit())
        end)
        
        bj_meleeGrantHeroItems  = true
    end
    
    local slotStatus    = {}
    local function startingResources()
        if (VersionGet() == VERSION_REIGN_OF_CHAOS) then
            startingGold    = bj_MELEE_STARTING_GOLD_V0
            startingLumber  = bj_MELEE_STARTING_LUMBER_V0
        else
            startingGold    = bj_MELEE_STARTING_GOLD_V1
            startingLumber  = bj_MELEE_STARTING_LUMBER_V1
        end
        forAllPlayers(function(id, player)
            slotStatus[id]  = GetPlayerSlotState(player)
            if id >= bj_MAX_PLAYERS or 
               (slotStatus[id] ~= PLAYER_SLOT_STATE_PLAYING) then
                return
            end
            SetPlayerState(player, PLAYER_STATE_RESOURCE_GOLD, startingGold)
            SetPlayerState(player, PLAYER_STATE_RESOURCE_LUMBER, startingLumber)
        end)
    end
    local function clearExcessUnits()
        forAllPlayers(function(id, player)
            if id >= bj_MAX_PLAYERS or (slotStatus[id] ~= PLAYER_SLOT_STATE_PLAYING) then
                return
            end
            local locid         = GetPlayerStartLocation(player)
            local locx, locy    = GetStartLocationX(locid), GetStartLocationY(locid)
            melee.clearNearbyUnits(locx, locy, bj_MELEE_CLEAR_UNITS_RADIUS)
        end)
    end
    local function startRaceSelection()
        if not CustomRaceUI then
            error("startRaceSelection >> CustomRaceUI not found")
        end
        CustomRaceUI.init()

        forAllPlayers(function(id, player)
            if id >= bj_MAX_PLAYERS or (slotStatus[id] ~= PLAYER_SLOT_STATE_PLAYING) then
                return
            end
            CustomRaceUI.feedPlayerData(id, player)
            CustomRaceUI.processPlayer(player)
        end)
        CustomRaceUI.checkFactionSelection()
    end
    local function pauseAll()
        SuspendTimeOfDay(true)
        CustomRace.pauseFlag    = true
        CustomRace.pauseTrig    = CreateTrigger()
        TriggerAddCondition(CustomRace.pauseTrig, Condition(function()
            if CustomRace.pauseFlag then
                PauseUnit(GetTriggerUnit(), true)
            end
        end))        
        local rect, reg         = GetWorldBounds(), CreateRegion()
        RegionAddRect(reg, rect)
        TriggerRegisterEnterRegion(CustomRace.pauseTrig, reg, nil)

        local grp               = CreateGroup()
        GroupEnumUnitsInRect(grp, rect, nil)
        ForGroup(grp, function()
            PauseUnit(GetEnumUnit(), true)
        end)
        DestroyGroup(grp)
    end
    local function unpauseAll()
        SuspendTimeOfDay(false)
        CustomRace.pauseFlag    = nil

        DestroyTrigger(CustomRace.pauseTrig)
        CustomRace.pauseTrig    = nil

        local grp               = CreateGroup()
        local rect              = GetWorldBounds()
        GroupEnumUnitsInRect(grp, rect, nil)
        ForGroup(grp, function()
            PauseUnit(GetEnumUnit(), false)
        end)
        DestroyGroup(grp)
        RemoveRect(rect)
    end
    local function startingCamera()
        local player    = GetLocalPlayer()
        local id        = GetPlayerId(player)
        local dur       = ((CustomRace.countdown.TICKS + 1) + 
                          ((CustomRace.countdown.INCLUDE_EXTRA_TICK and 1) or 0))*CustomRace.countdown.INTERVAL
        if IsPlayerObserver(player) then
            return
        elseif slotStatus[id] ~= PLAYER_SLOT_STATE_PLAYING then
            return
        end
        local locid         = GetPlayerStartLocation(player)
        local locx, locy    = GetStartLocationX(locid), GetStartLocationY(locid)
        PanCameraToTimedWithZ(locx, locy, CustomRace.countdown.Z_OFFSET, 0)
        --ResetToGameCamera(dur)
    end
    local function startingUnits()
        Preloader("scripts\\SharedMelee.pld")
        forAllPlayers(function(id, player)
            if id >= bj_MAX_PLAYERS or (slotStatus[id] ~= PLAYER_SLOT_STATE_PLAYING) then
                return
            end
            local race      = GetPlayerRace(player)
            local faction   = tb._container[race][CustomRace.faction[id]]
            local startloc  = GetStartLocationLoc(GetPlayerStartLocation(player))
            if faction then
                if (not faction.setup) or (faction.setup) and
                (not pcall(faction.setup, player, startloc, true, true, true)) and (tb._DEBUG) then
                    print("Warning! Setup function failed for the following player:", GetPlayerName(player))
                    print("Faction ID:", faction.name or ("Faction(" .. tostring(CustomRace.faction[id]) .. ")"))
                end
                RemoveLocation(startloc)
                if GetPlayerController(player) == MAP_CONTROL_COMPUTER and (not faction.aiSetup) or
                ((faction.aiSetup) and not pcall(faction.aiSetup, player) and (tb._DEBUG)) then
                    print("Warning! AI-Setup function failed for the following computer player:", GetPlayerName(player))
                    print("Faction ID:", faction.name or ("Faction(" .. tostring(CustomRace.faction[id]) .. ")"))
                end
            end
        end)
    end
    local function startingCountdown()
        local timer = CreateTimer()
        local ticks = CustomRace.countdown.TICKS + 1
        local disp  = ticks
        if CustomRace.countdown.INCLUDE_EXTRA_TICK then
            ticks   = ticks + 1
        end
        TimerStart(timer, CustomRace.countdown.INTERVAL, true, function()
            disp    = disp - 1
            ticks   = ticks - 1
            if ticks <= 0 then
                PauseTimer(timer)
                DestroyTimer(timer)
            end

            if disp == 0 then
                print("START!")
                melee.playSound(melee.generateHorn())
            elseif disp > 0 then
                print(disp)
                melee.playSound(melee.generateTick())
            end
            if ticks <= 0 then
                unpauseAll()
                xpcall(CustomRaceConditions.init, print)
            end
        end)
    end

    function CustomRace.initialization()
        startingVis()
        startingHeroLimit()
        grantHeroItems()
        startingResources()
        clearExcessUnits()
        pauseAll()
        startRaceSelection()
    end
    function CustomRace.start()
        startingUnits()
        startingCountdown()
        startingCamera()
    end
end