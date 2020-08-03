do
    local m_cache       = {}
    m_cache.__newindex  = function() end
    m_cache._results    = {}
    m_cache._interval   = {}
    m_cache._list       = {}

    function m_cache:__index(k)
        if type(k) == 'number' then return m_cache._results[self][k];
        end
        if tostring(k):sub(1,1) == '_' then return nil;
        end
        return m_cache[k]
    end
    function m_cache:next(i)
        if m_cache._list[self][i] then return m_cache._list[self][i];
        end
        return -1
    end
    function math.cache(a, b, interval, func)
        interval                = interval or 1
        local i                 = 1
        local tb                = setmetatable({}, m_cache)
        m_cache._results[tb]    = {}
        m_cache._list[tb]       = {}
        m_cache._interval[tb]   = interval
        while a < b do
            m_cache._results[tb][i] = func(a)
            m_cache._list[tb][i]    = i + 1
            a   = a + interval
            i   = i + 1
        end
        m_cache._list[tb][i - 1]    = 1
        return tb
    end
end