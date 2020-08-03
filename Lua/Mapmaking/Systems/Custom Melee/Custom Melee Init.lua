do
    local tb            = getmetatable(CustomMelee)
    local hall          = tb._hall
    local hero          = tb._hero
    local p_faction     = tb._faction
    local funcs         = {}

    --  Special Dialog functions

    --  Melee-only mimic functions.
    function funcs.starting_vis()
        SetFloatGameState(GAME_STATE_TIME_OF_DAY, bj_MELEE_STARTING_TOD)
    end
    function funcs.starting_hero_limit()
        local p
        for player_id = 0,bj_MAX_PLAYERS-1 do
            p = Player(player_id)
            SetPlayerTechMaxAllowed(p, FourCC('HERO'), bj_MELEE_HERO_LIMIT)

            -- ReducePlayerTechMaxAllowed(p, <heroType>, bj_MELEE_HERO_TYPE_LIMIT)
            for index = 1, #hero do
                SetPlayerTechMaxAllowed(p, hero[index], bj_MELEE_HERO_TYPE_LIMIT)
            end
        end
    end
    function funcs.grant_hero_scroll(whichunit)
        if not IsUnitType(whichunit, UNIT_TYPE_HERO) then return;
        end

        local owner   = GetPlayerId(GetOwningPlayer(whichunit))
        -- If we haven't twinked N heroes for this player yet, twink away.
        if (bj_meleeTwinkedHeroes[owner] < bj_MELEE_MAX_TWINKED_HEROES) then
            UnitAddItemById(whichunit, FourCC('stwp'))
            bj_meleeTwinkedHeroes[owner] = bj_meleeTwinkedHeroes[owner] + 1
        end
    end
    function funcs.grant_hero_items()
        local t = CreateTrigger()
        for player_id = 0, bj_MAX_PLAYER_SLOTS - 1 do
            bj_meleeTwinkedHeroes[player_id] = 0
            if player_id < bj_MAX_PLAYERS then
                TriggerRegisterPlayerUnitEvent(t, Player(player_id), EVENT_PLAYER_UNIT_TRAIN_FINISH, nil)
            end
        end
        TriggerAddCondition(t, Filter(function()
            funcs.grant_hero_scroll(GetTrainedUnit())
        end))

        t = CreateTrigger()
        TriggerRegisterPlayerUnitEvent(t, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL, nil)
        TriggerAddCondition(t, Filter(function()
            funcs.grant_hero_scroll(GetSoldUnit())
        end))
        bj_meleeGrantHeroItems  = true
    end
    function funcs.starting_resources()
        local startingGold
        local startingLumber
        local v = VersionGet()

        if (v == VERSION_REIGN_OF_CHAOS) then
            startingGold, startingLumber = bj_MELEE_STARTING_GOLD_V0, bj_MELEE_STARTING_LUMBER_V0
        else
            startingGold, startingLumber = bj_MELEE_STARTING_GOLD_V1, bj_MELEE_STARTING_LUMBER_V1
        end

        local p
        for player_id = 0,bj_MAX_PLAYERS - 1 do
            p = Player(player_id)
            if (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, startingGold)
                SetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER, startingLumber)
            end
        end
    end
    function funcs.clear_units()
        local p
        local loc
        local locX
        local locY
        local g     = CreateGroup()
        for player_id = 0,bj_MAX_PLAYERS-1 do
            p = Player(player_id)
            if (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                loc         = GetPlayerStartLocation(p)
                locX, locY  = GetStartLocationX(loc), GetStartLocationY(loc)

                GroupEnumUnitsInRange(g, locX, locY, bj_MELEE_CLEAR_UNITS_RADIUS, nil)
                local enum_unit = FirstOfGroup(g)
                while enum_unit do
                    GroupRemoveUnit(g, enum_unit)
                    if GetOwningPlayer(enum_unit) == Player(PLAYER_NEUTRAL_AGGRESSIVE) then
                        RemoveUnit(enum_unit)
                    elseif (GetOwningPlayer(enum_unit) == Player(PLAYER_NEUTRAL_AGGRESSIVE)) and
                            not IsUnitType(enum_unit, UNIT_TYPE_STRUCTURE) then
                        RemoveUnit(enum_unit)
                    end
                    enum_unit = FirstOfGroup(g)
                end
            end
        end
        DestroyGroup(g)
    end
    function funcs.select_def_faction(whichplayer)
        local race  = GetPlayerRace(whichplayer)
        if (#tb._race[race] == 1) or (GetPlayerController(whichplayer) == MAP_CONTROL_COMPUTER) then
            tb.dialog.create_race(whichplayer, race, 1)
            return
        end
        tb.dialog.add_player(whichplayer)
    end
    function funcs.starting_units()
        for player_id = 0, bj_MAX_PLAYERS-1 do
            local p = Player(player_id)
            if (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                funcs.select_def_faction(p)
            end
        end
        tb.dialog.show()
    end
    function funcs.starting_ai()
        for player_id = 0,bj_MAX_PLAYERS-1 do
            local indexPlayer = Player(player_id)
            if (GetPlayerSlotState(indexPlayer) == PLAYER_SLOT_STATE_PLAYING) then
                local indexRace = GetPlayerRace(indexPlayer)
                if (GetPlayerController(indexPlayer) == MAP_CONTROL_COMPUTER) then
                    -- Run a race-specific melee AI script.
                    StartMeleeAI(indexPlayer, p_faction[player_id].ai_script)
                    if indexRace == RACE_UNDEAD then
                        RecycleGuardPosition(bj_ghoul[player_id])
                    end
                    ShareEverythingWithTeamAI(indexPlayer)
                end
            end
        end
    end
    function funcs.victory_defeat()
        tb.init_victory_defeat()
    end

    function tb.initialization()
        funcs.starting_vis()
        funcs.starting_hero_limit()
        funcs.grant_hero_items()
        funcs.starting_resources()
        funcs.clear_units()
        funcs.starting_units()
        funcs.starting_ai()
        funcs.victory_defeat()
    end
end