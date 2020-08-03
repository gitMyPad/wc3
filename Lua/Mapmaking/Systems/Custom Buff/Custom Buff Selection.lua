do
    local tb                = protected_table()
    local main              = CustomBuff.Main
    CustomBuff.Selection    = setmetatable({}, tb)

    tb.ICON_UP_PATH         = "Ui\\Custom\\DropdownArrowUp.blp"
    tb.ICON_DOWN_PATH       = "Ui\\Custom\\DropdownArrowDown.blp"

    tb.HEIGHT               = 0.02
    tb.WIDTH                = 0.04

    tb.REL_X                = 0.002
    tb.REL_Y                = 0

    tb.HEIGHT               = math.min(tb.HEIGHT, main.HEIGHT)
    tb.WIDTH                = math.min(tb.WIDTH, main.WIDTH_REMAIN - tb.REL_X)
    main.WIDTH_REMAIN       = main.WIDTH_REMAIN - (tb.WIDTH + tb.REL_X)

    tb.DISP_OFFSET          = 0.015
    tb.DISP_HEIGHT          = tb.HEIGHT
    tb.DISP_WIDTH           = tb.WIDTH - tb.DISP_OFFSET
    tb.DISP_SCALE           = 1.25

    function tb._create_framework()
        tb.disp_frame   = BlzCreateFrameByType("TEXT", "CustomBuffTextDisplay", main.panel, "", 0)
        tb.click_frame  = BlzCreateFrameByType("BACKDROP", "CustomBuffSelectionFrame", main.panel, "", 0)

        BlzFrameSetSize(tb.disp_frame, tb.DISP_WIDTH, tb.DISP_HEIGHT)
        BlzFrameSetSize(tb.click_frame, tb.DISP_OFFSET, tb.DISP_HEIGHT)

        BlzFrameClearAllPoints(tb.disp_frame)
        BlzFrameClearAllPoints(tb.click_frame)

        BlzFrameSetPoint(tb.disp_frame, FRAMEPOINT_LEFT, CustomBuff.ListPanel.panel, FRAMEPOINT_RIGHT, tb.REL_X, tb.REL_Y)
        BlzFrameSetPoint(tb.click_frame, FRAMEPOINT_LEFT, tb.disp_frame, FRAMEPOINT_RIGHT, 0, 0)
        BlzFrameSetScale(tb.disp_frame, tb.DISP_SCALE)

        BlzFrameSetTextAlignment(tb.disp_frame, TEXT_JUSTIFY_CENTER, TEST_JUSTIFY_LEFT)
        BlzFrameSetText(tb.disp_frame, "0/0")
        BlzFrameSetAlpha(tb.click_frame, 0)
    end
    function tb._create_buttons()
        tb.top_disp     = BlzCreateFrameByType("BACKDROP", "CustomBuffDropDownIconUp", tb.disp_frame, "", 0)
        tb.bot_disp     = BlzCreateFrameByType("BACKDROP", "CustomBuffDropDownIconDown", tb.disp_frame, "", 0)
        tb.top_button   = BlzCreateFrameByType("BUTTON", "CustomBuffDropDownButtonUp", tb.top_disp, "ScoreScreenTabButtonTemplate", 0)
        tb.bot_button   = BlzCreateFrameByType("BUTTON", "CustomBuffDropDownButtonDown", tb.bot_disp, "ScoreScreenTabButtonTemplate", 0)

        BlzFrameSetSize(tb.top_disp, tb.DISP_OFFSET, tb.DISP_HEIGHT/2)
        BlzFrameSetSize(tb.bot_disp, tb.DISP_OFFSET, tb.DISP_HEIGHT/2)

        BlzFrameClearAllPoints(tb.top_disp)
        BlzFrameClearAllPoints(tb.bot_disp)

        BlzFrameSetPoint(tb.top_disp, FRAMEPOINT_TOP, tb.click_frame, FRAMEPOINT_TOP, 0, 0)
        BlzFrameSetPoint(tb.bot_disp, FRAMEPOINT_TOP, tb.top_disp, FRAMEPOINT_BOTTOM, 0, 0)
        BlzFrameSetAllPoints(tb.top_button, tb.top_disp)
        BlzFrameSetAllPoints(tb.bot_button, tb.bot_disp)

        BlzFrameSetTexture(tb.top_disp, tb.ICON_UP_PATH, 0, true)
        BlzFrameSetTexture(tb.bot_disp, tb.ICON_DOWN_PATH, 0, true)
    end

    Initializer("SYSTEM", function()
        tb._create_framework()
        tb._create_buttons()
    end)
end