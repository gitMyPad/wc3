do
    --[[
        TO-DO:
        -   Inspect UI for any flaws.
        -   Implement tournament-based functions.
        -   Implement Default Race Setups.
        -   Verify system function through local multiplayer.
    ]]
    bj_MELEE_CRIPPLE_TIMEOUT    = 5.00
    
    local tb                = getmetatable(CustomRaceSystem)
    local internal          = {}
    local teams             = {
        allies              = {},
        enemies             = {}
    }
    local buildingGroup     = {}
    local triggers          = {}
    CustomRaceConditions    = setmetatable({}, tb)

    function internal.initGlobalVars(index, player)
        bj_meleeDefeated[index]         = false
        bj_meleeVictoried[index]        = false
        
        -- Create a timer and timer window in case the player is crippled.
        bj_playerIsCrippled[index]      = false
        bj_playerIsExposed[index]       = false

        bj_crippledTimer[index]         = CreateTimer()
        bj_crippledTimerWindows[index]  = CreateTimerDialog(bj_crippledTimer[index])
        TimerDialogSetTitle(bj_crippledTimerWindows[index], MeleeGetCrippledTimerMessage(player))
    end


    local victorEnemyCount  = 0
    function internal.checkVictorsEnum2()
        victorEnemyCount    = victorEnemyCount + 1
    end
    function internal.checkVictorsEnum()
        local player    = GetEnumPlayer()
        local id        = GetPlayerId(player)
        ForForce(teams.enemies[id], internal.checkVictorsEnum2)
    end
    function internal.checkVictors()
        if bj_meleeGameOver then
            return
        end
        victorEnemyCount    = 0
        ForForce(teams.players, internal.checkVictorsEnum)
        if victorEnemyCount > 0 then
            return
        end
        --  Award victory to all team players
        --  In this case, use a closure instead.
        ForForce(teams.players, function()
            local player    = GetEnumPlayer()
            local id        = GetPlayerId(player)
            if bj_meleeGameOver then
                return
            elseif bj_meleeVictoried[id] then
                return
            end
            bj_meleeVictoried[id]   = true
            internal.exposePlayerTeam(player, false)

            PauseTimer(bj_crippledTimer[id])
            if GetLocalPlayer() == player then
                TimerDialogDisplay(bj_crippledTimerWindows[id], false)
            end

            CachePlayerHeroData(player)
            RemovePlayerPreserveUnitsBJ(player, PLAYER_GAME_RESULT_VICTORY, false)
        end)
        bj_meleeGameOver    = true
    end

    --  Obtaining structure count and key structure count.
    local structCount       = {}
    function internal.getKeyStructureCountGroup(player, id)
        id                      = id or GetPlayerId(player)
        local size              = BlzGroupGetSize(buildingGroup[id]) - 1
        for i = 0, size do
            local unit  = BlzGroupUnitAt(buildingGroup[id], i)
            if tb._hallptr[GetUnitTypeId(unit)] ~= nil then
                structCount.keyCount    = structCount.keyCount + 1
            end
        end
    end
    function internal.getKeyStructureCountEnum()
        internal.getKeyStructureCountGroup(GetEnumPlayer())
    end
    function internal.getKeyStructureCount(excludeAllies, player, id)
        id                      = id or GetPlayerId(player)
        structCount.keyCount    = 0
        internal.getKeyStructureCountGroup(player, id)
        if (not excludeAllies) then
            ForForce(teams.allies[id], internal.getKeyStructureCountEnum)
        end
        return structCount.keyCount
    end
    function internal.getStructureCountEnum()
        local player        = GetEnumPlayer()
        local id            = GetPlayerId(player)
        structCount.count   = structCount.count + BlzGroupGetSize(buildingGroup[id])
    end
    function internal.getStructureCount(excludeAllies, player, id)
        id                  = id or GetPlayerId(player)
        structCount.count   = BlzGroupGetSize(buildingGroup[id])
        if (not excludeAllies) then
            ForForce(teams.allies[id], internal.getStructureCountEnum)
        end
        return structCount.count
    end

    --  This section handles exposure of bases.
    local exposeTable       = {}
    function internal.exposePlayerTeamEnum()
        ForceAddPlayer(exposeTable.allyforce, GetEnumPlayer())
    end
    function internal.exposePlayerTeamEx()
        local player    = GetEnumPlayer()
        local id        = GetPlayerId(player)
        CripplePlayer(player, exposeTable.force, exposeTable.flag)
        if exposeTable.updateFlag then
            bj_playerIsExposed[id]  = exposeTable.flag
        end
    end
    function internal.exposePlayerTeam(player, expose)
        local id                = GetPlayerId(player)
        exposeTable.force       = CreateForce()

        --  NOTE: The player by default is not included among
        --  the list of allies, so this behavior should be
        --  taken advantage of.

        --  Temporarily add the player to the list of allies
        ForceAddPlayer(teams.allies[id], player)

        exposeTable.flag        = false
        exposeTable.updateFlag  = false
        ForForce(teams.allies[id], internal.exposePlayerTeamEx)

        DestroyForce(exposeTable.force)
        exposeTable.flag        = expose
        exposeTable.updateFlag  = true
        exposeTable.force       = teams.enemies[id]
        ForForce(teams.allies[id], internal.exposePlayerTeamEx)

        ForceRemovePlayer(teams.allies[id], player)
    end

    --  This section handles exposure of crippling mechanics.
    local crippleTable  = {
        flag            = false,
        timerData       = {},
        active          = {}
    }
    function internal.crippleTeamHideWindows()
        local player                                = GetEnumPlayer()
        local id                                    = GetPlayerId(player)
        crippleTable.active[bj_crippledTimer[id]]   = nil

        if GetLocalPlayer() == player then
            TimerDialogDisplay(bj_crippledTimerWindows[id], false)
            DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                     MeleeGetCrippledWarningMessage(player))
        end
    end
    function internal.crippleTeamCallback()
        local player                                = crippleTable.timerData[GetExpiredTimer()]
        local id                                    = GetPlayerId(player)
        DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                 MeleeGetCrippledRevealedMessage(player))
        if GetLocalPlayer() == player then
            TimerDialogDisplay(bj_crippledTimerWindows[id], false)
        end
        if crippleTable.active[bj_crippledTimer[id]] then
            internal.exposePlayerTeam(player, true)
            ForForce(teams.allies, internal.crippleTeamHideWindows)
        end
        crippleTable.active[bj_crippledTimer[id]]   = nil
    end
    function internal.cripplePlayerTeamDummy()
        local player                                        = GetEnumPlayer()
        local id                                            = GetPlayerId(player)
        bj_playerIsCrippled[id]                             = crippleTable.flag
        crippleTable.timerData[bj_crippledTimer[id]]        = crippleTable.timerData[bj_crippledTimer[id]] or 
                                                              player
        if crippleTable.flag then
            crippleTable.active[bj_crippledTimer[id]]       = false
            TimerStart(bj_crippledTimer[id], bj_MELEE_CRIPPLE_TIMEOUT, false, internal.crippleTeamCallback)

            if GetLocalPlayer() == player then
                TimerDialogDisplay(bj_crippledTimerWindows[id], true)
                DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                        MeleeGetCrippledWarningMessage(player))
            end
            return
        end
        crippleTable.active[bj_crippledTimer[id]]    = nil

        PauseTimer(bj_crippledTimer[id])
        if GetLocalPlayer() ~= player then
            return
        end
        if IsTimerDialogDisplayed(bj_crippledTimerWindows[id]) then
            TimerDialogDisplay(bj_crippledTimerWindows[id], false)
        end
        if (bj_playerIsExposed[id]) then
            DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                        GetLocalizedString("CRIPPLE_UNREVEALED"))
        else
            DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                        GetLocalizedString("CRIPPLE_UNCRIPPLED"))
        end
    end
    function internal.cripplePlayerTeam(player, cripple)
        local id    = GetPlayerId(player)
        if bj_playerIsCrippled[id] == cripple then
            --  Player's cripple state is the same as the flag.
            --  Ignore
            return
        end
        crippleTable.flag                                   = cripple
        bj_playerIsCrippled[id]                             = cripple

        if cripple then
            --  Map the active timer id of each
            crippleTable.timerData[bj_crippledTimer[id]]        = crippleTable.timerData[bj_crippledTimer[id]] or 
                                                                  player
            crippleTable.active[bj_crippledTimer[id]]           = true
            TimerStart(bj_crippledTimer[id], bj_MELEE_CRIPPLE_TIMEOUT, false, internal.crippleTeamCallback)
            if GetLocalPlayer() == player then
                TimerDialogDisplay(bj_crippledTimerWindows[id], true)
                DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                         MeleeGetCrippledWarningMessage(player))
            end
            ForForce(teams.allies[id], internal.cripplePlayerTeamDummy)
            return
        end
        player                                              = crippleTable.timerData[bj_crippledTimer[id]]
        id                                                  = GetPlayerId(player)
        crippleTable.active[bj_crippledTimer[id]]           = nil

        PauseTimer(bj_crippledTimer[id])
        if GetLocalPlayer() == player then
            TimerDialogDisplay(bj_crippledTimerWindows[id], false)
            if (bj_playerIsExposed[id]) then
                DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                            GetLocalizedString("CRIPPLE_UNREVEALED"))
            else
                DisplayTimedTextToPlayer(player, 0, 0, bj_MELEE_CRIPPLE_MSG_DURATION,
                                            GetLocalizedString("CRIPPLE_UNCRIPPLED"))
            end
        end
        ForForce(teams.allies[id], internal.cripplePlayerTeamDummy)
        internal.exposePlayerTeam(player, false)
    end

    --  Handle Defeat mechanics
    function internal.defeatPlayer(player, leftGame)
        local id                = GetPlayerId(player)
        local flag              = false
        if bj_meleeVictoried[id] then
            return
        elseif bj_meleeDefeated[id] then
            return
        end
        bj_meleeDefeated[id]    = true
        bj_playerIsCrippled[id] = false
        bj_playerIsExposed[id]  = false

        crippleTable.timerData[bj_crippledTimer[id]]    = nil
        crippleTable.active[bj_crippledTimer[id]]       = nil

        PauseTimer(bj_crippledTimer[id])
        DestroyTimer(bj_crippledTimer[id])
        ForForce(teams.enemies[id], function()
            local player2           = GetEnumPlayer()
            local jd                = GetPlayerId(player2)
            ForceRemovePlayer(teams.enemies[jd], player)
        end)
        ForForce(teams.allies[id], function()
            local player2           = GetEnumPlayer()
            local jd                = GetPlayerId(player2)
            ForceRemovePlayer(teams.allies[jd], player)
            if flag then
                crippleTable.active[bj_crippledTimer[id]]       = true
            end
        end)
        DestroyForce(teams.enemies[id])
        DestroyForce(teams.allies[id])
        teams.enemies[id]       = nil
        teams.allies[id]        = nil

        ForceRemovePlayer(teams.players, player)
        ForceAddPlayer(teams.loser, player)
        CachePlayerHeroData(player)
        RemovePlayerPreserveUnitsBJ(player, PLAYER_GAME_RESULT_DEFEAT, leftGame)
    end
    function internal.defeatPlayerTeam(player)
        local id                = GetPlayerId(player)
        --  Since this function is going to be called only a few times
        --  (at most 23 times), a closure is used instead.
        ForForce(teams.allies[id], function()
            local player2       = GetEnumPlayer()
            internal.defeatPlayer(player2, false)
        end)
        internal.defeatPlayer(player, false)
    end
    function internal.neutralizePlayer(player)
        local group = CreateGroup()
        GroupEnumUnitsOfPlayer(group, player, nil)
        ForGroup(group, MakeUnitsPassiveForPlayerEnum)
        DestroyGroup(group)
    end
    function internal.neutralizePlayerTeam(player)
        local id    = GetPlayerId(player)
        internal.neutralizePlayer(player)
        ForForce(teams.allies[id], function()
            internal.neutralizePlayer(GetEnumPlayer())
        end)
    end
    function internal.shareControl(player)
        local id    = GetPlayerId(player)
        ForForce(teams.allies[id], function()
            local player2   = GetEnumPlayer()
            SetPlayerAlliance(player, player2, ALLIANCE_SHARED_VISION, true)
            SetPlayerAlliance(player, player2, ALLIANCE_SHARED_CONTROL, true)
            SetPlayerAlliance(player2, player, ALLIANCE_SHARED_CONTROL, true)
            SetPlayerAlliance(player, player2, ALLIANCE_SHARED_ADVANCED_CONTROL, true)
        end)
    end

    function internal.checkTeamStatus(player)
        local teamCount     = internal.getStructureCount(false, player)
        local teamKeyCount  = internal.getKeyStructureCount(false, player)
        if (teamKeyCount > 0) then
            --  A town hall might have been reconstructed.
            internal.cripplePlayerTeam(player, false)
            return
        end
        if teamCount > 0 then
            internal.cripplePlayerTeam(player, true)
            return
        end
        internal.neutralizePlayerTeam(player)
        internal.defeatPlayerTeam(player)
        internal.checkVictors()
    end

    --  Update structure count
    function internal.removeStructure(unit, player, id)
        id  = id or GetPlayerId(player)
        GroupRemoveUnit(buildingGroup[id], unit)
        internal.checkTeamStatus(player)
    end
    function internal.addStructure(unit, player, id)
        id  = id or GetPlayerId(player)
        GroupAddUnit(buildingGroup[id], unit)
        internal.checkTeamStatus(player)
    end

    --  Unit Trigger callbacks
    function internal.registerDeath(player)
        if not triggers.death then
            triggers.death  = CreateTrigger()
            TriggerAddAction(triggers.death, function()
                local unit      = GetTriggerUnit()
                local player    = GetOwningPlayer(unit)
                local id        = GetPlayerId(player)
                if not IsUnitInGroup(unit, buildingGroup[id]) then
                    return
                end
                internal.removeStructure(unit, player, id)
            end)
        end
        TriggerRegisterPlayerUnitEvent(triggers.death, player, EVENT_PLAYER_UNIT_DEATH)
    end
    function internal.registerConstruct(player)
        if not triggers.construct then
            triggers.construct  = CreateTrigger()
            TriggerAddAction(triggers.construct, function()
                local unit      = GetConstructingStructure()
                local player    = GetOwningPlayer(unit)
                internal.addStructure(unit, player, id)
            end)
        end
        TriggerRegisterPlayerUnitEvent(triggers.construct, player, EVENT_PLAYER_UNIT_CONSTRUCT_START)
    end
    function internal.registerChangeOwner(player)
        if not triggers.ownership then
            triggers.ownership  = CreateTrigger()
            TriggerAddAction(triggers.ownership, function()
                local unit          = GetTriggerUnit()
                local player        = GetOwningPlayer(unit)
                local prevPlayer    = GetChangingUnitPrevOwner()
                local prevID        = GetPlayerId(prevPlayer)
                if not IsUnitInGroup(unit, buildingGroup[prevID]) then
                    return
                end
                internal.removeStructure(unit, prevPlayer, prevID)
                internal.addStructure(unit, player)
            end)
        end
        TriggerRegisterPlayerUnitEvent(triggers.ownership, player, EVENT_PLAYER_UNIT_CHANGE_OWNER)
    end

    --  Player trigger callbacks
    function internal.registerDefeat(player)
        if not triggers.defeat then
            triggers.defeat  = CreateTrigger()
            TriggerAddAction(triggers.defeat, function()
            end)
        end
    end
    function internal.registerLeave(player)
        if not triggers.leave then
            triggers.leave  = CreateTrigger()
            TriggerAddAction(triggers.leave, function()
                local player        = GetTriggerPlayer()
                local teamCount     = internal.getStructureCount(false, player)
                if teamCount > 0 then
                    internal.shareControl(player)
                    internal.defeatPlayer(player, true)
                    return
                end
                internal.defeatPlayerTeam(player)
                internal.checkVictors()
            end)
        end
        TriggerRegisterPlayerEvent(triggers.leave, player, EVENT_PLAYER_LEAVE)
    end
    function internal.registerAllianceChange(player)
        if not triggers.allyChange then
            triggers.allyChange  = CreateTrigger()
            TriggerAddAction(triggers.allyChange, function()
                local player        = GetTriggerPlayer()
                local id            = GetPlayerId(player)
                ForForce(teams.allies[id], function()
                    local player2   = GetEnumPlayer()
                    local jd        = GetPlayerId(player2)
                    if not IsPlayerAlly(player, player2) then
                        ForceAddPlayer(teams.enemies[id], player2)
                        ForceRemovePlayer(teams.allies[id], player2)
                    end
                end)
                ForForce(teams.enemies[id], function()
                    local player2   = GetEnumPlayer()
                    local jd        = GetPlayerId(player2)
                    if not IsPlayerEnemy(player, player2) then
                        ForceAddPlayer(teams.allies[id], player2)
                        ForceRemovePlayer(teams.enemies[id], player2)
                    end
                end)
            end)
        end
        TriggerRegisterPlayerAllianceChange(triggers.allyChange, player, ALLIANCE_PASSIVE)
    end
    function internal.registerAlliedVictory(player)
        if not triggers.allyVictory then
            triggers.allyVictory  = CreateTrigger()
            TriggerAddAction(triggers.allyVictory, function()
                DisableTrigger(triggers.allyVictory)
                EnableTrigger(triggers.allyVictory)
            end)
        end
    end

    --  Observer callbacks
    function internal.registerObserverLeave(player)
        if not triggers.observerLeave then
            triggers.observerLeave  = CreateTrigger()
            TriggerAddAction(triggers.observerLeave, function()
                RemovePlayerPreserveUnitsBJ(GetTriggerPlayer(), PLAYER_GAME_RESULT_NEUTRAL, false)
            end)
        end
        TriggerRegisterPlayerEvent(triggers.observerLeave, player, EVENT_PLAYER_LEAVE)
    end

    function internal.initTeams()
        teams.victor        = CreateForce()
        teams.loser         = CreateForce()
        teams.players       = CreateForce()
        for id = 0, bj_MAX_PLAYERS - 1 do
            local player    = Player(id)
            if GetPlayerSlotState(player) == PLAYER_SLOT_STATE_PLAYING then
                teams.allies[id]    = CreateForce()
                teams.enemies[id]   = CreateForce()
                buildingGroup[id]   = CreateGroup()
                ForceAddPlayer(teams.players, player)

            elseif IsPlayerObserver(player) then
                internal.registerObserverLeave(player)
            end
        end
    end
    function internal.enumPreplacedStructures()
        local rect      = GetWorldBounds()
        local grp       = CreateGroup()
        GroupEnumUnitsInRect(grp, rect, nil)
        ForGroup(grp, function()
            local unit      = GetEnumUnit()
            local player    = GetOwningPlayer(unit)
            local id        = GetPlayerId(player)
            if not IsUnitType(unit, UNIT_TYPE_STRUCTURE) then
                return
            elseif id >= bj_MAX_PLAYERS then
                return
            end
            --  Bypass checking directly
            GroupAddUnit(buildingGroup[id], unit)
        end)
        ForForce(teams.players, function()
            internal.checkTeamStatus(GetEnumPlayer())
        end)
        DestroyGroup(grp)
        RemoveRect(rect)
    end

    function internal.initTriggers()
        local tempForce     = CreateForce()
        ForForce(teams.players, function()
            ForceAddPlayer(tempForce, GetEnumPlayer())
        end)
        ForForce(teams.players, function()
            local player    = GetEnumPlayer()
            local id        = GetPlayerId(player)
            ForForce(tempForce, function()
                local player2   = GetEnumPlayer()
                local jd        = GetPlayerId(player)
                if player == player2 then
                    return
                end
                if IsPlayerAlly(player2, player) then
                    ForceAddPlayer(teams.allies[id], player2)
                end
                if IsPlayerEnemy(player2, player) then
                    ForceAddPlayer(teams.enemies[id], player2)
                end
            end)
            internal.initGlobalVars(id, player)

            internal.registerDeath(player)
            internal.registerConstruct(player)
            internal.registerChangeOwner(player)

            --internal.registerDefeat(player)
            internal.registerLeave(player)
            internal.registerAllianceChange(player)
            internal.registerAlliedVictory(player)
        end)
        DestroyForce(tempForce)

        internal.enumPreplacedStructures()
        TimerStart(CreateTimer(), 2.00, false, function()
            DestroyTimer(GetExpiredTimer())
            ForForce(teams.players, function()
                internal.checkTeamStatus(GetEnumPlayer())
            end)
        end)
    end

    -- MeleeInitVictoryDefeat
    function CustomRaceConditions.init()
        internal.initTeams()
        internal.initTriggers()
    end
end