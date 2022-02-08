library BezierCurve requires Table, Alloc, Init

function GetWeightedValue takes real a, real b, real t returns real
    return a*(1.0 - t) + b*t
endfunction

struct PascalTriangle extends array
    readonly static integer array value

    private static method populate takes integer size, integer base returns nothing
        local integer i         = 1
        local integer j         = base - size
        set value[base]         = 1
        set value[base + size]  = 1
        //  Recursive definition
        if (value[j] == 0) then
            call thistype.populate(size - 1, j)
        endif
        loop
            exitwhen (i >= size)
            set value[base + i] = value[j + i - 1] + value[j + i]
            set i               = i + 1
        endloop
    endmethod

    static method getBaseIndex takes integer index returns integer
        local integer i = (index + 1)*(index) / 2
        if (value[i] == 0) then
            call thistype.populate(index, i)
        endif
        return i
    endmethod

    static method operator [] takes integer index returns integer
        return thistype.getBaseIndex(index)
    endmethod

    private static method init takes nothing returns nothing
        //  Initialize depth.
        //  Base 0
        set value[0]    = 1
        //  Base 1
        set value[1]    = 1
        set value[2]    = 1
        //  Base 2
        set value[3]    = 1
        set value[4]    = 2
        set value[5]    = 1
        //  Base 3
        set value[6]    = 1
        set value[7]    = 3
        set value[8]    = 3
        set value[9]    = 1
        //  Base 4
        set value[10]   = 1
        set value[11]   = 4
        set value[12]   = 6
        set value[13]   = 4
        set value[14]   = 1
    endmethod
    implement Init
endstruct

struct BezierCurve extends array
    implement Alloc

    private  static TableArray curveCoords                  = 0
    private  static constant integer INSTANCE_GAP           = 182

    readonly static constant integer OBJECT_TYPE_TEMPLATE   = 1
    readonly static constant integer OBJECT_TYPE_OBJECT     = 2
    private  integer    lastIndex
    private  thistype   base
    readonly integer    size
    readonly integer    objectType

    method operator [] takes integer index returns thistype
        set this.lastIndex  = INSTANCE_GAP*integer(this) + IMaxBJ(IMinBJ(index, this.size - 1), 0)
        return this
    endmethod

    method operator x takes nothing returns real
        return curveCoords[0].real[this.lastIndex]
    endmethod
    method operator y takes nothing returns real
        return curveCoords[1].real[this.lastIndex]
    endmethod
    method operator z takes nothing returns real
        return curveCoords[2].real[this.lastIndex]
    endmethod

    method operator x= takes real value returns nothing
        set curveCoords[0].real[this.lastIndex]     = value
    endmethod
    method operator y= takes real value returns nothing
        set curveCoords[1].real[this.lastIndex]     = value
    endmethod
    method operator z= takes real value returns nothing
        set curveCoords[2].real[this.lastIndex]     = value
    endmethod

    //  Should be used for template purposes
    static method create takes integer size returns thistype
        local thistype this                         = thistype.allocate()
        set this.objectType                         = OBJECT_TYPE_TEMPLATE
        set this.size                               = IMaxBJ(size + 1, 2)
        //  For optimization purposes
        set this.lastIndex                          = INSTANCE_GAP*integer(this)
        set this.x                                  = 0.0
        set this.y                                  = 0.0
        set this.z                                  = 0.0
        //  For optimization purposes
        set this.lastIndex                          = this.lastIndex + this.size - 1
        set this.x                                  = 1.0
        set this.y                                  = 1.0
        set this.z                                  = 1.0
        return this
    endmethod

    method destroy takes nothing returns nothing
        local integer  i                            = 0
        if (this.objectType == OBJECT_TYPE_TEMPLATE) or /*
        */ (this.size == 0) then
            return
        endif
        set this.lastIndex                          = INSTANCE_GAP*integer(this)
        loop
            exitwhen i >= (this.size)
            call curveCoords[0].real.remove(this.lastIndex)
            call curveCoords[1].real.remove(this.lastIndex)
            call curveCoords[2].real.remove(this.lastIndex)
            set i                                   = i + 1
            set this.lastIndex                      = this.lastIndex + 1
        endloop
        set this.lastIndex                          = 0
        set this.size                               = 0
        set this.base                               = 0
        set this.objectType                         = 0
        call this.deallocate()
    endmethod

    //! textmacro BEZIER_CURVE_GET_VALUE takes FUNCNAME, OPERATOR, FUNCDNAME
    private method p$FUNCNAME$ takes real t, real w returns real
        local integer i         = 1
        local integer index     = PascalTriangle[this.size - 1]
        local real value        = 0.0
        local real base         = 1.0 
        local real factor       = t / w
        loop
            exitwhen (i >= this.size)
            set base            = base*w
            set i               = i + 1
        endloop
        set i                   = 0
        loop
            exitwhen (i >= this.size)
            set value           = value + PascalTriangle.value[index]*base*this[i].$OPERATOR$
            set base            = base*factor
            set this.lastIndex  = this.lastIndex + 1
            set index           = index + 1
            set i               = i + 1
        endloop
        return value
    endmethod

    method $FUNCNAME$ takes real t returns real
        local real w            = (1.0 - t)
        if (t == 1.0) or (RAbsBJ(t / w) >= 1000.0) then
            return this[this.size - 1].$OPERATOR$
        //  Prevent a division by 0 first, then check if it's really close to 1 by dividing t by (1 - t).
        elseif (t == 0.0) then
            return this[0].$OPERATOR$
        endif
        if (this.size == 2) then
            return GetWeightedValue(this[0].$OPERATOR$, this[1].$OPERATOR$, t)
        elseif (this.size == 3) then
            return this[0].$OPERATOR$*w*w + 2.0*this[1].$OPERATOR$*w*t + this[2].$OPERATOR$*t*t
        elseif (this.size == 4) then
            return this[0].$OPERATOR$*w*w*w + 3.0*this[1].$OPERATOR$*w*w*t + 3.0*this[2].$OPERATOR$*w*t*t + this[3].$OPERATOR$*t*t*t
        endif
        return p$FUNCNAME$(t, w)
    endmethod

    method $FUNCDNAME$ takes real t1, real t0 returns real
        return this.$FUNCNAME$(t1) - this.$FUNCNAME$(t0)
    endmethod
    //! endtextmacro

    //! runtextmacro BEZIER_CURVE_GET_VALUE("getX", "x", "getDX")
    //! runtextmacro BEZIER_CURVE_GET_VALUE("getY", "y", "getDY")
    //! runtextmacro BEZIER_CURVE_GET_VALUE("getZ", "z", "getDZ")

    method adjustPos takes real cx, real cy, real cz, real tx, real ty, real tz returns nothing
        local integer  i                            = 0
        if (this.objectType != OBJECT_TYPE_OBJECT) then
            return
        endif
        set this.lastIndex                          = INSTANCE_GAP*integer(this)
        loop
            exitwhen i >= (this.size)
            set this.x                              = GetWeightedValue(cx, tx, this.base[i].x)
            set this.y                              = GetWeightedValue(cy, ty, this.base[i].y)
            set this.z                              = GetWeightedValue(cz, tz, this.base[i].z)
            set i                                   = i + 1
            set this.lastIndex                      = this.lastIndex + 1
        endloop
    endmethod
    static method createFromTemplate takes thistype base, real cx, real cy, real cz, real tx, real ty, real tz returns thistype
        local thistype this                         = 0
        local integer  i                            = 0
        if (base.objectType != OBJECT_TYPE_TEMPLATE) then
            return thistype(0)
        endif
        set this                                    = thistype.allocate()
        set this.base                               = base
        set this.objectType                         = OBJECT_TYPE_OBJECT
        set this.size                               = base.size
        call this.adjustPos(cx, cy, cz, tx, ty, tz)
        return this
    endmethod

    private static method init takes nothing returns nothing
        set curveCoords                             = TableArray[3]
    endmethod
    implement Init
endstruct

endlibrary