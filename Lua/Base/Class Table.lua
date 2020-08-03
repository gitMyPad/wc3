do
    local m_class       = {}
    local table_class   = {}
    local flags         = {
        READONLY        = 1,
        PROTECTED       = 2,
    }
    m_class.__index     = m_class
    m_class.__newindex  = function() end
    ClassTable          = setmetatable({}, m_class)
    
    function m_class.is_readonly(o)
        return table_class[o] == flags.READONLY
    end
    function m_class.is_protected(o)
        return table_class[o] == flags.PROTECTED
    end

    function readonly_table(o)
        o               = o or {}
        o.__index       = o
        o.__newindex    = function(t, k, v)
            if o[k] then return
            end
            rawset(t, k, v)
        end
        table_class[o]  = flags.READONLY
        return o
    end
    function protected_table(o)
        o               = o or {}
        o.__index       = function(t, k)
            if tostring(k):sub(1,1) == '_' then return;
            end
            return o[k]
        end
        o.__newindex    = function() end
        table_class[o]  = flags.PROTECTED
        return o
    end
end