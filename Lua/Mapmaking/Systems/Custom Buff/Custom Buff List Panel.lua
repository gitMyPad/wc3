do
    local tb                = protected_table()
    local main              = CustomBuff.Main
    local status            = CustomBuff.Status
    CustomBuff.ListPanel    = setmetatable({}, tb)

    tb.WIDTH                = 0.10
    tb.HEIGHT               = 0.025

    tb.REL_X                = 0.01
    tb.REL_Y                = 0

    tb.HEIGHT               = math.min(tb.HEIGHT, main.HEIGHT)
    tb.WIDTH                = math.min(tb.WIDTH, main.WIDTH_REMAIN - tb.REL_X)
    main.WIDTH_REMAIN       = main.WIDTH_REMAIN - (tb.WIDTH + tb.REL_X)

    Initializer("SYSTEM", function()
        tb.panel    = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", main.panel, 0, 0)

        BlzFrameSetSize(tb.panel, tb.WIDTH, tb.HEIGHT)
        BlzFrameClearAllPoints(tb.panel)
        BlzFrameSetPoint(tb.panel, FRAMEPOINT_LEFT, status.status, FRAMEPOINT_RIGHT, tb.REL_X, tb.REL_Y)
    end)
end