--[[
--  Originally made by Almia, this was ported over to LUA.
--  Link to the JASS library: https://www.hiveworkshop.com/threads/beziereasing.310514/
]]
do
    local m_bez         = {
        _EPSILON        = 0.00001
    }
    BezierEasing        = setmetatable({}, m_bez)
    m_bez.__metatable   = BezierEasing
    m_bez.__newindex    = function() end

    local function Max(a, b)
        return math.max(a, b)
    end
    
    --[[
    /*
    *   Float Equality Approximation
    *   Accuracy is influenced by EPSILON's value
    */
    ]]
    local function Equals(a,b)
        return math.abs(a - b) <= m_bez._EPSILON*math.max(1., math.max(math.abs(a), math.abs(b)))
    end
    local function Bezier3(a, b, c, d, t)
        local x = 1 - t
        return x*x*x*a + 3*x*x*t*b + 3*x*t*t*c + t*t*t*d
    end
  
    function m_bez.create(ax, ay, bx, by)
        local o = o or setmetatable({x1 = ax or 0, x2 = bx or 0, y1 = ay or 0, y2 = by or 0}, m_bez)
        return o
    end
    function m_bez.__index(t, k)
        if type(k) == 'number' then
            --[[
            *   Perform binary search for the equivalent points on curve
            *   by using the t factor of cubic beziers, where the input
            *   is equal to the bezier point's x, and the output is the
            *   point's y, respectively.
            ]]
            local lo, hi    = 0., 1.
            --[[
            *   Since bezier points lies within
            *   the [0, 1] bracket, just return
            *   the bound values.
            ]]
            if k < 0 then
                return 0
            elseif k > 1 then
                return 1
            end
            if (Equals(k, 0.)) then
                return 0.
            elseif (Equals(k, 1.)) then
                return 1.
            end
          
            --[[
            *   Binary Search
            ]]

            while true do
                local mid = (lo + hi)*0.5
                local tx = Bezier3(0, t.x1, t.x2, 1, mid)
                local ty = Bezier3(0, t.y1, t.y2, 1, mid)
              
                if (Equals(k, tx)) then return ty;
                elseif (k < tx) then hi = mid;
                else lo = mid;
                end
            end
            return 0.
        end
        return m_bez[k]
    end
    function m_bez:destroy()
        self.x1, self.y1, self.x2, self.y2 = nil
        setmetatable(self, nil)
    end

    BezierEase = {
        inSine      = m_bez.create(0.47, 0, 0.745, 0.715),
        outSine     = m_bez.create(0.39, 0.575, 0.565, 1),
        inOutSine   = m_bez.create(0.445, 0.05, 0.55, 0.95),
        inQuad      = m_bez.create(0.55, 0.085, 0.68, 0.53),
        outQuad     = m_bez.create(0.25, 0.46, 0.45, 0.94),
        inOutQuad   = m_bez.create(0.455, 0.03, 0.515, 0.955),
        inCubic     = m_bez.create(0.55, 0.055, 0.675, 0.19),
        outCubic    = m_bez.create(0.215, 0.61, 0.355, 1),
        inOutCubic  = m_bez.create(0.645, 0.045, 0.355, 1),
        inQuart     = m_bez.create(0.895, 0.03, 0.685, 0.22),
        outQuart    = m_bez.create(0.165, 0.84, 0.44, 1),
        inOutQuart  = m_bez.create(0.77, 0, 0.175, 1),
        inQuint     = m_bez.create(0.755, 0.05, 0.855, 0.06),
        outQuint    = m_bez.create(0.23, 1, 0.32, 1),
        inOutQuint  = m_bez.create(0.86, 0, 0.07, 1),
        inExpo      = m_bez.create(0.95, 0.05, 0.795, 0.035),
        outExpo     = m_bez.create(0.19, 1, 0.22, 1),
        inOutExpo   = m_bez.create(1, 0, 0, 1),
        inCirc      = m_bez.create(0.6, 0.04, 0.98, 0.335),
        outCirc     = m_bez.create(0.075, 0.82, 0.165, 1),
        inOutCirc   = m_bez.create(0.785, 0.135, 0.15, 0.86),
        inBack      = m_bez.create(0.6, -0.28, 0.735, 0.045),
        outBack     = m_bez.create(0.175, 0.885, 0.32, 1.275),
        inOutBack   = m_bez.create(0.68, -0.55, 0.265, 1.55),

        easeInOut   = m_bez.create(0.4, 0, 0.6, 1),
        linear      = m_bez.create(0, 0, 1, 1),
    }
end