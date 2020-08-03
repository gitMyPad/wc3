do
    local tb        = getmetatable(CustomMelee)
    local races     = {
        RACE_HUMAN,
        RACE_ORC,
        RACE_UNDEAD,
        RACE_NIGHTELF,
        RACE_DEMON,
        RACE_OTHER
    }
    tb.dialog           = {}
    tb._faction         = {}
    tb.active_players   = {
        force           = CreateForce(),
        count           = 0,
    }

    function tb.dialog.add_player(whichplayer)
        ForceAddPlayer(tb.active_players.force, whichplayer)
    end
    function tb.dialog.remove_player(whichplayer)
        ForceRemovePlayer(tb.active_players.force, whichplayer)
    end
    function tb.dialog.create_race(player, race, index)
        local indexStartLoc = GetStartLocationLoc(GetPlayerStartLocation(player))
        local self          = tb._race[race][index]
        tb._faction[GetPlayerId(player)]    = self
        self.setup(player, indexStartLoc, true, true, true)
        RemoveLocation(indexStartLoc)
    end
    function tb.dialog.show()
        local pause_status  = 0
        ForForce(tb.active_players.force, function()
            pause_status    = pause_status + 1
        end)
        if pause_status > 0 then
            tb.dialog.pause_state   = true
            doAfter(0.00, function()
                SuspendTimeOfDay(true)
                ForForce(tb.active_players.force, function()
                    local p         = GetEnumPlayer()
                    local race      = GetPlayerRace(p)
                    doAfter(0.00, DialogDisplay, p, tb.dialog[race].main, true)
                end)
                for unit in UnitIterator() do
                    PauseUnit(unit, true)
                end
            end)
        end
    end
    function tb.active_players.enum_players()
        tb.active_players.count    = tb.active_players.count + 1
    end
    function tb.dialog.check_unpause_all()
        if not tb.dialog.pause_state then return;
        end

        local pause_status
        
        tb.active_players.count = 0
        ForForce(tb.active_players.force, tb.active_players.enum_players)
        pause_status    = tb.active_players.count
        
        if pause_status == 0 then
            DestroyForce(tb.active_players.force)
            SuspendTimeOfDay(false)
            tb.active_players.force = nil
            tb.dialog.pause_state   = nil
            for unit in UnitIterator() do
                PauseUnit(unit, false)
            end
        end
    end

    UnitDex.register("ENTER_EVENT", function()
        local unit  = UnitDex.eventUnit
        if tb.dialog.pause_state then
            PauseUnit(unit, true)
        end
    end)
    Initializer("SYSTEM", function()
        local trig  = CreateTrigger()
        for i = 1, #races do
            tb.dialog[races[i]] = {main = DialogCreate(), button={}}
            TriggerRegisterDialogEvent(trig, tb.dialog[races[i]].main)
        end
        doAfter(0.00, function()
            for i = 1, #races do
                local main = tb.dialog[races[i]].main
                DialogSetMessage(main, "Select your faction:")
                for j = 1, #tb._race[races[i] ] do
                    local self  = tb._race[races[i] ][j]
                    tb.dialog[races[i] ].button[j]   = DialogAddButton(main, self.name, j - 1)
                end
            end
        end)
        TriggerAddCondition(trig, Condition(function()
            local main      = GetClickedDialog()
            local button    = GetClickedButton()
            local player    = GetTriggerPlayer()
            local race      = GetPlayerRace(player)
            DialogDisplay(player, main, false)
            tb.dialog.remove_player(player)

            local i         = 0
            while i < #tb.dialog[race].button do
                if button == tb.dialog[race].button[i + 1] then
                    i = i + 1
                    break
                end
                i = i + 1
            end
            tb.dialog.create_race(player, race, i)
            tb.dialog.check_unpause_all()
        end))
    end)
end