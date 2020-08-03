do
    local tb            = protected_table()
    local main          = CustomBuff.Main
    CustomBuff.Status   = setmetatable({}, tb)

    tb.WIDTH            = 0.032
    tb.HEIGHT           = main.HEIGHT
    tb.SCALE            = 1.25

    tb.REL_X            = 0.01
    tb.REL_Y            = 0

    tb.WIDTH            = math.min(tb.WIDTH, main.WIDTH_REMAIN/tb.SCALE - tb.REL_X)
    main.WIDTH_REMAIN   = main.WIDTH_REMAIN - (tb.WIDTH*tb.SCALE + tb.REL_X)
    
    Initializer("SYSTEM", function()
        tb.status       = BlzCreateFrame("TeamLabelTextTemplate", main.panel, 0, 0)

        BlzFrameSetSize(tb.status, tb.WIDTH, tb.HEIGHT)
        BlzFrameClearAllPoints(tb.status)
        BlzFrameSetAllPoints(copy, tb.status)

        BlzFrameSetPoint(tb.status, FRAMEPOINT_LEFT, main.panel, FRAMEPOINT_LEFT, tb.REL_X, tb.REL_Y)
        
        BlzFrameSetText(tb.status, "Buffs:")
        BlzFrameSetScale(tb.status, tb.SCALE)
    end)
end