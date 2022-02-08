library Vector2 requires VolatileStruct

struct Vector extends array
    readonly real x
    readonly real y

    private static constant method RECYCLE_INTERVAL takes nothing returns real
        return 10.0
    endmethod

    private static constant method RECYCLE_INSTANCES takes nothing returns integer
        return 200
    endmethod

    private method onCleanup takes nothing returns nothing
        set this.x          = 0.0
        set this.y          = 0.0
    endmethod

    static method create takes real x, real y returns Vector
        local Vector this   = Vector.allocate()
        set this.x          = x
        set this.y          = y
        return this
    endmethod

    method operator inv takes nothing returns Vector
        return Vector.create(-this.x, -this.y)
    endmethod
    
    method operator magnitude takes nothing returns real
        return SquareRoot(this.x*this.x + this.y*this.y)
    endmethod

    method operator angle takes nothing returns real
        return Atan2(this.y, this.x)
    endmethod

    method add takes Vector v2 returns Vector
        return Vector.create(this.x + v2.x, this.y + v2.y)
    endmethod

    method sub takes Vector v2 returns Vector
        return Vector.create(this.x - v2.x, this.y - v2.y)
    endmethod

    method dot takes Vector v2 returns real
        return this.x*v2.x + this.y*v2.y
    endmethod

    method mult takes Vector v2 returns Vector
        return Vector.create(this.x*v2.x - this.y*v2.y, this.y*v2.x + this.x*v2.y)
    endmethod

    method div takes Vector v2 returns Vector
        local real scalar   = 1.0 / (v2.x*v2.x + v2.y*v2.y)
        return Vector.create((this.x*v2.x + this.y*v2.y) * scalar, (this.y*v2.x - this.x*v2.y) * scalar)
    endmethod

    implement VStruct
endstruct

endlibrary