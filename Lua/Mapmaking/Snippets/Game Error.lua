do
    local tb    = protected_table()
    tb._TICKS   = 32
    tb._DECAY   = 3
    tb._DUR     = 3
    tb._alpha   = {}
    GameError   = setmetatable({}, tb)

    tb._fade    = TimerIterator:create(tb._TICKS, function(i)
        tb._alpha[i]    = math.max(tb._alpha[i] - tb._RATE, 0)
        if GetLocalPlayer() == Player(i) then
            BlzFrameSetAlpha(tb._panel, math.floor(tb._alpha[i] + 0.5))
        end
        if tb._alpha[i] <= 0 then
            tb._fade:remove(i)
        end
    end)
    Initializer("SYSTEM", function()
        for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
            tb._alpha[i]    = 0
        end
    end)
    local function gen_error()
        local snd   = CreateSound("Sound\\Interface\\Error.wav", false, false, false, 10, 10, "")
        SetSoundParamsFromLabel(snd, "InterfaceError")
        SetSoundDuration(snd, 614)
        SetSoundVolume(snd, 127)
        return snd
    end
    local function sound_kill()
        local t     = GetExpiredTimer()
        local snd   = GetTimerData(t)
        StartSound(snd)
        KillSoundWhenDone(snd)
        DestroyTimer(t)
    end
    local function sound_play()
        local t     = GetExpiredTimer()
        local snd   = GetTimerData(t)
        StartSound(snd)
        DestroyTimer(t)
    end
    local function fade_panel()
        local t     = GetExpiredTimer()
        local i     = GetTimerData(t)
        tb._fade:insert(i)
        DestroyTimer(t)
    end

    function tb:__call(player, msg, snd, retain, decay)
        snd             = snd or gen_error()
        decay           = decay or tb._DECAY
        local i         = GetPlayerId(player)

        tb._alpha[i]    = 255
        if GetLocalPlayer() == player then
            BlzFrameSetAlpha(tb._panel, tb._alpha[i])
            BlzFrameSetText(tb._panel, tb._color .. msg .. "|r")
        end
        tb._fade:remove(i)

        local timer     = CreateTimer()
        local timer2    = CreateTimer()
        SetTimerData(timer, snd)
        SetTimerData(timer2, i)
        if not retain then
            TimerStart(timer, 0.00, false, sound_kill)
        else
            TimerStart(timer, 0.00, false, sound_play)
        end
        TimerStart(timer2, decay, false, fade_panel)
    end

    Initializer("SYSTEM", function()
        local world = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        tb._panel   = BlzCreateFrameByType("TEXT", "GameErrorText", world, "", 0)
        tb._color   = "|cffffda00"
        tb._RATE    = 255/tb._DUR/tb._TICKS

        BlzFrameSetParent(tb._panel, nil)
        BlzFrameSetSize(tb._panel, 0.36, 0.12)
        BlzFrameSetTextAlignment(tb._panel, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_CENTER)
        BlzFrameSetAlpha(tb._panel, 0)
        
        BlzFrameSetAbsPoint(tb._panel, FRAMEPOINT_CENTER, 0.4, 0.3 - 0.12/2 - 0.08)
        BlzFrameSetScale(tb._panel, 1.55)
        BlzFrameSetEnable(tb._panel, false)
    end)
end