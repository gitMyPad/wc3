library ObjectMovement requires /*

    -----------------------------------
    */  Table, Alloc, Init, ListT,   /*
    -----------------------------------

    --------------------------------------
    */  GTimer, UnitDex, BezierEasing   /*
    --------------------------------------

    -----------------------------------
    */  UnitPathCheck, BezierCurve   /*
    -----------------------------------

     ---------------------------------------------------------------------------
    |
    |   ObjectMovement
    |   - MyPad
    |
    |---------------------------------------------------------------------------
    |
    |   A library that facilitates triggered object movement
    |   without the strict coupling of one's position to
    |   its' in-game position. Since this system was designed
    |   for one thing, there isn't a lot of features that the
    |   current version (v.1.0.0.0) offers out of the box.
    |
    |---------------------------------------------------------------------------
    |
    |   API:
    |   
    |   class ObjectMovement {
    |   ========================================================================
    |        ---------------
    |       |   Methods:    |
    |        ---------------
    |       static method create(unit whichUnit, ObjectMovementResponse resp)
    |           - The ObjectMovementResponse instance will be explained below.
    |
    |       method destroy()
    |           - Destroys an instance.
    |           - If called while the instance was still moving, a
    |             STOP response will be triggered.
    |           - Fires a DESTROY response.
    |
    |       method setTargetArea(real x, y, z) -> ObjectMovement
    |       method setTargetAreaXY(real x, y) -> ObjectMovement
    |           - Sets the target area to the specified coordinates.
    |           - setTargetAreaXY internally calls setTargetAreaXYZ with 0.0
    |             as the third parameter.
    |           - If used while moving, the movement might become janky.
    |           - Returns itself for chained calls.
    |
    |       method setTargetUnitOffset(unit target, real offset)   -> ObjectMovement
    |           - Sets the target to the specified unit.
    |       method setTargetUnit(unit target)   -> ObjectMovement
    |           - Sets the target to the specified unit.
    |       method setTargetDest(destructable target)   -> ObjectMovement
    |           - Sets the target to the specified destructable.
    |       method setTargetItem(item target)   -> ObjectMovement
    |           - Sets the target to the specified item.
    |           - Returns itself for chained calls.
    |
    |       method launch() -> bool
    |           - Launches an instance if and only if
    |             both the velocity and the target type have
    |             been defined.
    |           - Returns true if it launches the instance,
    |             false otherwise.
    |           - Fires a RESUME response if instance was
    |             paused.
    |           - Otherwise fires a LAUNCH response.
    |
    |       method stop() -> bool
    |           - Stops an instance dead in its tracks.
    |           - If the ObjectMovementResponse reference the
    |             instance is based off of has ticked the
    |             FLAG_DESTROY_ON_STOP, then the instance is
    |             destroyed afterwards.
    |           - If FLAG_NO_TARGET_ON_STOP is ticked, the
    |             movement instance will behave as though
    |             it has never been launched when stopped.
    |           - Fires a STOP response.
    |
    |       method pause() -> bool
    |           - Stops the movement of an instance.
    |           - Fires a PAUSE instance.
    |
    |        ---------------
    |       |   Members:    |
    |        ---------------
    |           readonly static ObjectMovement  current
    |               - The current instance inside a response execution.
    |           readonly unit                   unit
    |               - The unit being moved.
    |           readonly item                   item
    |               - The item being moved.
    |           readonly effect                 effect
    |               - The generated special effect being moved.
    |           readonly integer                moveStatus
    |               - Holds numerous flags about the status of the movement instance.
    |           readonly integer                instanceFlags
    |               - Holds numerous flags about the behavior of the movement instance.
    |           readonly integer                targType
    |               - Holds numerous flags about the target type of the movement instance.
    |           readonly unit                   targUnit
    |           readonly item                   targItem
    |           readonly destructable           targDest
    |               - Should be self-explanatory (These are target objects).
    |
    |           integer                         data
    |               - Should be self-explanatory (This is user-specified data).
    |           BezierEasing                    easeMode
    |               - The Bezier curve which governs how the instance will move.
    |           real                            veloc
    |               - The speed of the Movement instance.
    |               - Must be defined by the user as a requirement for launching.
    |   ========================================================================
    |   }
    |
    |   Ideally, the ObjectMovementResponse object is generated once
    |   per class / struct, but if one wants to create it directly,
    |   the API is provided below.
    |
    |   WARNING: These objects cannot be destroyed as it is presumed
    |   that these are static.
    |
    |   class ObjectMovementResponse {
    |   ========================================================================
    |        ---------------
    |       |   Methods:    |
    |        ---------------
    |       static method create(code onLaunch, onMove, onPause, onResume, onStop, onDest) -> ObjectMovementResponse
    |           - Returns a unique ObjectMovementResponse object.
    |           - Note that the responses can still be altered after definition.
    |
    |        ---------------
    |       |   Members:    |
    |        ---------------
    |           integer flag
    |               - Dictates how a ObjectMovement instance will behave when
    |                 using this object as a response handler.
    |           readonly EventResponder launchResponse
    |           readonly EventResponder moveResponse
    |           readonly EventResponder pauseResponse
    |           readonly EventResponder resumeResponse
    |           readonly EventResponder stopResponse
    |           readonly EventResponder destroyResponse
    |               - Objects which execute a certain function depending
    |                 on the situation.
    |               - Can be made to call different functions using
    |                 <resp>.change(code callback)
    |   ========================================================================
    |   }
    |
    |   Now, if one doesn't want to worry about having to create the static
    |   object beforehand, populating its responses. they can just import
    |   the module below.
    |
    |   module ObjectMovementTemplate {
    |   ========================================================================
    |       interface static method onLaunch()
    |       interface static method onMove()
    |       interface static method onStop()
    |       interface static method onResume()
    |       interface static method onPause()
    |       interface static method onDest()
    |           - These methods can be optionally defined.
    |
    |       interface static method defineMissileCurve(BezierCurve curveBase)
    |           - An optional method for defining how the object will move.
    |
    |       interface static method MISSILE_CURVE_NODES() -> int
    |           - An optional method for defining how many control points the
    |             curve will have. MUST BE IMPLEMENTED alongside defineMissileCurve.
    |
    |       static method applyUnitMovement(unit whichUnit)
    |           - A shortcut for creating a ObjectMovement instance
    |             with its' responses associated with the parent
    |             class, and coupling the movement of the object
    |             to a unit.
    |
    |       static method applyMovement(real cx, real cy)
    |           - A shortcut for creating a ObjectMovement instance
    |             with its' responses associated with the parent
    |             class, and coupling the movement of the object
    |             to a generated effect.
    |
    |       static method applyItemMovement(item whichItem)
    |           - A shortcut for creating a ObjectMovement instance
    |             with its' responses associated with the parent
    |             class, and coupling the movement of the object
    |             to an item.
    |
    |        ---------------
    |       |   Members:    |
    |        ---------------
    |           - static ObjectMovementResponse resp
    |               - This is your generated ObjectMovementResponse object.
    |                 It is defined at map initialization.
    |
    |           - stub static integer FLAGSET
    |               - This is a generated method operator if not
    |                 specified directly beforehand.
    |               - Has an initial value of FLAG_NO_TARGET_ON_STOP + 
    |                 FLAG_DESTROY_ON_OBJECT_DEATH + FLAG_IGNORE_GROUND_PATHING
    |
    |           - stub static string MISSILE_MODEL
    |               - This is another generated method operator if
    |                 not specified directly beforehand.
    |               - Determines the model of the generated effect
    |                 associated with the class.
    |
    |   ========================================================================
    |   }
     ---------------------------------------------------------------------------
*/

//  ============================================================================
//  Ideally, we want to keep this as small as possible
//  while still allowing enough time to pass to lessen
//  the burden of distance recomputation.
private constant function TICKS_FOR_CALC_DISTANCE takes nothing returns integer
    return 8
endfunction

//  Not sure if doing it this way is less computationally expensive.
private function GetDistanceXY takes real x1, real y1, real x2, real y2 returns real
    set x1  = (x1 - x2)
    set y1  = (y1 - y2)
    return SquareRoot(x1*x1 + y1*y1)
endfunction

private function GetDistanceXYZ takes real x1, real y1, real z1, real x2, real y2, real z2 returns real
    set x1  = (x1 - x2)
    set y1  = (y1 - y2)
    set z1  = (z1 - z2)
    return SquareRoot(x1*x1 + y1*y1 + z1*z1)
endfunction

private function GetSquareDistanceXY takes real x1, real y1, real x2, real y2 returns real
    set x1  = (x1 - x2)
    set y1  = (y1 - y2)
    return (x1*x1 + y1*y1)
endfunction

private function GetSquareDistanceXYZ takes real x1, real y1, real z1, real x2, real y2, real z2 returns real
    set x1  = (x1 - x2)
    set y1  = (y1 - y2)
    set z1  = (z1 - z2)
    return (x1*x1 + y1*y1 + z1*z1)
endfunction

private function GetBezierGradient takes BezierEasing ease, real cur, real prev returns real
    return ease[cur] - ease[prev]
endfunction

//  ============================================================================
struct ObjectMovementResponse extends array
    implement Alloc

    readonly EventResponder launchResponse
    readonly EventResponder moveResponse
    readonly EventResponder pauseResponse
    readonly EventResponder resumeResponse
    readonly EventResponder stopResponse
    readonly EventResponder destroyResponse
    integer flag

    static method create takes code onLaunch, code onMove, code onPause, code onResume, code onStop, code onDest returns thistype
        local thistype this         = thistype.allocate()
        set this.launchResponse     = EventResponder.create(onLaunch)
        set this.moveResponse       = EventResponder.create(onMove)
        set this.pauseResponse      = EventResponder.create(onPause)
        set this.resumeResponse     = EventResponder.create(onResume)
        set this.stopResponse       = EventResponder.create(onStop)
        set this.destroyResponse    = EventResponder.create(onDest)
        return this
    endmethod
endstruct

//  ============================================================================
//! runtextmacro DEFINE_LIST("private", "MovementList", "integer")

struct ObjectCoords extends array
    real cx
    real cy
    real cz

    real tx
    real ty
    real tz
    real tzOff

    real ox
    real oy
    real oz

    real curBezierValue
    real curProgValue
    real bezierSkipValue
    real angle

    //  Since the allocation scheme is based on parent inheritance,
    //  this method is ubiquitous with cleanup instead.
    method destroy takes nothing returns nothing
        set this.cx                 = 0.0
        set this.cy                 = 0.0
        set this.cz                 = 0.0
        set this.tx                 = 0.0
        set this.ty                 = 0.0
        set this.tz                 = 0.0
        set this.ox                 = 0.0
        set this.oy                 = 0.0
        set this.oz                 = 0.0
        set this.tzOff              = 0.0
        set this.curBezierValue     = 0.0
        set this.curProgValue       = 0.0
        set this.bezierSkipValue    = 0.0
        set this.angle              = 0.0
    endmethod

    private static location zLoc    = null
    static method getZ takes real x, real y returns real
        call MoveLocation(zLoc, x, y)
        return GetLocationZ(zLoc)
    endmethod

    private static method init takes nothing returns nothing
        set zLoc                    = Location(0.0, 0.0)
    endmethod
    implement Init
endstruct

private struct ObjectMovementData extends array
    static EventResponder       movementResp          = 0
    static MovementList         moveList              = 0
    static MovementList array   instanceList

    static method addMovingInstance takes ObjectMovement instance returns MovementListItem
        local MovementListItem result   = moveList.push(instance).last
        //  Add unit in movingGroup
        if (moveList.size() == 1) then
            call GTimer[GAME_TICK].requestCallback(movementResp)
        endif
        return result
    endmethod
    static method removeMovingInstance takes MovementListItem ptr returns nothing
        call moveList.erase(ptr)
        if (moveList.empty()) then
            call GTimer[GAME_TICK].releaseCallback(movementResp)
        endif
    endmethod

    static method addUnitInstance takes unit whichUnit, ObjectMovement instance returns MovementListItem
        local integer id                = GetUnitId(whichUnit)
        local MovementListItem result   = 0
        if (instanceList[id] == 0) then
            set instanceList[id]        = MovementList.create()
        endif
        set result                      = instanceList[id].push(instance).last
        return result
    endmethod
    static method removeUnitInstance takes unit whichUnit, MovementListItem ptr returns nothing
        local integer id                = GetUnitId(whichUnit)
        if (instanceList[id] == 0) then
            return
        endif
        call instanceList[id].erase(ptr)
        if (instanceList[id].empty()) then
            call instanceList[id].destroy()
            set instanceList[id]    = 0
        endif
    endmethod
endstruct

//  ============================================================================
struct ObjectMovement extends array
    implement Alloc

    //  ==================================================
    private  static constant real       INTERVAL                        = 1.0 / I2R(GAME_TICK)
    private  static constant integer    STATUS_ALLOCATED                = 1
    private  static constant integer    STATUS_UNUSED                   = 2
    private  static constant integer    STATUS_MOVING                   = 4
    private  static constant integer    STATUS_PAUSED                   = 8
    private  static constant integer    STATUS_STOPPED                  = 16
    private  static constant integer    STATUS_BEING_REMOVED            = 32
    private  static constant integer    STATUS_READDED                  = 64

    private  static constant integer    TARGET_TYPE_STATIC              = 1
    private  static constant integer    TARGET_TYPE_MOVING              = 2
    private  static constant integer    TARGET_TYPE_UNIT                = 4
    private  static constant integer    TARGET_TYPE_DESTRUCTABLE        = 8
    private  static constant integer    TARGET_TYPE_ITEM                = 12
    private  static constant integer    TARGET_TYPE_MASK                = TARGET_TYPE_UNIT + TARGET_TYPE_DESTRUCTABLE

    readonly static constant integer    OBJECT_TYPE_UNIT                = 1
    readonly static constant integer    OBJECT_TYPE_ITEM                = 2
    readonly static constant integer    OBJECT_TYPE_EFFECT              = 4

    private  static constant integer    EVENT_LAUNCHED                  = 1
    private  static constant integer    EVENT_MOVING                    = 2
    private  static constant integer    EVENT_PAUSED                    = 4
    private  static constant integer    EVENT_RESUMED                   = 8
    private  static constant integer    EVENT_STOPPED                   = 16
    private  static constant integer    EVENT_DESTROYED                 = 32

    static   constant integer           FLAG_DESTROY_ON_STOP            = 1
    static   constant integer           FLAG_DESTROY_ON_TARGET_REMOVE   = 2
    static   constant integer           FLAG_DESTROY_ON_TARGET_DEATH    = 4
    static   constant integer           FLAG_DESTROY_ON_OBJECT_DEATH    = 8
    static   constant integer           FLAG_STOP_ON_UNIT_ROOT          = 16
    static   constant integer           FLAG_NO_TARGET_ON_STOP          = 32
    static   constant integer           FLAG_IGNORE_GROUND_PATHING      = 64

    private  static boolean             inCallback                      = false
    private  static integer             loopIterCount                   = 0
    readonly static thistype            current                         = 0
    readonly static BezierEasing        linear                          = 0
    readonly static BezierCurve         linearPath                      = 0
    readonly integer                    moveStatus
    readonly integer                    instanceFlags

    //  The object type to be moved.
    readonly integer                    objectType
    readonly unit                       unit
    readonly effect                     effect
    readonly destructable               destructable
    readonly item                       item

    readonly integer                    targType
    readonly unit                       targUnit
    readonly item                       targItem
    readonly destructable               targDest

    integer                             data
    BezierEasing                        easeMode
    BezierCurve                         curvePath

    private ObjectMovementResponse      respHandler
    private real                        pVeloc
    private MovementListItem            moveListPtr
    private MovementListItem            instanceListPtr
    private BezierCurve                 pMovementPath

    method operator coords takes nothing returns ObjectCoords
        return ObjectCoords(this)
    endmethod
    method operator veloc takes nothing returns real
        return this.pVeloc * GAME_TICK
    endmethod
    method operator veloc= takes real value returns nothing
        local real objDist              = 0.0
        set this.moveStatus             = BlzBitAnd(this.moveStatus, -STATUS_UNUSED - 1)
        set this.pVeloc                 = value / I2R(GAME_TICK)
        if (this.targType == 0) then
            return
        endif
        set objDist                     = GetDistanceXY(this.coords.cx, this.coords.cy, /*
                                                     */ this.coords.tx, this.coords.ty)
        set this.coords.bezierSkipValue = pVeloc / objDist
    endmethod
    //  ==================================================

    private method invokeCallback takes integer eventType returns nothing
        local thistype prev = current
        set current         = this
        if (eventType == EVENT_LAUNCHED) then
            call this.respHandler.launchResponse.run()
        elseif (eventType == EVENT_MOVING) then
            call this.respHandler.moveResponse.run()
        elseif (eventType == EVENT_PAUSED) then
            call this.respHandler.pauseResponse.run()
        elseif (eventType == EVENT_RESUMED) then
            call this.respHandler.resumeResponse.run()
        elseif (eventType == EVENT_STOPPED) then
            call this.respHandler.stopResponse.run()
        elseif (eventType == EVENT_DESTROYED) then
            call this.respHandler.destroyResponse.run()
        endif
        set current         = prev
    endmethod

    private method onLaunchPopData takes nothing returns nothing
        local real dist
        if (this.objectType == OBJECT_TYPE_UNIT) then
            set this.coords.cx                  = GetUnitX(this.unit)
            set this.coords.cy                  = GetUnitY(this.unit)
            set this.coords.cz                  = GetUnitFlyHeight(this.unit)
        elseif (this.objectType == OBJECT_TYPE_ITEM) then
            set this.coords.cx                  = GetItemX(this.item)
            set this.coords.cy                  = GetItemY(this.item)
            set this.coords.cz                  = 0.0
            set this.coords.tz                  = 0.0       //  It's senseless trying to move an item in the z-axis.
        else
            set this.coords.cx                  = BlzGetLocalSpecialEffectX(this.effect)
            set this.coords.cy                  = BlzGetLocalSpecialEffectY(this.effect)
            set this.coords.cz                  = BlzGetLocalSpecialEffectZ(this.effect)
        endif
        set dist                                = GetDistanceXY(this.coords.cx, this.coords.cy, /*
                                                             */ this.coords.tx, this.coords.ty)
        set this.coords.angle                   = Atan2(this.coords.ty - this.coords.cy, /*
                                                    */  this.coords.tx - this.coords.cx)
        set this.coords.curBezierValue          = 0.0
        set this.coords.curProgValue            = 0.0
        if (dist == 0.0) then
            set this.coords.bezierSkipValue     = 1.0
        else
            set this.coords.bezierSkipValue     = RMinBJ(this.pVeloc / dist, 1.0)
        endif
        if (this.pMovementPath == 0) then
            set this.pMovementPath              = BezierCurve.createFromTemplate(this.curvePath, /*
                                                                               */this.coords.cx, /*
                                                                               */this.coords.cy, /*
                                                                               */this.coords.cz, /*
                                                                               */this.coords.tx, /*
                                                                               */this.coords.ty, /*
                                                                               */this.coords.tz)
        else
            call this.pMovementPath.adjustPos(this.coords.cx, this.coords.cy, this.coords.cz, /*
                                            */this.coords.tx, this.coords.ty, this.coords.tz)
        endif
        set this.coords.ox                      = this.pMovementPath.getX(0.0)
        set this.coords.oy                      = this.pMovementPath.getY(0.0)
        set this.coords.oz                      = this.pMovementPath.getZ(0.0)
    endmethod

    method time2Veloc takes real time returns real
        //  Check if instance is already moving.
        local real dist = 0.0
        if (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) or /*
        */ (BlzBitAnd(this.moveStatus, STATUS_MOVING) == 0) then
            return 0.0
        endif
        set dist        = GetDistanceXY(this.coords.cx, this.coords.cy, /*
                                     */ this.coords.tx, this.coords.ty)
        if (time == 0.0) then
            return dist*1000.0*GAME_TICK
        endif
        return dist / RAbsBJ(time)
    endmethod

    method launch takes nothing returns boolean
        //  Check if instance is already moving.
        if (BlzBitAnd(this.moveStatus, STATUS_MOVING) != 0) or /*
        */ (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) then
            return false
        endif
        //  Check if missile is ready to launch.
        if (BlzBitAnd(this.moveStatus, STATUS_UNUSED) != 0) then
            // call BJDebugMsg("ObjectMovement.launch >> Movement instance is not ready to launch yet!")
            // call BJDebugMsg("ObjectMovement.launch >> Please define the instance's velocity.")
            return false
        endif
        if (this.targType == 0) then
            // call BJDebugMsg("ObjectMovement.launch >> Movement instance is not ready to launch yet!")
            // call BJDebugMsg("ObjectMovement.launch >> Please define the instance's target type.")
            return false
        endif
        //  Missile is ready to launch.
        set this.moveStatus                 = BlzBitOr(this.moveStatus, STATUS_MOVING)
        call this.onLaunchPopData()

        if (BlzBitAnd(this.moveStatus, STATUS_PAUSED) != 0) then
            call this.invokeCallback(EVENT_RESUMED)
        else
            call this.invokeCallback(EVENT_LAUNCHED)
        endif
        set this.moveStatus                 = BlzBitAnd(this.moveStatus, -(STATUS_STOPPED + STATUS_PAUSED) - 1)
        set this.moveListPtr                = ObjectMovementData.addMovingInstance(this)
        if (inCallback) then
            set this.moveStatus             = BlzBitOr(this.moveStatus, STATUS_READDED)
        endif
        return true
    endmethod

    method pause takes nothing returns boolean
        if (BlzBitAnd(this.moveStatus, STATUS_PAUSED) != 0) then
            return false
        endif
        set this.moveStatus     = BlzBitAnd(this.moveStatus, -STATUS_MOVING - 1)
        set this.moveStatus     = BlzBitOr(this.moveStatus, STATUS_PAUSED)
        call ObjectMovementData.removeMovingInstance(this.moveListPtr)
        set this.moveListPtr    = 0
        call this.invokeCallback(EVENT_PAUSED)
        return true
    endmethod

    method resume takes nothing returns boolean
        if (BlzBitAnd(this.moveStatus, STATUS_PAUSED) == 0) then
            return false
        endif
        return this.launch()
    endmethod

    method destroy takes nothing returns nothing
        if (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) then
            return
        endif
        set this.moveStatus = BlzBitAnd(this.moveStatus, -STATUS_ALLOCATED - 1)
        //  If the instance is moving, stop it
        if (BlzBitAnd(this.moveStatus, STATUS_MOVING) != 0) then
            call this.invokeCallback(EVENT_STOPPED)
            call ObjectMovementData.removeMovingInstance(this.moveListPtr)
            set this.moveListPtr        = 0
        endif
        if (BlzBitAnd(this.moveStatus, STATUS_BEING_REMOVED) == 0) then
            set this.moveStatus         = this.moveStatus + STATUS_BEING_REMOVED
            call this.invokeCallback(EVENT_DESTROYED)
            set this.moveStatus         = this.moveStatus - STATUS_BEING_REMOVED
        endif
        if (this.objectType == OBJECT_TYPE_EFFECT) then
            call DestroyEffect(this.effect)

        elseif (this.instanceListPtr != 0) then
            call ObjectMovementData.removeUnitInstance(this.unit, this.instanceListPtr)
            set this.instanceListPtr    = 0
        endif
        if (this.pMovementPath != 0) then
            call this.pMovementPath.destroy()
        endif
        call this.coords.destroy()
        set this.unit                   = null
        set this.item                   = null
        set this.effect                 = null
        set this.targItem               = null
        set this.targDest               = null
        set this.targUnit               = null
        set this.objectType             = 0
        set this.easeMode               = 0
        set this.curvePath              = 0
        set this.pMovementPath          = 0
        set this.moveStatus             = 0
        set this.targType               = 0
        set this.instanceFlags          = 0
        set this.pVeloc                 = 0.0
        set this.respHandler            = 0
        call this.deallocate()
    endmethod

    method stop takes nothing returns boolean
        if (BlzBitAnd(this.moveStatus, STATUS_STOPPED) != 0) or /*
        */ (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) then
            return false
        endif
        set this.moveStatus     = BlzBitAnd(this.moveStatus, -STATUS_MOVING - 1)
        set this.moveStatus     = BlzBitOr(this.moveStatus, STATUS_STOPPED)
        if (BlzBitAnd(this.instanceFlags, FLAG_NO_TARGET_ON_STOP + FLAG_DESTROY_ON_STOP) != 0) then
            set this.moveStatus = BlzBitOr(this.moveStatus, STATUS_UNUSED)
            set this.targType   = 0
            set this.targUnit   = null
            set this.targDest   = null
            set this.targItem   = null
            set this.pVeloc     = 0.0
            set this.targType   = 0
        endif
        call ObjectMovementData.removeMovingInstance(this.moveListPtr)
        set this.moveListPtr    = 0
        call this.invokeCallback(EVENT_STOPPED)
        if ((BlzBitAnd(this.instanceFlags, FLAG_DESTROY_ON_STOP) != 0) and /*
        */  (BlzBitAnd(this.moveStatus, STATUS_UNUSED) != 0)) then
            call this.destroy()
        endif
        return true
    endmethod

    method setTargetArea takes real x, real y, real z returns thistype
        set this.targType       = TARGET_TYPE_STATIC
        set this.coords.tx      = x
        set this.coords.ty      = y
        set this.coords.tz      = z
        set this.targUnit       = null
        set this.targDest       = null
        set this.targItem       = null
        if (BlzBitAnd(this.objectType, OBJECT_TYPE_EFFECT) != 0) then
            set this.coords.tz  = this.coords.tz + ObjectCoords.getZ(x, y)
        endif
        //  Whenever target is repointed while missile isn't moving, force a recalculation.
        //  Hopefully, this doesn't need to be done too often.
        if (BlzBitAnd(this.moveStatus, STATUS_MOVING) == 0) then
            return this
        endif
        call this.onLaunchPopData()
        return this
    endmethod
    method setTargetAreaXY takes real x, real y returns thistype
        return this.setTargetArea(x, y, 0.0 + GetUnitFlyHeight(this.unit))
    endmethod
    method setTargetUnitOffset takes unit target, real offset returns thistype
        set this.targType       = TARGET_TYPE_MOVING + TARGET_TYPE_UNIT
        set this.targUnit       = target
        set this.targDest       = null
        set this.targItem       = null
        set this.coords.tx      = GetUnitX(target)
        set this.coords.ty      = GetUnitY(target)
        set this.coords.tz      = GetUnitFlyHeight(target)
        set this.coords.tzOff   = offset
        return this
    endmethod
    method setTargetUnit takes unit target returns thistype
        return this.setTargetUnitOffset(target, 0.0)
    endmethod
    method setTargetDest takes destructable target returns thistype
        set this.targType   = TARGET_TYPE_MOVING + TARGET_TYPE_DESTRUCTABLE
        set this.targDest   = target
        set this.targItem   = null
        set this.targUnit   = null
        set this.coords.tx  = GetDestructableX(target)
        set this.coords.ty  = GetDestructableY(target)
        set this.coords.tz  = 0.0
        return this
    endmethod
    method setTargetItem takes item target returns thistype
        set this.targType   = TARGET_TYPE_MOVING + TARGET_TYPE_ITEM
        set this.targItem   = target
        set this.targDest   = null
        set this.targUnit   = null
        set this.coords.tx  = GetItemX(target)
        set this.coords.ty  = GetItemY(target)
        set this.coords.tz  = 0.0
        return this
    endmethod

    static method create takes string model, real cx, real cy, ObjectMovementResponse resp returns thistype
        local thistype this         = thistype.allocate()
        set this.effect             = AddSpecialEffect(model, cx, cy)
        set this.easeMode           = thistype.linear
        set this.curvePath          = thistype.linearPath
        set this.moveStatus         = STATUS_ALLOCATED + STATUS_UNUSED + STATUS_STOPPED
        set this.targType           = 0
        set this.instanceFlags      = resp.flag
        set this.pVeloc             = 0.0
        set this.respHandler        = resp
        set this.objectType         = OBJECT_TYPE_EFFECT
        return this
    endmethod

    static method createForUnit takes unit whichUnit, ObjectMovementResponse resp returns thistype
        local thistype this         = thistype.allocate()
        set this.unit               = whichUnit
        set this.easeMode           = thistype.linear
        set this.curvePath          = thistype.linearPath
        set this.moveStatus         = STATUS_ALLOCATED + STATUS_UNUSED + STATUS_STOPPED
        set this.targType           = 0
        set this.instanceFlags      = resp.flag
        set this.pVeloc             = 0.0
        set this.respHandler        = resp
        set this.instanceListPtr    = ObjectMovementData.addUnitInstance(whichUnit, this)
        set this.objectType         = OBJECT_TYPE_UNIT
        return this
    endmethod

    static method createForItem takes item whichItem, ObjectMovementResponse resp returns thistype
        local thistype this         = thistype.allocate()
        set this.item               = whichItem
        set this.easeMode           = thistype.linear
        set this.curvePath          = thistype.linearPath
        set this.moveStatus         = STATUS_ALLOCATED + STATUS_UNUSED + STATUS_STOPPED
        set this.targType           = 0
        set this.instanceFlags      = resp.flag
        set this.pVeloc             = 0.0
        set this.respHandler        = resp
        set this.objectType         = OBJECT_TYPE_ITEM
        return this
    endmethod

    //  ==================================================
    //  Find a way to compute for distance as computationally
    //  non-taxing as possible.
    private static real dx              = 0.0
    private static real dy              = 0.0
    private static real dz              = 0.0
    private static real normalFactor    = 0.0
    private static real gradFactor      = 0.0
    private static real srcDist2        = 0.0
    private static real objDist2        = 0.0
    private static real lastBezier      = 0.0
    private static unit tempUnit        = null
    //! textmacro_once UNIT_MOVEMENT_PROCESS_TARG_STATE takes TYPE, TYPEFUNC, TARGETTYPE, COND
            if (Get$TYPEFUNC$TypeId(this.targ$TYPE$) == 0) then
                if (BlzBitAnd(this.instanceFlags, FLAG_DESTROY_ON_TARGET_REMOVE) != 0) then
                    call this.destroy()
                else
                    set this.targType   = BlzBitAnd(this.targType, -($TARGETTYPE$) - 1)
                    set this.targType   = BlzBitOr(this.targType, TARGET_TYPE_STATIC)
                endif
            elseif ($COND$) then
                if (BlzBitAnd(this.instanceFlags, FLAG_DESTROY_ON_TARGET_DEATH) != 0) then
                    call this.destroy()
                else
                    set this.targType   = BlzBitAnd(this.targType, -($TARGETTYPE$) - 1)
                    set this.targType   = BlzBitOr(this.targType, TARGET_TYPE_STATIC)
                endif
            endif
    //! endtextmacro
    private method processTargState takes nothing returns nothing
        //  Turns out, I forgot to mask the bits I wanted to inspect in
        //  the first place, leading to a dangerous situation where the
        //  null item would cause the targeting scheme to become static
        local integer mask  = BlzBitAnd(this.targType, TARGET_TYPE_MASK)
        if (mask == TARGET_TYPE_UNIT) then
            //! runtextmacro UNIT_MOVEMENT_PROCESS_TARG_STATE("Unit", "Unit", "TARGET_TYPE_UNIT", "not UnitAlive(this.targUnit)")
        endif
        if (mask == TARGET_TYPE_DESTRUCTABLE) then
            //! runtextmacro UNIT_MOVEMENT_PROCESS_TARG_STATE("Dest", "Destructable", "TARGET_TYPE_DESTRUCTABLE", "GetWidgetLife(this.targDest) <= 0.0")
        endif
        if (mask == TARGET_TYPE_ITEM) then
            //! runtextmacro UNIT_MOVEMENT_PROCESS_TARG_STATE("Item", "Item", "TARGET_TYPE_ITEM", "GetWidgetLife(this.targItem) <= 0.0")
        endif
    endmethod
    private method processTargMovement takes nothing returns nothing
        //  Target unit
        local integer mask  = BlzBitAnd(this.targType, TARGET_TYPE_MASK)
        if (mask == TARGET_TYPE_UNIT) then
            set this.coords.tx  = GetUnitX(this.targUnit)
            set this.coords.ty  = GetUnitY(this.targUnit)
            set this.coords.tz  = GetUnitFlyHeight(this.targUnit) + this.coords.tzOff
        endif
        if (mask == TARGET_TYPE_DESTRUCTABLE) then
            set this.coords.tx  = GetDestructableX(this.targDest)
            set this.coords.ty  = GetDestructableY(this.targDest)
            set this.coords.tz  = 0.0
        endif
        if (mask == TARGET_TYPE_ITEM) then
            set this.coords.tx  = GetItemX(this.targItem)
            set this.coords.ty  = GetItemY(this.targItem)
            set this.coords.tz  = 0.0
        endif
        if (BlzBitAnd(this.objectType, OBJECT_TYPE_EFFECT) != 0) then
            set this.coords.tz  = this.coords.tz + ObjectCoords.getZ(this.coords.tx, this.coords.ty)
        endif
    endmethod
    private method processMovementSub takes integer id, MovementListItem iter returns MovementListItem
        if (this.coords.curProgValue + this.coords.bezierSkipValue >= 1.0) then
            //  The object has reached its' destination
            set dx                          = this.pMovementPath.getX(1.0) - this.coords.ox
            set dy                          = this.pMovementPath.getY(1.0) - this.coords.oy
            set dz                          = this.pMovementPath.getZ(1.0) - this.coords.oz
            set this.coords.ox              = this.coords.ox + dx
            set this.coords.oy              = this.coords.oy + dy
            set this.coords.oz              = this.coords.oz + dz
            set this.coords.angle           = Atan2(dy, dx)
            //  Move unit.
            call this.stop()
        else
            //  The object is still moving
            set lastBezier                  = this.coords.curBezierValue
            set this.coords.curBezierValue  = this.easeMode[this.coords.curProgValue]
            set this.coords.curProgValue    = this.coords.curProgValue + this.coords.bezierSkipValue
            set dx                          = this.pMovementPath.getX(this.coords.curBezierValue) - this.coords.ox
            set dy                          = this.pMovementPath.getY(this.coords.curBezierValue) - this.coords.oy
            set dz                          = this.pMovementPath.getZ(this.coords.curBezierValue) - this.coords.oz
            set this.coords.ox              = this.coords.ox + dx
            set this.coords.oy              = this.coords.oy + dy
            set this.coords.oz              = this.coords.oz + dz
            set this.coords.angle           = Atan2(dy, dx)
            //  Move unit.
            call this.invokeCallback(EVENT_MOVING)
        endif
        //  Check if instance is already cleaned up.
        if ((BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) and /*
        */ (ObjectMovementData.instanceList[id] == 0)) then
            //  Instance was removed.
            return 0
        endif
        return iter
    endmethod
    private method processMovement takes boolean computeDist, integer id, MovementListItem iter returns MovementListItem
        local real temp
        set iter        = iter.next

        //  ======================================  //
        //      Flag checks Section                 //
        //  ======================================  //
        if (BlzBitAnd(this.moveStatus, STATUS_READDED) != 0) then
            return iter
        endif
        if (BlzBitAnd(this.instanceFlags, FLAG_DESTROY_ON_OBJECT_DEATH) != 0) then
            if ((this.objectType == OBJECT_TYPE_UNIT) and /*
            */ (not UnitAlive(this.unit))) or /*
            */ ((this.objectType == OBJECT_TYPE_ITEM) and /*
            */ (GetWidgetLife(this.item) < 0.405)) then
                call this.destroy()
                return iter
            endif
        endif
        if (this.objectType == OBJECT_TYPE_UNIT) and /*
         */ (BlzBitAnd(this.instanceFlags, FLAG_STOP_ON_UNIT_ROOT) != 0) and /*
         */ (IsUnitType(this.unit, UNIT_TYPE_SNARED)) then
            call this.stop()
            return iter
        endif

        //  ======================================  //
        //              Static movement             //
        //  ======================================  //
        if (BlzBitAnd(this.targType, TARGET_TYPE_STATIC) != 0) then
            return this.processMovementSub(id, iter)
        endif

        //  Check each target type either for death or removal.
        call this.processTargState()
        if (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) then
            if (ObjectMovementData.instanceList[id] == 0) then
                return 0
            endif
            return iter
        endif
        //  Check if target type has been changed. If so, call function
        //  again.
        if (BlzBitAnd(this.targType, TARGET_TYPE_STATIC) != 0) then
            return this.processMovementSub(id, iter)
        endif
        call this.processTargMovement()

        //  Location is tagged. Calculate the distance when prompted
        if (computeDist) then
            set srcDist2                    = GetDistanceXY(this.coords.cx, this.coords.cy, /*
                                                        */  this.coords.tx, this.coords.ty)
            set temp                        = 1.0 / srcDist2
            set this.coords.bezierSkipValue = this.pVeloc * temp
            call this.pMovementPath.adjustPos(this.coords.cx, this.coords.cy, this.coords.cz, /*
                                            */this.coords.tx, this.coords.ty, this.coords.tz)
        endif
        set iter                            = this.processMovementSub(id, iter)
        //  Check if instance is already cleaned up.
        if ((BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) and /*
        */ (ObjectMovementData.instanceList[id] == 0)) then
                //  Instance was removed.
            return 0
        endif
        return iter
    endmethod

    private method applyMovement takes nothing returns nothing
        local real pitch            = 0.5
        local boolean factorGround  = (BlzBitAnd(this.instanceFlags, FLAG_IGNORE_GROUND_PATHING) != 0) and /*
                                   */ (this.objectType == OBJECT_TYPE_UNIT) and /*
                                   */ (BlzBitAnd(BlzGetUnitIntegerField(this.unit, UNIT_IF_MOVE_TYPE), 61) != 0)
        if (BlzBitAnd(this.moveStatus, STATUS_READDED) != 0) or /*
        */ (BlzBitAnd(this.moveStatus, STATUS_ALLOCATED) == 0) then
            return
        endif
        if (this.objectType == OBJECT_TYPE_UNIT) then
            set dx          = dx + GetUnitX(this.unit)
            set dy          = dy + GetUnitY(this.unit)
            set dz          = dz + GetUnitFlyHeight(this.unit)
            if (factorGround) and (not IsValidGroundPathing(dx, dy)) then
                set dx      = GetGroundPathX()
                set dy      = GetGroundPathY()
            endif
            call SetUnitX(this.unit, dx)
            call SetUnitY(this.unit, dy)
            call SetUnitFlyHeight(this.unit, dz, 0.0)
            call SetUnitFacing(this.unit, this.coords.angle*bj_RADTODEG)
            return
        endif
        if (this.objectType == OBJECT_TYPE_EFFECT) then
            if (dz < 0) then
                set pitch   = -0.5
            endif
            set pitch       = ModuloReal(Atan2(dz*dz, dx*dx + dy*dy) * pitch, 2*bj_PI)
            set dx          = dx + BlzGetLocalSpecialEffectX(this.effect)
            set dy          = dy + BlzGetLocalSpecialEffectY(this.effect)
            set dz          = dz + BlzGetLocalSpecialEffectZ(this.effect)
            call BlzSetSpecialEffectPosition(this.effect, dx, dy, dz)
            call BlzSetSpecialEffectYaw(this.effect, ModuloReal(this.coords.angle, 2*bj_PI))
            call BlzSetSpecialEffectPitch(this.effect, pitch)
            return
        endif
        set dx              = dx + GetItemX(this.item)
        set dy              = dy + GetItemY(this.item)
        call SetItemPosition(this.item, dx, dy)
    endmethod

    private static method onMovementUpdate takes nothing returns nothing
        local integer unitIter      = 0
        local integer id            = 0
        local integer ttype         = 0
        local MovementListItem iter = ObjectMovementData.moveList.first
        local thistype this         = iter.data
        local boolean computeDist   = false
        set loopIterCount           = ModuloInteger(loopIterCount + 1, TICKS_FOR_CALC_DISTANCE())
        set computeDist             = (loopIterCount == 0)
        set inCallback              = true
        loop
            exitwhen (iter == 0)
            set iter                = this.processMovement(computeDist, id, iter)
            call this.applyMovement()
            if (BlzBitAnd(this.moveStatus, STATUS_READDED) != 0) then
                set this.moveStatus = this.moveStatus - STATUS_READDED
            endif
            set this                = iter.data
        endloop
        set inCallback              = false
    endmethod

    //  ==================================================
    private static method onExit takes nothing returns nothing
        //  Fix this later
        local integer id    = GetIndexedUnitId()
        //  If unit doesn't have any instances in the first place, do not proceed.
        if (ObjectMovementData.instanceList[id] == 0) then
            return
        endif
        loop
            //  The destroy method calls removeInstance, which cleans up the instanceList[id]
            //  for us if the list in question is empty.
            exitwhen (ObjectMovementData.instanceList[id] == 0)
            call thistype(ObjectMovementData.instanceList[id].first.data).destroy()
        endloop
    endmethod
    private static method onEnter takes nothing returns nothing
        if ((UnitAddAbility(GetIndexedUnit(), 'Amrf')) and /*
        */  (UnitRemoveAbility(GetIndexedUnit(), 'Amrf'))) then
        endif
    endmethod
    private static method init takes nothing returns nothing
        set linear                          = BezierEase.linear
        set linearPath                      = BezierCurve.create(1)
        set ObjectMovementData.moveList     = MovementList.create()
        set ObjectMovementData.movementResp = GTimer.register(GAME_TICK, function thistype.onMovementUpdate)
        call OnUnitIndex(function thistype.onEnter)
        call OnUnitDeindex(function thistype.onExit)
    endmethod
    implement Init
endstruct

module ObjectMovementTemplate
    static ObjectMovementResponse resp      = 0
    static BezierCurve curveBase            = 0

    //  Stub method operator.
    static if not thistype.FLAGSET.exists then
    static method FLAGSET takes nothing returns integer
        return ObjectMovement.FLAG_NO_TARGET_ON_STOP + ObjectMovement.FLAG_DESTROY_ON_OBJECT_DEATH + /*
            */ ObjectMovement.FLAG_IGNORE_GROUND_PATHING
    endmethod
    endif

    static if not thistype.MISSILE_MODEL.exists then
    static method MISSILE_MODEL takes nothing returns string
        return ""
    endmethod
    endif

    static method applyUnitMovement takes unit whichUnit returns ObjectMovement
        local ObjectMovement object = ObjectMovement.createForUnit(whichUnit, thistype.resp)
        set object.curvePath        = thistype.curveBase
        return object
    endmethod

    static method applyItemMovement takes item whichItem returns ObjectMovement
        local ObjectMovement object = ObjectMovement.createForItem(whichItem, thistype.resp)
        set object.curvePath        = thistype.curveBase
        return object
    endmethod

    static method applyMovement takes real cx, real cy returns ObjectMovement
        local ObjectMovement object = ObjectMovement.create(thistype.MISSILE_MODEL(), cx, cy, thistype.resp)
        set object.curvePath        = thistype.curveBase
        return object
    endmethod

    static method applyCustomMovement takes string model, real cx, real cy returns ObjectMovement
        local ObjectMovement object = ObjectMovement.create(model, cx, cy, thistype.resp)
        set object.curvePath        = thistype.curveBase
        return object
    endmethod

    private static method onInit takes nothing returns nothing
        set resp            = ObjectMovementResponse.create(null, null, null, null, null, null)
        set resp.flag       = thistype.FLAGSET()
        static if thistype.defineMissileCurve.exists then
            set curveBase   = BezierCurve.create(thistype.MISSILE_CURVE_NODES())
            call thistype.defineMissileCurve(curveBase)
        else
            set curveBase   = ObjectMovement.linearPath
        endif
        static if (thistype.onLaunch.exists) then
            call resp.launchResponse.change(function thistype.onLaunch)
        endif
        static if (thistype.onMove.exists) then
            call resp.moveResponse.change(function thistype.onMove)
        endif
        static if (thistype.onStop.exists) then
            call resp.stopResponse.change(function thistype.onStop)
        endif
        static if (thistype.onResume.exists) then
            call resp.resumeResponse.change(function thistype.onResume)
        endif
        static if (thistype.onPause.exists) then
            call resp.pauseResponse.change(function thistype.onPause)
        endif
        static if (thistype.onDest.exists) then
            call resp.destroyResponse.change(function thistype.onDest)
        endif
    endmethod
endmodule

function GetSpecialEffectHeight takes effect whichEffect returns real
    return BlzGetLocalSpecialEffectZ(whichEffect) - ObjectCoords.getZ(BlzGetLocalSpecialEffectX(whichEffect), BlzGetLocalSpecialEffectY(whichEffect))
endfunction
function SetSpecialEffectHeight takes effect whichEffect, real height returns nothing
    call BlzSetSpecialEffectZ(whichEffect, ObjectCoords.getZ(BlzGetLocalSpecialEffectX(whichEffect), BlzGetLocalSpecialEffectY(whichEffect)) + height)
endfunction

endlibrary