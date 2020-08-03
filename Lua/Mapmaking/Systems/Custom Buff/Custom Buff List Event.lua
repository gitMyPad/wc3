do
    local tb                = protected_table()
    local icons             = CustomBuff.ListIcons
    local l_player
    CustomBuff.ListEvent    = setmetatable({}, tb)

    tb._PRIMARY         = {}
    tb._STACK           = {}
    tb._BUTTON_POINT    = {}
    tb._BUTTON_POS      = {}

    function tb.get_primary_index(p)
        return tb._PRIMARY[GetPlayerId(p)]
    end
    function tb._update(p, id, i, count)
        tb._STACK[id][i]    = tb._STACK[id][i] + count
        local flag          = tb._STACK[id][i] > 0
        local self          = icons.get_frame(i)

        if l_player == p then
            BlzFrameSetVisible(self.tooltip.frame, flag)
        end
    end
    function tb._on_enter(p, id, self)
        if tb._PRIMARY[id] ~= 0 then return;
        end
        
        local i             = tb._BUTTON_POS[self.button]
        tb._update(p, id, i, 1)
    end
    function tb._on_leave(p, id, self)
        if tb._PRIMARY[id] ~= 0 then return;
        end
        
        local i             = tb._BUTTON_POS[self.button]
        tb._update(p, id, i, -1)
    end
    function tb._on_click(p, id, self)
        local i     = tb._BUTTON_POS[self.button]
        if tb._PRIMARY[id] == i then
            tb._PRIMARY[id]     = 0
            tb._update(p, id, i, 0)
            return
        end
        if tb._PRIMARY[id] ~= 0 then
            local j             = tb._PRIMARY[id]
            tb._update(p, id, j, -1)
        end        
        tb._PRIMARY[id]     = i

        self:show(false)
        self:show(true)
        self:activate(false)
        self:activate(true)
        self:unfocus()
        if tb._STACK[id][i] == 0 then
            tb._update(p, id, i, 1)
        end
    end
    function tb.deactivate_buff(p, i)
        local id = GetPlayerId(p)
        if tb._PRIMARY[id] ~= i then return;
        end

        tb._PRIMARY[id] = 0
        if tb._STACK[id][i] > 0 then
            tb._update(p, id, i, -1)
        else
            tb._update(p, id, i, 0)
        end
    end
    function tb._parse(p, self, event)
        local id = GetPlayerId(p)
        if event == FRAMEEVENT_MOUSE_ENTER then
            tb._on_enter(p, id, self, event)
        elseif event == FRAMEEVENT_MOUSE_LEAVE then
            tb._on_leave(p, id, self, event)
        elseif event == FRAMEEVENT_CONTROL_CLICK then
            tb._on_click(p, id, self, event)
        end
    end

    Initializer("SYSTEM", function()
        l_player    = GetLocalPlayer()

        local trig  = CreateTrigger()
        for id = 0, bj_MAX_PLAYER_SLOTS - 1 do
            local p         = Player(id)
            tb._PRIMARY[id] = 0
            tb._STACK[id]   = {}
            for i = 1, icons.ICON_MAX_COUNT do
                tb._STACK[id][i]    = 0
            end
        end
        for i = 1, icons.ICON_MAX_COUNT do
            local self                      = icons.get_frame(i)
            tb._BUTTON_POINT[self.button]   = self
            tb._BUTTON_POS[self.button]     = i
            BlzTriggerRegisterFrameEvent(trig, self.button, FRAMEEVENT_MOUSE_ENTER)
            BlzTriggerRegisterFrameEvent(trig, self.button, FRAMEEVENT_MOUSE_LEAVE)
            BlzTriggerRegisterFrameEvent(trig, self.button, FRAMEEVENT_CONTROL_CLICK)
        end
        TriggerAddCondition(trig, Condition(function()
            local p     = GetTriggerPlayer()
            local self  = tb._BUTTON_POINT[BlzGetTriggerFrame()]
            local event = BlzGetTriggerFrameEvent()

            tb._parse(p, self, event)
        end))
    end)
end