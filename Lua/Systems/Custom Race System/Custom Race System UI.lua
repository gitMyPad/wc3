do
    --[[
        HEIGHT  -> with respect to y-axis
        WIDTH   -> with respect to x-axis
    ]]
    local tb                        = getmetatable(CustomRaceSystem)
    local internal                  = {}
    CustomRaceUI                    = setmetatable({}, tb)
    CustomRaceUI.toc                = "war3mapImported\\CustomRaceTOC.toc"

    function internal.loadTOC()
        if not BlzLoadTOCFile(CustomRaceUI.toc) then
            error("toc file was not loaded.")
        end
    end
    function internal.generateSmallClick()
        local snd   = CreateSound("Sound\\Interface\\MouseClick1.wav", false, false, false, 10, 10, "")
        SetSoundParamsFromLabel( gg_snd_MouseClick1, "InterfaceClick")
        SetSoundDuration(snd, 390)
        SetSoundVolume(snd, 127)
        return snd
    end
    function internal.generateBigClick()
        local snd   = CreateSound("Sound\\Interface\\BigButtonClick.wav", false, false,
                                  false, 10, 10, "" )
        SetSoundParamsFromLabel(snd, "MouseClick1")
        SetSoundDuration(snd, 239)
        SetSoundVolume(snd, 127)
        return snd
    end
    function internal.playSound(player, snd)
        if GetLocalPlayer() ~= player then
            SetSoundVolume(snd, 0)
        end
        StartSound(snd)
        KillSoundWhenDone(snd)
    end

    local config                    = {
        RACE_MAX_OPTIONS            = 4,

        MAIN_WIDTH                  = 0.50,
        MAIN_HEIGHT                 = 0.44,

        UPPER_BOX_HEIGHT            = 0.20,     -- Must be >= DESC_BOX_HEIGHT
        LOWER_BOX_HEIGHT            = 0.24,     -- Must be < MAIN_HEIGHT

        DESC_BOX_WIDTH              = 0.28,
        DESC_BOX_HEIGHT             = 0.14,
        ICON_BOX_WIDTH              = 0.16,
        ICON_BOX_HEIGHT             = 0.16,
        ICON_DISP_WIDTH             = 0.148,
        ICON_DISP_HEIGHT            = 0.148,
        RACE_TEXT_WIDTH             = 0.28,
        RACE_TEXT_HEIGHT            = 0.02,

        SELECTION_WIDTH             = 0.44,
        SELECTION_HEIGHT            = 0.18,
        SLIDER_WIDTH                = 0.01,
        CONFIRM_WIDTH               = 0.14,
        CONFIRM_HEIGHT              = 0.04,

        SELECTION_TEXT_WIDTH        = 0.24,
        SELECTION_TEXT_HEIGHT       = 0.02,

        margin                      = {
            UPPER_UPPER_MARGIN          = 0.02,
            UPPER_LOWER_MARGIN          = 0.02,
            UPPER_LEFT_MARGIN           = 0.02,
            UPPER_RIGHT_MARGIN          = 0.02,

            LOWER_UPPER_MARGIN          = 0.00,
            LOWER_LOWER_MARGIN          = 0.02,
            LOWER_LEFT_MARGIN           = 0.02,
            LOWER_RIGHT_MARGIN          = 0.02,

            RACE_LEFT_MARGIN            = 0.005,
            
            SELECTION_LOWER_MARGIN      = 0.04,

            SELECTION_TEXT_LEFT_MARGIN  = 0.02,
        },

        scale                       = {
            RACE_TEXT               = 1.35,
            SELECTION_TEXT          = 1.25,
        }
    }
    do
        config.UPPER_BOX_WIDTH      = config.MAIN_WIDTH
        config.LOWER_BOX_WIDTH      = config.MAIN_WIDTH
        config.SLIDER_HEIGHT        = config.SELECTION_HEIGHT
    end

    function internal.prepareAllFrames()
        local world             = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        CustomRaceUI.main       = BlzCreateFrame("EscMenuBackdrop", world, 0, 0)
        BlzFrameSetSize(CustomRaceUI.main, config.MAIN_WIDTH, config.MAIN_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.main)
        BlzFrameSetAbsPoint(CustomRaceUI.main, FRAMEPOINT_TOP, 
                            0.4, 0.80 - config.MAIN_HEIGHT/2)

        CustomRaceUI.descMain   = BlzCreateFrame("BattleNetTextAreaTemplate", CustomRaceUI.main, 0, 0)
        BlzFrameSetSize(CustomRaceUI.descMain, config.DESC_BOX_WIDTH, config.DESC_BOX_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.descMain)
        BlzFrameSetPoint(CustomRaceUI.descMain, FRAMEPOINT_TOPRIGHT,
                         CustomRaceUI.main, FRAMEPOINT_TOPRIGHT,
                         -config.margin.UPPER_RIGHT_MARGIN, -config.margin.UPPER_RIGHT_MARGIN*2)
        
        CustomRaceUI.iconMain   = BlzCreateFrame("QuestButtonBaseTemplate", CustomRaceUI.main, 0, 0)

        BlzFrameSetSize(CustomRaceUI.iconMain, config.ICON_BOX_WIDTH, config.ICON_BOX_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.iconMain)
        BlzFrameSetPoint(CustomRaceUI.iconMain, FRAMEPOINT_TOPLEFT,
                         CustomRaceUI.main, FRAMEPOINT_TOPLEFT, 
                         config.margin.UPPER_LEFT_MARGIN, -config.margin.UPPER_UPPER_MARGIN)

        CustomRaceUI.raceMain   = BlzCreateFrameByType("TEXT", "CustomRaceHeaderText",
                                                       CustomRaceUI.main, "", 0)
        BlzFrameSetSize(CustomRaceUI.raceMain, 
                        (config.RACE_TEXT_WIDTH-config.margin.RACE_LEFT_MARGIN)/config.scale.RACE_TEXT,
                        config.RACE_TEXT_HEIGHT/config.scale.RACE_TEXT)
        BlzFrameSetScale(CustomRaceUI.raceMain, config.scale.RACE_TEXT)
        BlzFrameSetTextAlignment(CustomRaceUI.raceMain, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        BlzFrameClearAllPoints(CustomRaceUI.raceMain)
        BlzFrameSetPoint(CustomRaceUI.raceMain, FRAMEPOINT_BOTTOMLEFT,
                         CustomRaceUI.descMain, FRAMEPOINT_TOPLEFT,
                         config.margin.RACE_LEFT_MARGIN, 0)

        CustomRaceUI.selectMain = BlzCreateFrame("QuestButtonBaseTemplate", CustomRaceUI.main, 0, 0)
        BlzFrameSetSize(CustomRaceUI.selectMain, config.SELECTION_WIDTH, config.SELECTION_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.selectMain)
        BlzFrameSetPoint(CustomRaceUI.selectMain, FRAMEPOINT_BOTTOMLEFT,
                         CustomRaceUI.main, FRAMEPOINT_BOTTOMLEFT,
                         config.margin.LOWER_LEFT_MARGIN,
                         config.margin.LOWER_LOWER_MARGIN + config.margin.SELECTION_LOWER_MARGIN)

        CustomRaceUI.sliderMain = BlzCreateFrameByType("SLIDER", "CustomRaceSlider",
                                                       CustomRaceUI.main, "QuestMainListScrollBar", 0)
        BlzFrameSetSize(CustomRaceUI.sliderMain, config.SLIDER_WIDTH, config.SLIDER_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.sliderMain)
        BlzFrameSetPoint(CustomRaceUI.sliderMain, FRAMEPOINT_LEFT,
                         CustomRaceUI.selectMain, FRAMEPOINT_RIGHT,
                         0.00, 0.00)

        CustomRaceUI.buttonFrame    = BlzCreateFrameByType("GLUETEXTBUTTON", "CustomRaceConfirmButton",
                                                           CustomRaceUI.main, "ScriptDialogButton", 0)
        BlzFrameSetSize(CustomRaceUI.buttonFrame, config.CONFIRM_WIDTH, config.CONFIRM_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.buttonFrame)
        BlzFrameSetPoint(CustomRaceUI.buttonFrame, FRAMEPOINT_BOTTOMRIGHT,
                         CustomRaceUI.main, FRAMEPOINT_BOTTOMRIGHT,
                         -config.margin.LOWER_RIGHT_MARGIN, config.margin.LOWER_LOWER_MARGIN)

        BlzFrameSetText(CustomRaceUI.buttonFrame, "Confirm Race")
    end
    function internal.prepareSubFrames()
        CustomRaceUI.icon       = BlzCreateFrameByType("BACKDROP", "", CustomRaceUI.iconMain, "", 0)
        BlzFrameSetSize(CustomRaceUI.icon, config.ICON_DISP_WIDTH, config.ICON_DISP_HEIGHT)
        BlzFrameClearAllPoints(CustomRaceUI.icon)
        BlzFrameSetPoint(CustomRaceUI.icon, FRAMEPOINT_CENTER,
                         CustomRaceUI.iconMain, FRAMEPOINT_CENTER,
                         0, 0)
        BlzFrameSetVisible(CustomRaceUI.icon, false)

        CustomRaceUI.selectList     = {}
        CustomRaceUI.framePosData   = {}
        CustomRaceUI.playerData     = {pointer={}}
        for i = 1, config.RACE_MAX_OPTIONS do
            local t     = {}
            t.main      = BlzCreateFrameByType("GLUETEXTBUTTON", "CustomRaceSelectOption",
                                               CustomRaceUI.selectMain, "EscMenuButtonTemplate",
                                               0)
            BlzFrameSetSize(t.main, config.SELECTION_WIDTH, 
                            config.SELECTION_HEIGHT/config.RACE_MAX_OPTIONS)
            if i ~= 1 then
                BlzFrameSetPoint(t.main, FRAMEPOINT_TOP,
                                 CustomRaceUI.selectList[i-1].main, FRAMEPOINT_BOTTOM,
                                 0, 0)
            else
                BlzFrameSetPoint(t.main, FRAMEPOINT_TOP,
                                 CustomRaceUI.selectMain, FRAMEPOINT_TOP,
                                 0, 0)
            end

            t.nameframe = BlzCreateFrameByType("TEXT", "", t.main, "", 0)
            BlzFrameSetEnable(t.nameframe, false)
            BlzFrameSetFocus(t.nameframe, false)
            BlzFrameSetSize(t.nameframe,
                            config.SELECTION_TEXT_WIDTH/config.scale.SELECTION_TEXT,
                            config.SELECTION_TEXT_HEIGHT/config.scale.SELECTION_TEXT)
            BlzFrameSetScale(t.nameframe, config.scale.SELECTION_TEXT)
            BlzFrameClearAllPoints(t.nameframe)
            BlzFrameSetPoint(t.nameframe, FRAMEPOINT_LEFT,
                             t.main, FRAMEPOINT_LEFT,
                             config.margin.SELECTION_TEXT_LEFT_MARGIN, 0)

            --  Debug text
            CustomRaceUI.selectList[i]          = t
            CustomRaceUI.framePosData[t.main]   = i
        end
    end
    function internal.addButtonAudioFeedback()
        local trig  = CreateTrigger()
        TriggerAddCondition(trig, Condition(function()
            local player        = GetTriggerPlayer()

            BlzFrameSetEnable(CustomRaceUI.buttonFrame, false)
            BlzFrameSetEnable(CustomRaceUI.buttonFrame, true)
            internal.playSound(GetTriggerPlayer(), internal.generateBigClick())

            local id            = CustomRaceUI.playerData.pointer[player]
            local data          = CustomRaceUI.playerData[id]
            if not data then
                return
            end
            if data.selectPos == 0 then
                return
            end
            --  Feed back the data
            CustomRace.faction[data.playerID]   = data.selectPos
            CustomRaceUI.display(player, false)
            CustomRaceUI.removeSelectingPlayer(player)
        end))
        BlzTriggerRegisterFrameEvent(trig, CustomRaceUI.buttonFrame, FRAMEEVENT_CONTROL_CLICK)

        local trig  = CreateTrigger()
        TriggerAddCondition(trig, Condition(function()
            local frame         = BlzGetTriggerFrame()
            local player        = GetTriggerPlayer()
            BlzFrameSetEnable(frame, false)
            BlzFrameSetEnable(frame, true)
            internal.playSound(player, internal.generateSmallClick())

            local id            = CustomRaceUI.playerData.pointer[player]
            local data          = CustomRaceUI.playerData[id]
            local pos           = CustomRaceUI.framePosData[frame]
            if not data then
                return
            end
            if data.selectPos ~= data.hoverOffset + pos then
                data.selectPos  = data.hoverOffset + pos
            else
                data.selectPos  = 0
            end
            CustomRaceUI.updateSelection(player, true)
        end))
        for i = 1, config.RACE_MAX_OPTIONS do
            BlzTriggerRegisterFrameEvent(trig, CustomRaceUI.selectList[i].main, FRAMEEVENT_CONTROL_CLICK)
        end
    end
    function internal.addSelectionProcess()
        local trig  = {CreateTrigger(), CreateTrigger()}
        TriggerAddCondition(trig[1], Condition(function()
            local frame     = BlzGetTriggerFrame()
            local player    = GetTriggerPlayer()
            local id        = CustomRaceUI.playerData.pointer[player]
            local data      = CustomRaceUI.playerData[id]
            local pos       = CustomRaceUI.framePosData[frame]
            if (not data) then
                return
            end
            --  When a frame is selected, the info will
            --  be locked to displaying the details of
            --  said frame.
            if data.selectPos   ~= 0 then
                return
            end
            if data.hoverPos - data.hoverOffset ~= pos then
                data.hoverPos   = data.hoverOffset + pos
                CustomRaceUI.updateSelection(player, false)
            end
        end))
        TriggerAddCondition(trig[2], Condition(function()
            local frame     = BlzGetTriggerFrame()
            local player    = GetTriggerPlayer()
            local id        = CustomRaceUI.playerData.pointer[player]
            local data      = CustomRaceUI.playerData[id]
            local pos       = CustomRaceUI.framePosData[frame]
            if (not data) or
               (GetLocalPlayer() ~= player) then
                return
            end
            if data.selectPos   ~= 0 then
                return
            end
            if data.hoverPos - data.hoverOffset == pos then
                data.hoverPos   = 0
                CustomRaceUI.updateSelection(player, false)
            end
        end))
        for i = 1, config.RACE_MAX_OPTIONS do
            BlzTriggerRegisterFrameEvent(trig[1], CustomRaceUI.selectList[i].main, FRAMEEVENT_MOUSE_ENTER)
            BlzTriggerRegisterFrameEvent(trig[2], CustomRaceUI.selectList[i].main, FRAMEEVENT_MOUSE_LEAVE)
        end
    end
    function internal.addScrollCallback()
        local trig  = {CreateTrigger(), CreateTrigger()}
        --  This trigger is for taking note of changed values
        TriggerAddCondition(trig[1], Condition(function()
            local player        = GetTriggerPlayer()
            local id            = CustomRaceUI.playerData.pointer[player]
            local data          = CustomRaceUI.playerData[id]
            local value         = (BlzGetTriggerFrameValue() + 0.5)//1
            if (not data) then
                return
            end
            data.hoverPos       = data.hoverPos - data.hoverOffset
            data.hoverOffset    = data.hoverMax - value
            data.hoverPos       = data.hoverPos + data.hoverOffset
            if data.selectPos ~= 0 then
                return
            end
            CustomRaceUI.updateHoverList(player)
            CustomRaceUI.updateSelection(player, false)
        end))
        TriggerAddCondition(trig[2], Condition(function()
            local player    = GetTriggerPlayer()
            local value     = BlzGetTriggerFrameValue()
            local incr      = 0
            if value > 0 then
                incr        = 1
            else
                incr        = -1
            end
            if GetLocalPlayer() == player then
                BlzFrameSetValue(CustomRaceUI.sliderMain, BlzFrameGetValue(CustomRaceUI.sliderMain) + incr)
            end
        end))
        BlzTriggerRegisterFrameEvent(trig[1], CustomRaceUI.sliderMain, FRAMEEVENT_SLIDER_VALUE_CHANGED)
        BlzTriggerRegisterFrameEvent(trig[2], CustomRaceUI.sliderMain, FRAMEEVENT_MOUSE_WHEEL)
    end

    function CustomRaceUI.updateSelection(player, useSelectedFrame)
        local id        = CustomRaceUI.playerData.pointer[player]
        if not id then
            return
        end
        local data      = CustomRaceUI.playerData[id]
        local factionID
        if useSelectedFrame then
            factionID   = (data.selectPos ~= 0 and data.selectPos) or data.hoverPos
        else
            factionID   = data.hoverPos
        end
        --  If factionID is 0, the user didn't select any race.
        if factionID == 0 then
            if GetLocalPlayer() == player then
                BlzFrameSetText(CustomRaceUI.descMain, "")
                BlzFrameSetText(CustomRaceUI.raceMain, "")
                BlzFrameSetTexture(CustomRaceUI.icon, "", 0, true)
                if BlzFrameIsVisible(CustomRaceUI.icon) then
                    BlzFrameSetVisible(CustomRaceUI.icon, false)
                end
            end
        else
            local faction       = tb._container[data.playerRace][factionID]
            local texture       = faction.racePic or "ReplaceableTextures\\CommandButtons\\BTNTemp.blp"
            if GetLocalPlayer() == player then
                BlzFrameSetText(CustomRaceUI.descMain, faction.description or "")
                BlzFrameSetText(CustomRaceUI.raceMain, "|cffffcc00" .. (faction.name or "") .. "|r")
                BlzFrameSetTexture(CustomRaceUI.icon, texture, 0, true)
                if texture == "" then
                    if BlzFrameIsVisible(CustomRaceUI.icon) then
                        BlzFrameSetVisible(CustomRaceUI.icon, false)
                    end
                else
                    if not BlzFrameIsVisible(CustomRaceUI.icon) then
                        BlzFrameSetVisible(CustomRaceUI.icon, true)
                    end
                end
            end
        end
    end
    function CustomRaceUI.updateHoverList(player)
        local id        = CustomRaceUI.playerData.pointer[player]
        if not id then
            return
        end
        local data      = CustomRaceUI.playerData[id]
        local j         = 1
        for i = 1, config.RACE_MAX_OPTIONS do
            if i + data.hoverOffset > data.factionChoices then
                break
            end
            local t         = CustomRaceUI.selectList[i]
            j               = j + 1
            local faction   = tb._container[data.playerRace][i + data.hoverOffset]
            if GetLocalPlayer() == player then
                if not BlzFrameIsVisible(t.main) then
                    BlzFrameSetVisible(t.main, true)
                end
                BlzFrameSetText(t.nameframe, "|cffffcc00" .. (faction.name or "") .. "|r")
            end
        end
        if j > config.RACE_MAX_OPTIONS then
            return
        end
        while j <= config.RACE_MAX_OPTIONS do
            local t         = CustomRaceUI.selectList[j]
            if GetLocalPlayer() == player then
                BlzFrameSetText(t.nameframe, "")
                if BlzFrameIsVisible(t.main) then
                    BlzFrameSetVisible(t.main, false)
                end
            end
            j = j + 1
        end
    end
    function CustomRaceUI.defSliderBounds(player)
        local id        = CustomRaceUI.playerData.pointer[player]
        if not id then
            return
        end
        local data      = CustomRaceUI.playerData[id]
        local j         = 1
        if data.factionChoices <= config.RACE_MAX_OPTIONS then
            if GetLocalPlayer() == player then
                BlzFrameSetVisible(CustomRaceUI.sliderMain, false)
            end
        else
            if GetLocalPlayer() == player then
                BlzFrameSetMinMaxValue(CustomRaceUI.sliderMain, 0, data.hoverMax)
                BlzFrameSetStepSize(CustomRaceUI.sliderMain, 1)
                BlzFrameSetValue(CustomRaceUI.sliderMain, data.hoverMax)
            end
        end
    end

    function CustomRaceUI.removeSelectingPlayer(player)
        local pos       = 1
        while pos <= #CustomRaceUI.playerSelectData do
            if CustomRaceUI.playerSelectData[pos] == player then
                break
            end
            pos = pos + 1
        end
        if pos > #CustomRaceUI.playerSelectData then
            return
        end
        table.remove(CustomRaceUI.playerSelectData, pos)
        CustomRaceUI.selectionCount = CustomRaceUI.selectionCount - 1
        if CustomRaceUI.selectionCount <= 0 then
            CustomRaceUI.clearSelectionTrigger()
            CustomRace.start()
        end
    end
    function CustomRaceUI.clearSelectionTrigger()
        if not CustomRaceUI.playerSelectTrig then
            return
        end
        DisableTrigger(CustomRaceUI.playerSelectTrig)
        DestroyTrigger(CustomRaceUI.playerSelectTrig)
        CustomRaceUI.playerSelectTrig   = nil
    end
    function CustomRaceUI.checkFactionSelection()
        if CustomRaceUI.selectionCount <= 0 then
            CustomRaceUI.display(GetLocalPlayer(), false)
            CustomRace.start()
            return
        end

        local trig                      = CreateTrigger()
        CustomRaceUI.playerSelectData   = {}
        CustomRaceUI.playerSelectTrig   = trig
        TriggerAddCondition(trig, Condition(function()
            local player    = GetTriggerPlayer()
            CustomRaceUI.removeSelectingPlayer(player)
        end))
        for i = 1, #CustomRaceUI.playerData do
            local player    = CustomRaceUI.playerData[i].player
            if GetPlayerController(player) == MAP_CONTROL_USER then
                table.insert(CustomRaceUI.playerSelectData, player)
                
                CustomRaceUI.updateHoverList(player)
                CustomRaceUI.updateSelection(player, false)
                TriggerRegisterPlayerEvent(trig, player, EVENT_PLAYER_LEAVE)
            end
        end
    end
    function CustomRaceUI.processPlayer(player)
        local id    = CustomRaceUI.playerData.pointer[player]
        local data  = CustomRaceUI.playerData[id]
        if not data then
            return
        end
        if GetPlayerController(player) == MAP_CONTROL_USER then
            --  Computer Players will always select default race.
            CustomRaceUI.selectionCount = CustomRaceUI.selectionCount + 1
        end
    end
    function CustomRaceUI.feedPlayerData(id, player)
        local race  = GetPlayerRace(player)
        if #tb._container[race] <= 1 then
            CustomRace.faction[id]  = 1
            return
        end
        local data  = {
            player          = player,
            playerID        = id,
            playerRace      = GetPlayerRace(player),
            factionChoices  = 0,
            hoverOffset     = 0,
            hoverPos        = 0,
            selectPos       = 0,
        }
        data.factionChoices = #tb._container[data.playerRace]
        data.hoverMax       = math.max(data.factionChoices - config.RACE_MAX_OPTIONS, 0)
        CustomRaceUI.playerData[#CustomRaceUI.playerData + 1]   = data
        CustomRaceUI.playerData.pointer[player]                 = #CustomRaceUI.playerData
        CustomRaceUI.defSliderBounds(player)
    end
    function CustomRaceUI.display(player, flag)
        if GetLocalPlayer() == player then
            BlzFrameSetVisible(CustomRaceUI.main, flag)
        end
    end
    function CustomRaceUI.init()
        internal.loadTOC()
        internal.prepareAllFrames()
        internal.prepareSubFrames()
        internal.addButtonAudioFeedback()
        internal.addSelectionProcess()
        internal.addScrollCallback()

        CustomRaceUI.selectionCount     = 0
    end
end