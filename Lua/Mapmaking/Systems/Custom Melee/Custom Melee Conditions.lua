local tb    = getmetatable(CustomMelee)
local mtb   = {
    ENUM_GROUP  = CreateGroup(),
    TEST_GROUP  = CreateGroup(),
}
local hall  = tb._hall

mtb.get_ally_sc     = MeleeGetAllyStructureCount
function mtb.init_tournament()
    -- Create a timer window for the "finish soon" timeout period, it has no timer
    -- because it is driven by real time (outside of the game state to avoid desyncs)
    bj_finishSoonTimerDialog = CreateTimerDialog(nil)

    local trig  = CreateTrigger()
    TriggerRegisterGameEvent(trig, EVENT_GAME_TOURNAMENT_FINISH_SOON)
    TriggerAddAction(trig, MeleeTriggerTournamentFinishSoon)

    -- Set a trigger to fire when we receive a "finish now" game event
    trig = CreateTrigger()
    TriggerRegisterGameEvent(trig, EVENT_GAME_TOURNAMENT_FINISH_NOW)
    TriggerAddAction(trig, MeleeTriggerTournamentFinishNow)
end
function mtb.check_victors()
    local players   = CreateForce()
    local gameOver  = false

    -- Check to see if any players have opponents remaining.
    for i = 0, bj_MAX_PLAYERS - 1 do
        if (not bj_meleeDefeated[i]) then
            -- Determine whether or not this player has any remaining opponents.
            for j = 0, bj_MAX_PLAYERS - 1 do
                -- If anyone has an opponent, noone can be victorious yet.
                if MeleePlayerIsOpponent(i, j) then
                    DestroyForce(players)
                    return CreateForce()
                end
            end

            -- Keep track of each opponentless player so that we can give
            -- them a victory later.
            ForceAddPlayer(players, Player(i))
            gameOver = true
        end
    end
    -- Set the game over global flag
    bj_meleeGameOver = gameOver
    return players
end
function mtb.get_ally_kscallback()
    local uu    = GetEnumUnit()
    local id    = GetUnitTypeId(uu)
    if (not hall.pointer[id]) or (not UnitAlive(uu)) then
        GroupRemoveUnit(mtb.ENUM_GROUP, uu)
    end
end
function mtb.get_ally_ksc(player)
    local count  = 0
    -- Count the number of buildings controlled by all not-yet-defeated co-allies.
    for i = 0, bj_MAX_PLAYERS - 1 do
        local other = Player(i)
        if (PlayersAreCoAllied(player, other)) then
            GroupEnumUnitsOfPlayer(mtb.ENUM_GROUP, other, nil)
            ForGroup(mtb.ENUM_GROUP, mtb.get_ally_kscallback)
            count  = count + BlzGroupGetSize(mtb.ENUM_GROUP)
        end
    end
    return count
end
function mtb.is_crippled(player)
    return (mtb.get_ally_sc(player) > 0) and (mtb.get_ally_ksc(player) <= 0)
end
function mtb.on_check_cripples(player, i)
    local is_crap   = mtb.is_crippled(player)
    if bj_playerIsCrippled[i] == is_crap then return;
    end

    bj_playerIsCrippled[i]  = is_crap
    if is_crap then
        -- Player became crippled; start their cripple timer.
        TimerStart(bj_crippledTimer[i], bj_MELEE_CRIPPLE_TIMEOUT, false, MeleeCrippledPlayerTimeout)
        if (GetLocalPlayer() == player) then
            -- Show the timer window.
            TimerDialogDisplay(bj_crippledTimerWindows[i], true)
            -- Display a warning message.
            DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, MeleeGetCrippledWarningMessage(player))
        end
    else
        -- Player became uncrippled; stop their cripple timer.
        PauseTimer(bj_crippledTimer[i])
        if (GetLocalPlayer() == player) then
            -- Hide the timer window for this player.
            TimerDialogDisplay(bj_crippledTimerWindows[i], false)

            -- Display a confirmation message if the player's team is still alive.
            if (mtb.get_ally_sc(player) > 0) then
                if (bj_playerIsExposed[i]) then
                    DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNREVEALED"))
                else
                    DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION, GetLocalizedString("CRIPPLE_UNCRIPPLED"))
                end
            end
        end
        -- If the player granted shared vision, deny that vision now.
        MeleeExposePlayer(player, false)
    end
end
function mtb.check_cripples()
    if bj_finishSoonAllExposed then return;
    end
    -- Check each player to see if he or she has been crippled or uncrippled.
    for i = 0, bj_MAX_PLAYERS - 1 do
        local player    = Player(i)
        mtb.on_check_cripples(player, i)
    end
end
function mtb.check_losers_victors()
    local d_players   = CreateForce()
    local v_players 

    -- If the game is already over, do nothing
    if (bj_meleeGameOver) then
        DestroyForce(d_players)
        return
    end
    --[[
    If the game was disconnected then it is over, in this case we
    don't want to report results for anyone as they will most likely
    conflict with the actual game results
    ]]
    if (GetIntegerGameState(GAME_STATE_DISCONNECTED) ~= 0) then
        bj_meleeGameOver = true
        DestroyForce(d_players)
        return
    end

    -- Check each player to see if he or she has been defeated yet.
    for i = 0, bj_MAX_PLAYERS - 1 do
        local player = Player(i)
        if (not bj_meleeDefeated[i] and not bj_meleeVictoried[i]) then
            -- DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "Player" .. tostring(i) .. " has " .. tostring(mtb.get_ally_sc(player)) .. " ally buildings.")
            if (MeleeGetAllyStructureCount(player) <= 0) then
                -- Keep track of each defeated player so that we can give
                -- them a defeat later.
                ForceAddPlayer(d_players, Player(i))
                -- Set their defeated flag now so MeleeCheckForVictors
                -- can detect victors.
                bj_meleeDefeated[i] = true
            end
        end
    end
    -- Now that the defeated flags are set, check if there are any victors
    v_players = mtb.check_victors()

    -- Defeat all defeated players
    ForForce(d_players, MeleeDoDefeatEnum)
    -- Give victory to all victorious players
    ForForce(v_players, MeleeDoVictoryEnum)

    DestroyForce(d_players)
    DestroyForce(v_players)
    -- If the game is over we should remove all observers
    if (bj_meleeGameOver) then
        MeleeRemoveObservers()
    end
end
function mtb.check_lose_unit(whichunit)
    local owner = GetOwningPlayer(whichunit)
    if GetPlayerStructureCount(owner, true) <= 0 then
        mtb.check_losers_victors()
    end
    mtb.check_cripples()
end
function mtb.check_gain_unit(whichunit)
    local owner = GetOwningPlayer(whichunit)
    if (bj_playerIsCrippled[GetPlayerId(owner)]) then
        mtb.check_cripples()
    end
end

--  Trigger callback functions.
function mtb.on_building_cancel()
    mtb.check_lose_unit(GetTriggerUnit())
end
function mtb.on_building_death()
    local unit  = GetTriggerUnit()
    if not IsUnitType(unit, UNIT_TYPE_STRUCTURE) then return;
    end
    mtb.check_lose_unit(unit)
end
function mtb.on_building_start()
    mtb.check_gain_unit(GetTriggerUnit())
end
function mtb.on_player_defeat()
    local player = GetTriggerPlayer()
    CachePlayerHeroData(player)

    if (MeleeGetAllyCount(player) > 0) then
        -- If at least one ally is still alive and kicking, share units with
        -- them and proceed with death.
        ShareEverythingWithTeam(player)            
    else
        -- If no living allies remain, swap all units and buildings over to
        -- neutral_passive and proceed with death.
        MakeUnitsPassiveForTeam(player)
    end
    if (not bj_meleeDefeated[GetPlayerId(player)]) then
        MeleeDoDefeat(player)
    end
    mtb.check_losers_victors()
end
function mtb.on_player_leave()
    local player    = GetTriggerPlayer()
    -- Just show game over for observers when they leave
    if (IsPlayerObserver(player)) then
        RemovePlayerPreserveUnitsBJ(player, PLAYER_GAME_RESULT_NEUTRAL, false)
        return
    end

    -- Inspect the player for leaving while in queue.
    tb.dialog.remove_player(player)
    tb.dialog.check_unpause_all()
    CachePlayerHeroData(player)

    -- This is the same as defeat except the player generates the message 
    -- "player left the game" as opposed to "player was defeated".
    if (MeleeGetAllyCount(player) > 0) then
        -- If at least one ally is still alive and kicking, share units with
        -- them and proceed with death.
        ShareEverythingWithTeam(player)
    else
        -- If no living allies remain, swap all units and buildings over to
        -- neutral_passive and proceed with death.
        MakeUnitsPassiveForTeam(player)
    end
    MeleeDoLeave(player)
    if not tb.dialog.pause_state then
        mtb.check_losers_victors()
    else
        doAfter(0.01, mtb.check_losers_victors)
    end
end
function mtb.check_generic()
    mtb.check_losers_victors()
    mtb.check_cripples()
end
function mtb.on_player_alliance_change()
    if tb.dialog.pause_state then
        doAfter(0.01, mtb.check_generic)
        return
    end
    mtb.check_generic()
end

function tb.init_victory_defeat()
    mtb.init_tournament()

    local trigs = {}
    for i = 1, 6 do
        trigs[i]    = CreateTrigger()
    end

    do
        TriggerAddCondition(trigs[1], Condition(mtb.on_building_cancel))
        TriggerAddCondition(trigs[2], Condition(mtb.on_building_death))
        TriggerAddCondition(trigs[3], Condition(mtb.on_building_start))
        TriggerAddCondition(trigs[4], Condition(mtb.on_player_defeat))
        TriggerAddCondition(trigs[5], Condition(mtb.on_player_leave))
        TriggerAddCondition(trigs[6], Condition(mtb.on_player_alliance_change))
    end
    UnitDex.register("ENTER_EVENT", function()
        if IsUnitType(UnitDex.eventUnit, UNIT_TYPE_STRUCTURE) then
            mtb.check_gain_unit(UnitDex.eventUnit)
        end
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local unit = UnitDex.eventUnit
        if not IsUnitType(unit, UNIT_TYPE_STRUCTURE) then return;
        end
        doAfter(0.01, mtb.check_lose_unit, unit)
    end)

    for i = 0, bj_MAX_PLAYERS - 1 do
        local player = Player(i)

        -- Make sure this player slot is playing.
        if (GetPlayerSlotState(player) == PLAYER_SLOT_STATE_PLAYING) then
            bj_meleeDefeated[i]     = false
            bj_meleeVictoried[i]    = false

            -- Create a timer and timer window in case the player is crippled.
            bj_playerIsCrippled[i]          = false
            bj_playerIsExposed[i]           = false
            bj_crippledTimer[i]             = CreateTimer()
            bj_crippledTimerWindows[i]      = CreateTimerDialog(bj_crippledTimer[i])
            TimerDialogSetTitle(bj_crippledTimerWindows[i], MeleeGetCrippledTimerMessage(player))

            -- Set a trigger to fire whenever a building is cancelled for this player.
            TriggerRegisterPlayerUnitEvent(trigs[1], player, EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, nil)
            -- Set a trigger to fire whenever a unit dies for this player.
            TriggerRegisterPlayerUnitEvent(trigs[2], player, EVENT_PLAYER_UNIT_DEATH, nil)
            -- Set a trigger to fire whenever a unit begins construction for this player
            TriggerRegisterPlayerUnitEvent(trigs[3], player, EVENT_PLAYER_UNIT_CONSTRUCT_START, nil)
            -- Set a trigger to fire whenever this player defeats-out
            TriggerRegisterPlayerEvent(trigs[4], player, EVENT_PLAYER_DEFEAT)
            -- Set a trigger to fire whenever this player leaves
            TriggerRegisterPlayerEvent(trigs[5], player, EVENT_PLAYER_LEAVE)
            -- Set a trigger to fire whenever this player changes his/her alliances.
            TriggerRegisterPlayerAllianceChange(trigs[6], player, ALLIANCE_PASSIVE)
            TriggerRegisterPlayerStateEvent(trigs[6], player, PLAYER_STATE_ALLIED_VICTORY, EQUAL, 1)
        else
            bj_meleeDefeated[i] = true
            bj_meleeVictoried[i] = false

            -- Handle leave events for observers
            if (IsPlayerObserver(player)) then
                -- Set a trigger to fire whenever this player leaves
                TriggerRegisterPlayerEvent(trigs[6], player, EVENT_PLAYER_LEAVE)
            end
        end
    end
    -- Test for victory / defeat at startup, in case the user has already won / lost.
    -- Allow for a short time to pass first, so that the map can finish loading.
    doAfter(2.0, mtb.check_generic)
end