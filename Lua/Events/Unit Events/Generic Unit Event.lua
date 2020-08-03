do
    local m_reg         = protected_table()
    GenericUnitEvent    = setmetatable({}, m_reg)

    m_reg._MAX_SIZE     = 80
    m_reg._COLLECT      = 120
    m_reg._CUR_COLLECT  = 0
    m_reg._COLLECT_MIN  = 10
    m_reg._MAP          = {}
    m_reg._LIST         = LinkedList()

    local function is_unitevent(whichevent)
        return tostring(whichevent):sub(1,9) == 'unitevent'
    end
    local function new(whichevent)
        local o     = o or {}
        o.detector  = {}
        o.container = {}
        o.size      = {
            container   = {[0]=0},
            events      = {[0]=0},
            cur_index   = 0,
        }
        o.pointer   = {}
        o.listener  = EventListener:create()
        o.unitevent = whichevent
        setmetatable(o, m_reg)
        return o
    end
    local function prepare_trigger(self, i)
        self.detector[i]    = CreateTrigger()
        TriggerAddCondition(self.detector[i], Filter(function()
            self.listener:execute()
        end))
    end
    function m_reg:register_unit(whichunit)
        --  Filter out already-registered units
        if self.pointer[whichunit] then return;
        end

        --  Prepare the instance
        local index = self.size.cur_index
        if (index == 0) or (self.size.container[index] >= m_reg._MAX_SIZE) then
            index                       = index + 1
            self.size.cur_index         = index
            self.size.container[index]  = 0
            self.size.events[index]     = 0
            self.container[index]       = CreateGroup()
            prepare_trigger(self, index)
        end
        
        --  Use an O(n) algorithm search to determine the index for the
        --  unit
        local i = 1
        while i <= index do
            if self.size.container[i] < m_reg._MAX_SIZE then break;
            end
            i = i + 1
        end

        --  Index determined, register the unit
        GroupAddUnit(self.container[i], whichunit)
        TriggerRegisterUnitEvent(self.detector[i], whichunit, self.unitevent)

        self.pointer[whichunit] = i
        self.size.container[i]  = self.size.container[i] + 1
        self.size.events[i]     = self.size.events[i] + 1
    end
    function m_reg:deregister_unit(whichunit)
        --  Filter out deregistered units
        if not self.pointer[whichunit] then return;
        end

        --  Get the index containing the relevant group and
        --  number of registered unitevents
        local i = self.pointer[whichunit]
        GroupRemoveUnit(self.container[i], whichunit)
        self.size.events[i]     = self.size.events[i] - 1
        self.pointer[whichunit] = nil
    end

    local function clean_event(whichevent)
        local self  = m_reg._MAP[whichevent]
        local index = self.size.cur_index

        for i = 1, index do
            local delta = self.size.container[i] - self.size.events[i]

            --  If there are more than _COLLECT_MIN missing instances
            --  perform a collection
            if delta > m_reg._COLLECT_MIN then
                self.size.container[i]  = self.size.events[i]
                DestroyTrigger(self.detector[i])

                --  Iterate through each member, and re-register them
                --  to the trigger
                prepare_trigger(self, i)
                ForGroup(self.container[i], function()
                    TriggerRegisterUnitEvent(self.detector[i], GetEnumUnit(), self.unitevent)
                end)
            end
        end
    end
    local function register_all(whichevent)
        local t = m_reg._MAP[whichevent]
        for unit in UnitIterator() do
            t:register_unit(unit)
        end
    end

    UnitDex.register("ENTER_EVENT", function()
        local unit  = UnitDex.eventUnit
        for whichevent in m_reg._LIST:iterator() do
            m_reg._MAP[whichevent]:register_unit(unit)
        end
    end)
    UnitDex.register("LEAVE_EVENT", function()
        local unit          = UnitDex.eventUnit
        m_reg._CUR_COLLECT  = math.floor(math.fmod(m_reg._CUR_COLLECT + 1, m_reg._COLLECT))

        local reset         = (m_reg._CUR_COLLECT < 1)
        for whichevent in m_reg._LIST:iterator() do
            m_reg._MAP[whichevent]:deregister_unit(unit)
            if reset then
                clean_event(whichevent)
            end
        end
    end)
    function m_reg.register(whichevent, func)
        --  Filter out non-unitevents
        if not is_unitevent(whichevent) then return;
        end
        --  Create an instance if not already available
        if not m_reg._MAP[whichevent] then
            m_reg._MAP[whichevent]  = new(whichevent)
            m_reg._LIST:insert(whichevent)
            register_all(whichevent)
        end
        m_reg._MAP[whichevent].listener:register(func)
    end
    RegisterAnyUnitEvent    = m_reg.register
end