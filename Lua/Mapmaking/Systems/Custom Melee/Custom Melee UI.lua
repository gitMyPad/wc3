do
    local l_melee           = getmetatable(CustomMelee)
    local ui_display        = {TOC_PATH = "war3mapimported\\CustomText.toc",
                               MODEL    = "ReplaceableTextures\\CommandButtons\\BTNPeon.blp"}

    function l_melee.ui_initialization()
        local loaded_toc        = BlzLoadTOCFile(ui_display.TOC_PATH)
        ui_display.main         = BlzCreateFrame("QuestButtonBaseTemplate", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 1, 1)
        ui_display.main_text    = BlzCreateFrameByType("TEXT", "", ui_display.main, "CustomText" , 0)
        ui_display.main_model   = BlzCreateFrameByType("BACKDROP", "UI Model", ui_display.main, "", 0)

        BlzFrameSetParent(ui_display.main, nil)
        BlzFrameSetSize(ui_display.main, 0.20, 0.1875)

        BlzFrameClearAllPoints(ui_display.main)
        BlzFrameSetAbsPoint(ui_display.main, FRAMEPOINT_CENTER, 0.4, 0.3)

        BlzFrameSetSize(ui_display.main_model, 0.14, 0.14)
        BlzFrameSetTexture(ui_display.main_model, ui_display.MODEL, 0, true)

        BlzFrameSetScale(ui_display.main_text, 1.35)
        BlzFrameSetText(ui_display.main_text, "Please wait for others...")

        BlzFrameSetPoint(ui_display.main_text, FRAMEPOINT_TOP, ui_display.main, FRAMEPOINT_TOP, 0, -0.00875)
        BlzFrameSetPoint(ui_display.main_model, FRAMEPOINT_TOP, ui_display.main_text, FRAMEPOINT_BOTTOM, 0, -0.0075)

        BlzFrameSetVisible(ui_display.main, false)
        BlzFrameSetVisible(ui_display.main_text, false)
        BlzFrameSetVisible(ui_display.main_model, false)
    end

    function l_melee.display_elements(flag)
        BlzFrameSetVisible(ui_display.main, flag)
        BlzFrameSetVisible(ui_display.main_text, flag)
        BlzFrameSetVisible(ui_display.main_model, flag)
    end

    function l_melee.remove_elements()
        BlzDestroyFrame(ui_display.main_model)
        BlzDestroyFrame(ui_display.main_text)
        BlzDestroyFrame(ui_display.main)
    end
end