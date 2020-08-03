do
    local vect  = WeakObject(32)
    Vector2D    = setmetatable({}, vect)

    function vect:__constructor(x, y)
        self.x  = x or 0
        self.y  = y or 0
    end
    function vect:__destructor()
        self.x  = nil
        self.y  = nil
    end
    function vect:__len()
        return (self.x*self.x + self.y*self.y)^(1/2)
    end
    function vect:dot(other)
        return self.x*other.x + self.y*other.y
    end
    function vect:norm()
        local len   = #self
        return Vector2D(self.x/len, self.y/len)
    end
    function vect:__add(other)
        return Vector2D(self.x + other.x, self.y + other.y)
    end
    function vect:__sub(other)
        return Vector2D(self.x - other.x, self.y - other.y)
    end
    function vect:__mul(other)
        return self:dot(other)
    end
    function vect:coords()
        return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ")"
    end
    function vect:arg()
        return math.atan(self.y, self.x)
    end
    vect.ORIGIN = Vector2D(0, 0)
end