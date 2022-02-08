library BezierEasing /* 1.0.0
*************************************************************************************
*
*   Build Cubic Bezier-based Easing functions
*
*   Instead of solving for the point on the cubic bezier curve, BezierEasing
*   solves for output Y where X is the input.
*
*   Useful for adjusting animation rate smoothness
*
*************************************************************************************
*
*   struct BezierEasing extends array
*
*       static method create takes real ax, real ay, real bx, real by returns thistype
*       - points (ax, ay) and (bx, by) are cubic bezier control points on 2D plane.
*       - cx = cubic(0, ax, bx, 1)
*       - cy = cubic(0, ay, by, 1)
*       method operator [] takes real t returns real
*       - real "t" is the given time progression whose value in [0..1] range
*
*************************************************************************************/
globals
    /*
    *   Adjust precision of epsilon's value
    *   higher precision = lower performance
    *
    *   May cause infinite loop if the
    *   precision is too high.
    */
    private constant real EPSILON = 0.00001
endglobals

private function Abs takes real a returns real
    if(a < 0) then
        return -a
    endif
    return a
endfunction

private function Max takes real a, real b returns real
    if(a < b) then
        return b
    endif
    return a
endfunction

/*
*   Float Equality Approximation
*   Accuracy is influenced by EPSILON's value
*/
private function Equals  takes real a, real b returns boolean
    return Abs(a - b) <= EPSILON*Max(1., Max(Abs(a), Abs(b)))
endfunction

private function Bezier3 takes real a, real b, real c, real d, real t returns real
    local real x = 1. - t
    return x*x*x*a + 3*x*x*t*b + 3*x*t*t*c + t*t*t*d
endfunction

private module Init
    private static method onInit takes nothing returns nothing
        call init()
    endmethod
endmodule

struct BezierEasing extends array
    private static thistype array r
    
    private real x1
    private real y1
    private real x2
    private real y2
    
    static method create takes real ax, real ay, real bx, real by returns thistype
        local thistype this = r[0]
        if(r[this] == 0) then
            set r[0] = this + 1
        else
            set r[0] = r[this]
        endif
        set r[this] = -1
        
        set x1 = ax
        set y1 = ay
        set x2 = bx
        set y2 = by
        return this
    endmethod
    
    method operator [] takes real t returns real
        /*
        *   Perform binary search for the equivalent points on curve
        *   by using the t factor of cubic beziers, where the input
        *   is equal to the bezier point's x, and the output is the
        *   point's y, respectively.
        */
        local real lo = 0.
        local real hi = 1.
        local real mid
        local real tx
        local real ty
        
        local real ax = x1
        local real ay = y1
        local real bx = x2
        local real by = y2
        
        /*
        *   Since bezier points lies within
        *   the [0, 1] bracket, just return
        *   the bound values.
        */
        if(Equals(t, 0.)) or (t < 0.) then
            return 0.
        elseif(Equals(t, 1.)) or (t > 1.) then
            return 1.
        endif
        
        /*
        *   Binary Search
        */
        loop
            set mid = (lo + hi)*0.5
            set tx = Bezier3(0, ax, bx, 1, mid)
            set ty = Bezier3(0, ay, by, 1, mid)
            
            if(Equals(t, tx))then
                return ty
            elseif(t < tx) then
                set hi = mid
            else
                set lo = mid
            endif
        endloop
        return 0.
    endmethod
    
    method destroy takes nothing returns nothing
        if(r[this] == -1) then
            set r[this] = r[0]
            set r[0] = this
            
            set x1 = 0.
            set y1 = 0.
            set x2 = 0.
            set y2 = 0.
        endif
    endmethod
    
    private static method init takes nothing returns nothing
        set r[0] = 1
    endmethod
    implement Init
endstruct

struct BezierEase extends array
    readonly static BezierEasing inQuad
    readonly static BezierEasing outQuad
    readonly static BezierEasing inOutQuad
    readonly static BezierEasing inCubic
    readonly static BezierEasing outCubic
    readonly static BezierEasing inOutCubic
    readonly static BezierEasing inQuart
    readonly static BezierEasing outQuart
    readonly static BezierEasing inOutQuart
    readonly static BezierEasing inQuint
    readonly static BezierEasing outQuint
    readonly static BezierEasing inOutQuint
    readonly static BezierEasing inSine
    readonly static BezierEasing outSine
    readonly static BezierEasing inOutSine
    readonly static BezierEasing inBack
    readonly static BezierEasing outBack
    readonly static BezierEasing inOutBack
    readonly static BezierEasing inCirc
    readonly static BezierEasing outCirc
    readonly static BezierEasing inOutCirc
    readonly static BezierEasing inExpo
    readonly static BezierEasing outExpo
    readonly static BezierEasing inOutExpo
    readonly static BezierEasing linear
    
    private static method init takes nothing returns nothing
        set inSine = BezierEasing.create(0.47, 0, 0.745, 0.715)
        set outSine = BezierEasing.create(0.39, 0.575, 0.565, 1)
        set inOutSine = BezierEasing.create(0.445, 0.05, 0.55, 0.95)
        set inQuad = BezierEasing.create(0.55, 0.085, 0.68, 0.53)
        set outQuad = BezierEasing.create(0.25, 0.46, 0.45, 0.94)
        set inOutQuad = BezierEasing.create(0.455, 0.03, 0.515, 0.955)
        set inCubic = BezierEasing.create(0.55, 0.055, 0.675, 0.19)
        set outCubic = BezierEasing.create(0.215, 0.61, 0.355, 1)
        set inOutCubic = BezierEasing.create(0.645, 0.045, 0.355, 1)
        set inQuart = BezierEasing.create(0.895, 0.03, 0.685, 0.22)
        set outQuart = BezierEasing.create(0.165, 0.84, 0.44, 1)
        set inOutQuart = BezierEasing.create(0.77, 0, 0.175, 1)
        set inQuint = BezierEasing.create(0.755, 0.05, 0.855, 0.06)
        set outQuint = BezierEasing.create(0.23, 1, 0.32, 1)
        set inOutQuint = BezierEasing.create(0.86, 0, 0.07, 1)
        set inExpo = BezierEasing.create(0.95, 0.05, 0.795, 0.035)
        set outExpo = BezierEasing.create(0.19, 1, 0.22, 1)
        set inOutExpo = BezierEasing.create(1, 0, 0, 1)
        set inCirc = BezierEasing.create(0.6, 0.04, 0.98, 0.335)
        set outCirc = BezierEasing.create(0.075, 0.82, 0.165, 1)
        set inOutCirc = BezierEasing.create(0.785, 0.135, 0.15, 0.86)
        set inBack = BezierEasing.create(0.6, -0.28, 0.735, 0.045)
        set outBack = BezierEasing.create(0.175, 0.885, 0.32, 1.275)
        set inOutBack = BezierEasing.create(0.68, -0.55, 0.265, 1.55)
        set linear = BezierEasing.create(0.0, 0.0, 1.0, 1.0)
    endmethod
    
    implement Init
endstruct

endlibrary