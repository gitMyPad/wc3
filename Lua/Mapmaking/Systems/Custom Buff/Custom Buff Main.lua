do
    local tb            = protected_table()
    _G['CustomBuff']    = {}
    CustomBuff.Main     = tb
    CustomBuff.Debug    = "ReplaceableTextures\\CommandButtons\\BTNHeroPaladin.blp"

    tb.WIDTH            = 0.22
    tb.HEIGHT           = 0.04

    tb.ABS_X            = 0
    tb.ABS_X            = tb.ABS_X - ((tb.ABS_X - 0.4)/0.4)*tb.WIDTH/2
    tb.ABS_Y            = 0.56

    tb.WIDTH_REMAIN     = tb.WIDTH

    Initializer("SYSTEM", function()
        local world     = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        tb.WORLD        = world
        tb.panel        = BlzCreateFrame("QuestButtonBaseTemplate", world, 0, 0)

        BlzFrameSetSize(tb.panel, tb.WIDTH, tb.HEIGHT)
        BlzFrameSetAbsPoint(tb.panel, FRAMEPOINT_CENTER, tb.ABS_X, tb.ABS_Y)
    end)

    function tb.visual_frame(whichframe)
        local world     = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
        local dframe    = BlzCreateFrame("QuestButtonBaseTemplate", world, 0, 0)
        BlzFrameClearAllPoints(dframe)
        BlzFrameSetAllPoints(dframe, whichframe)
        BlzFrameSetTexture(dframe, CustomBuff.Debug, 0, true)
    end
end