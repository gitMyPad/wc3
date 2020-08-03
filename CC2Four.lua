do
    local meta  =  {}
    function meta:__call(cc)
        if not meta[cc] then
            local str = ""
            local j   = 1
            while j <= 4 do
                local i = math.floor(math.fmod(cc, 256))
                str     = string.char(i) .. str
                cc      = math.floor(cc/256)
                j       = j + 1
            end
            meta[cc] = str
            return str
        end
        return meta[cc]
    end
    CC2Four = setmetatable({}, meta)
end