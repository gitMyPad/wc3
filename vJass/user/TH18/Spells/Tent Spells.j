scope TentSpells

//  =======================================================================
//  Lumber gathering
private module LumberSynthesisConfig
    static constant method operator LUMBER_ABIL_ID takes nothing returns integer
        return 'A00L'
    endmethod
    static constant method operator LUMBER_ENUM_RANGE takes nothing returns real
        return 1800.0
    endmethod
    static constant method operator LUMBER_GENERATE_AMOUNT takes nothing returns integer
        return 10
    endmethod
    static constant method operator LUMBER_GENERATE_INTERVAL takes nothing returns real
        return 15.0
    endmethod
    static constant method operator LUMBER_GENERATE_WISP_MAX takes nothing returns integer
        return 4
    endmethod
    static constant method operator LUMBER_GARRISON_UNIT_ID takes nothing returns integer
        return 'e003'
    endmethod
    static constant method operator LUMBER_GENERATE_WISP_INTERVAL takes nothing returns real
        return 30.0
    endmethod
    static constant method operator LUMBER_GENERATE_MODEL_TIME takes nothing returns real
        return 0.380
    endmethod
    static constant method operator LUMBER_GENERATE_MODEL_HEIGHT takes nothing returns real
        return 200.0
    endmethod
    static constant method operator LUMBER_GENERATE_MODEL takes nothing returns string
        return "Custom\\Model\\Unit\\WispEx.mdx"
    endmethod
    static constant method operator LUMBER_GATHER_MODEL takes nothing returns string
        return "Custom\\Model\\Effect\\Soul Armor Lime Ex.mdx"
    endmethod
    static constant method operator LUMBER_EMPTY_MODEL takes nothing returns string
        return "Custom\\Model\\dummy.mdx"
    endmethod
    static constant method operator LUMBER_GENERATE_MODEL_SCALE takes nothing returns real
        return 1.50
    endmethod
    static constant method operator LUMBER_GATHER_MODEL_Z takes nothing returns real
        return 80.0
    endmethod
    static constant method operator LUMBER_VISION_RADIUS takes nothing returns real
        return 300.0
    endmethod
    static constant method operator LUMBER_ALPHA_START takes nothing returns integer
        return 0xff
    endmethod
    static constant method operator LUMBER_ALPHA_END takes nothing returns integer
        return 0x7f
    endmethod
    static constant method operator LUMBER_FADE_TRANSITION takes nothing returns real
        return 4.0
    endmethod
endmodule
private module LumberMissileConfig
    static constant method operator LUMBER_MISSILE_SPEED takes nothing returns real
        return 600.0
    endmethod
    static constant method operator LUMBER_MISSILE_RETURN_SPEED takes nothing returns real
        return 300.0
    endmethod
    static constant method operator LUMBER_MISSILE_Z_START takes nothing returns real
        return 200.0
    endmethod
    static constant method operator LUMBER_MISSILE_Z_END takes nothing returns real
        return 50.0
    endmethod
    static method MISSILE_MODEL takes nothing returns string
        return "Custom\\Model\\Projectile\\Chaos Missile.mdx"
    endmethod
    static method FLAGSET takes nothing returns integer
        return ObjectMovement.FLAG_DESTROY_ON_STOP
    endmethod
endmodule

//  =======================================================================
//  Tent Regeneration Ability
private module TentLoadUnloadConfig
    static constant method operator REGEN_ABIL_ID takes nothing returns integer
        return 'A00M'
    endmethod
    static constant method operator REGEN_HP_AMOUNT_DAY takes nothing returns real
        return 20.0
    endmethod
    static constant method operator REGEN_MP_AMOUNT_DAY takes nothing returns real
        return 12.0
    endmethod
    static constant method operator REGEN_HP_AMOUNT_NIGHT takes nothing returns real
        return 10.0
    endmethod
    static constant method operator REGEN_MP_AMOUNT_NIGHT takes nothing returns real
        return 6.0
    endmethod
    static constant method operator REGEN_TICK takes nothing returns integer
        return 1
    endmethod
endmodule

//  ======================================================================
//                      Lumber Synthesis Mechanics
//  ======================================================================
scope LumberSynthesis

private keyword LumberSynthesis

private struct LumberTreeMap extends array
    implement Alloc

    destructable dest
    effect treeFX
    LumberSynthesis owner
    boolean isActive
    timer lumberTimer
    IntegerListItem ptr
    IntegerListItem spiritPtr
    fogmodifier vision

    method operator x takes nothing returns real
        return GetDestructableX(this.dest)
    endmethod

    method operator y takes nothing returns real
        return GetDestructableY(this.dest)
    endmethod
    
    method destroy takes nothing returns nothing
        if (this.treeFX != null) then
            call DestroyEffect(this.treeFX)
        endif
        if (this.lumberTimer != null) then
            call ReleaseTimer(this.lumberTimer)
        endif
        if (this.vision != null) then
            call FogModifierStop(this.vision)
            call DestroyFogModifier(this.vision)
        endif
        set this.dest           = null
        set this.treeFX         = null
        set this.lumberTimer    = null
        set this.vision         = null
        set this.isActive       = false
        set this.owner          = 0
        set this.ptr            = 0
        set this.spiritPtr      = 0
        call this.deallocate()
    endmethod

    static method create takes destructable d, LumberSynthesis owner returns thistype
        local thistype this = thistype.allocate()
        set this.dest       = d
        set this.owner      = owner
        return this
    endmethod
endstruct

private struct LumberMissile extends array
    implement LumberMissileConfig

    readonly static constant integer PHASE_FORWARD  = 1
    readonly static constant integer PHASE_RETURN   = 2
    readonly static BezierEase FORWARD_EASE         = 0
    readonly static BezierEase RETURN_EASE          = 0
    readonly static BezierCurve FORWARD_CURVE       = 0
    static EventResponder forwardResp               = 0
    static EventResponder returnResp                = 0
    static EventResponder monitorResp               = 0

    integer phase

    private static method onStop takes nothing returns nothing
        local thistype this             = ObjectMovement.current
        if (this.phase == PHASE_FORWARD) then
            call forwardResp.run()
        else
            call returnResp.run()
        endif
        set this.phase                  = 0
    endmethod

    private static method onMove takes nothing returns nothing
        call monitorResp.run()
    endmethod

    private static method init takes nothing returns nothing
        set FORWARD_EASE        = BezierEasing.create(0.67, 0.0, 0.8, 0.35)
        set RETURN_EASE         = BezierEase.linear
        set FORWARD_CURVE       = BezierCurve.create(3)
        set FORWARD_CURVE[1].x  = -0.1
        set FORWARD_CURVE[1].y  = -0.1
        set FORWARD_CURVE[1].z  = 1.1
        set FORWARD_CURVE[2].x  = 0.40
        set FORWARD_CURVE[2].y  = 0.40
        set FORWARD_CURVE[2].z  = 1.0
    endmethod

    implement Init
    implement ObjectMovementTemplate
endstruct

private struct LumberSynthesis extends array
    implement LumberSynthesisConfig

    private static      code  generateWispPtr       = null
    private static      Table destMap               = 0
    private static      IntegerList tentList        = 0
    private static      IntegerList destList        = 0
    private static      EventResponder destResp     = 0
    private static      EventResponder tentResp     = 0

    private static constant integer PHASE_GENERATE  = 1
    private static constant integer PHASE_HOLD      = 2
    private integer         currentPhase

    private IntegerListItem tentPtr

    private boolean     inUse
    private boolean     isGenerating
    private boolean     alreadyEnumed
    private boolean     wasConstructing

    private IntegerList spiritList
    private integer     workerCount
    private integer     activeSpiritCount

    private timer       generatorTimer
    private effect      generatorFx
    private real        generatorZ

    private static method operator [] takes unit source returns thistype
        return GetUnitId(source)
    endmethod

    method operator unit takes nothing returns unit
        return GetUnitById(this)
    endmethod

    //  ======================================================
    //              Relation clearing function
    //  ======================================================
    private method removeTree takes LumberTreeMap map returns nothing
        local real cz               = 0.0
        set  this.activeSpiritCount = this.activeSpiritCount - 1
        if (map.spiritPtr != 0) then
            call this.spiritList.remove(map.spiritPtr)
        endif
        call destList.remove(map.ptr)
        call destMap.integer.remove(GetHandleId(map.dest))
        call map.destroy()

        if (this.currentPhase == PHASE_HOLD) then
            set this.currentPhase   = PHASE_GENERATE
            set this.alreadyEnumed  = false
            set this.generatorTimer = NewTimerEx(this)
            set this.generatorFx    = AddSpecialEffect(LUMBER_GENERATE_MODEL, GetUnitX(this.unit), GetUnitY(this.unit))
            call BlzSetSpecialEffectMatrixScale(this.generatorFx, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE)
            call BlzSetSpecialEffectZ(this.generatorFx, BlzGetLocalSpecialEffectZ(this.generatorFx) + LUMBER_GENERATE_MODEL_HEIGHT)
            set cz                  = BlzGetLocalSpecialEffectZ(this.generatorFx)
            if (DNCycle.isDay) and (not IsUnitVisible(this.unit, GetLocalPlayer())) then
                call BlzSetSpecialEffectX(this.generatorFx, WorldBounds.minX)
                call BlzSetSpecialEffectY(this.generatorFx, WorldBounds.minY)
                call BlzSetSpecialEffectZ(this.generatorFx, cz)
            endif
            if (this.workerCount > 0) then
                call TimerStart(this.generatorTimer, LUMBER_GENERATE_WISP_INTERVAL / I2R(this.workerCount), false, generateWispPtr)
            endif
        endif
        if (destList.empty()) then
            call GTimer[UPDATE_TICK].releaseCallback(destResp)
        endif
    endmethod

    private method destroy takes nothing returns nothing
        local LumberTreeMap map = 0
        if (not this.inUse) then
            return
        endif
        //  Clear out all used destructables.
        if (this.spiritList != 0) then
            loop
                exitwhen this.spiritList.empty()
                set map         = this.spiritList.first.data
                call this.removeTree(map)
            endloop
            call this.spiritList.destroy()
        endif
        if (this.generatorTimer != null) then
            call ReleaseTimer(this.generatorTimer)
        endif
        if (this.generatorFx != null) then
            call BlzSetSpecialEffectTimeScale(this.generatorFx, 1.0)
            call DestroyEffect(this.generatorFx)
        endif
        call tentList.erase(this.tentPtr)
        set this.inUse              = false
        set this.alreadyEnumed      = false
        set this.generatorTimer     = null
        set this.generatorFx        = null
        set this.currentPhase       = 0
        set this.activeSpiritCount  = 0
        set this.workerCount        = 0
        set this.spiritList         = 0
        set this.tentPtr            = 0
    endmethod

    //  ======================================================
    //          Desireable Tree filter function
    //  ======================================================
    private static method isValidTree takes destructable dest, boolean checkSize returns boolean
        local real cx                           = GetDestructableX(dest)
        local real cy                           = GetDestructableY(dest)
        local real dist                         = (cx - sourceCX)*(cx - sourceCX) + /*
                                               */ (cy - sourceCY)*(cy - sourceCY)
        //  Filter out trees that are visible
        if (not IsDestructableTree(dest)) or /*
        */ (IsDestructableDead(dest)) or /*
        */ (4.0*dist > LUMBER_ENUM_RANGE*LUMBER_ENUM_RANGE) or /*
        */ (not IsVisibleToPlayer(cx, cy, GetOwningPlayer(sourceInstance.unit))) or /*
        */ (destMap.integer.has(GetHandleId(dest))) or /*
        */ ((checkSize) and /*
        */ (sourceInstance.spiritList.size() >= LUMBER_GENERATE_WISP_MAX)) then
            return false
        endif
        return true        
    endmethod

    //  ======================================================
    //          Extension Callback handlers
    //          - onFeedbackLumber
    //  ======================================================
    private static method onFeedbackLumber takes nothing returns nothing
        local LumberTreeMap map                         = GetTimerData(GetExpiredTimer())
        local thistype this                             = map.owner
        local ObjectMovement object                     = 0
        local string model                              = LumberMissile.MISSILE_MODEL()
        if (not this.inUse) then
            return
        endif
        if (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            set model                                   = LUMBER_EMPTY_MODEL
        endif
        set object                                      = LumberMissile.applyCustomMovement(model, map.x, map.y)
        set object.veloc                                = LumberMissile.LUMBER_MISSILE_RETURN_SPEED
        set object.data                                 = map
        set object.easeMode                             = LumberMissile.RETURN_EASE
        set LumberMissile(object).phase                 = LumberMissile.PHASE_RETURN
        call object.setTargetAreaXY(GetUnitX(this.unit), GetUnitY(this.unit))
        call object.launch()
    endmethod

    //  ======================================================
    //          Extension Callback handlers
    //          - onGenerateWisp
    //  ======================================================
    private static real     sourceCX            = 0.0
    private static real     sourceCY            = 0.0
    private static thistype sourceInstance      = 0

    private method generateForwardMissile takes LumberTreeMap map returns nothing
        local string model                              = LumberMissile.MISSILE_MODEL()
        local ObjectMovement object                     = 0
        if (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            set model                                   = LUMBER_EMPTY_MODEL
        endif
        set object                                      = LumberMissile.applyCustomMovement(model, sourceCX, sourceCY)
        call SetSpecialEffectHeight(object.effect, LumberMissile.LUMBER_MISSILE_Z_START)
        set object.veloc                                = LumberMissile.LUMBER_MISSILE_SPEED
        set object.data                                 = map
        set object.easeMode                             = LumberMissile.FORWARD_EASE
        set object.curvePath                            = LumberMissile.FORWARD_CURVE
        set LumberMissile(object).phase                 = LumberMissile.PHASE_FORWARD

        call object.setTargetArea(map.x, map.y, LumberMissile.LUMBER_MISSILE_Z_END)
        call object.launch()
    endmethod

    private static method onSelectTrees takes nothing returns nothing
        local destructable dest                 = GetEnumDestructable()
        local LumberTreeMap map                 = 0
        //  Filter out trees that are visible
        if (not thistype.isValidTree(dest, true)) then
            set dest                            = null
            return
        endif
        set map                                 = LumberTreeMap.create(dest, sourceInstance)
        set map.ptr                             = destList.push(map).last
        set destMap.integer[GetHandleId(dest)]  = map
        set map.spiritPtr                       = sourceInstance.spiritList.push(map).last
        if (destList.size() == 1) then
            call GTimer[UPDATE_TICK].requestCallback(destResp)
        endif
    endmethod

    private static method onGenerateWisp takes nothing returns nothing
        local thistype this         = GetTimerData(GetExpiredTimer())
        local real cz
        local rect enumRect
        local IntegerListItem iter
        local LumberTreeMap map
        set sourceInstance          = this
        set sourceCX                = GetUnitX(this.unit)
        set sourceCY                = GetUnitY(this.unit)
        if (not this.alreadyEnumed) then
            set this.alreadyEnumed  = true
            if (this.spiritList == 0) then
                set this.spiritList = IntegerList.create()
            endif
            set enumRect            = Rect(sourceCX - LUMBER_ENUM_RANGE * 0.5, sourceCY - LUMBER_ENUM_RANGE * 0.5, /*
                                        */ sourceCX + LUMBER_ENUM_RANGE * 0.5, sourceCY + LUMBER_ENUM_RANGE * 0.5)
            call EnumDestructablesInRect(enumRect, null, function thistype.onSelectTrees)
            call RemoveRect(enumRect)
            set enumRect            = null
        endif
        if (this.activeSpiritCount >= LUMBER_GENERATE_WISP_MAX) then
            return
        endif
        set this.activeSpiritCount  = this.activeSpiritCount + 1
        set iter                    = this.spiritList.first
        loop
            set map                 = iter.data
            exitwhen (iter == 0)
            if (not map.isActive) then
                set map.isActive    = true
                exitwhen true
            endif
            set iter                = iter.next
        endloop
        //  Send a missile directed from the wisp to the tree.
        call this.generateForwardMissile(map)
        //  Stop once we've reached the max
        if (this.activeSpiritCount >= LUMBER_GENERATE_WISP_MAX) then
            set this.currentPhase   = PHASE_HOLD
            set this.isGenerating   = false
            call BlzSetSpecialEffectTimeScale(this.generatorFx, 1.0)
            call DestroyEffect(this.generatorFx)
            call ReleaseTimer(this.generatorTimer)
            set this.generatorFx    = null
            set this.generatorTimer = null
            return
        endif
        //  Reset the wisp model.
        call BlzSetSpecialEffectTimeScale(this.generatorFx, 0.0)
        call BlzSetSpecialEffectZ(this.generatorFx, -RAbsBJ(BlzGetLocalSpecialEffectZ(this.generatorFx)))
        call DestroyEffect(this.generatorFx)
        set this.generatorFx    = AddSpecialEffect(LUMBER_GENERATE_MODEL, GetUnitX(this.unit), GetUnitY(this.unit))
        call BlzSetSpecialEffectMatrixScale(this.generatorFx, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE)
        call BlzSetSpecialEffectTimeScale(this.generatorFx, LUMBER_GENERATE_MODEL_TIME / LUMBER_GENERATE_WISP_INTERVAL * this.workerCount)
        //  The coordinates of this particular special effect
        //  are not meant to be used synchronously.
        call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
        if (DNCycle.isDay) and (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            call BlzSetSpecialEffectX(this.generatorFx, WorldBounds.minX)
            call BlzSetSpecialEffectY(this.generatorFx, WorldBounds.minY)
            call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
        endif
        call TimerStart(this.generatorTimer, LUMBER_GENERATE_WISP_INTERVAL / I2R(this.workerCount), false, function thistype.onGenerateWisp)
    endmethod

    //  ==========================================================
    //          Tree checking functions.
    //  ==========================================================
    private static destructable nextTree    = null
    private static method onLocateAdjacentTree takes nothing returns nothing
        local destructable dest             = GetEnumDestructable()
        //  Filter out trees that are visible
        if (nextTree != null) or /*
        */ (not thistype.isValidTree(dest, false)) then
            set dest                        = null
            return
        endif
        set nextTree                        = dest
        set dest                            = null
    endmethod

    private method findNextTree takes LumberTreeMap map returns boolean
        local rect enumRect
        set nextTree            = null
        set sourceCX            = map.x
        set sourceCY            = map.y
        set sourceInstance      = this
        set enumRect            = Rect(sourceCX - LUMBER_ENUM_RANGE * 0.5, sourceCY - LUMBER_ENUM_RANGE * 0.5, /*
                                    */ sourceCX + LUMBER_ENUM_RANGE * 0.5, sourceCY + LUMBER_ENUM_RANGE * 0.5)
        call EnumDestructablesInRect(enumRect, null, function thistype.onLocateAdjacentTree)
        call RemoveRect(enumRect)
        set enumRect            = null
        return (nextTree != null)
    endmethod

    private method moveToTree takes LumberTreeMap map returns nothing
        local string model                              = LumberMissile.MISSILE_MODEL()
        local ObjectMovement object                     = 0
        if (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            set model                                   = LUMBER_EMPTY_MODEL
        endif
        set object                                      = LumberMissile.applyCustomMovement(model, sourceCX, sourceCY)
        call SetSpecialEffectHeight(object.effect, LumberMissile.LUMBER_MISSILE_Z_END)
        set object.veloc                                = LumberMissile.LUMBER_MISSILE_SPEED
        set object.data                                 = map
        set object.easeMode                             = LumberMissile.FORWARD_EASE
        set LumberMissile(object).phase                 = LumberMissile.PHASE_FORWARD

        call destMap.integer.remove(GetHandleId(map.dest))
        set map.dest                                    = nextTree
        set destMap.integer[GetHandleId(map.dest)]      = map

        //  Since the timer is created upon missile hit, might as
        //  well release the old timer.
        call ReleaseTimer(map.lumberTimer)
        set map.lumberTimer                             = null

        call object.setTargetArea(map.x, map.y, LumberMissile.LUMBER_MISSILE_Z_END)
        set EffectVisibility[object.effect].visible     = true
        set EffectVisibility[object.effect].visible     = false
        if (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            set EffectVisibility[object.effect].visible = false
        endif
        call object.launch()
    endmethod

    //  ==========================================================
    //          Event Callback Handlers.
    //  ==========================================================
    private static method onTentLoad takes nothing returns nothing
        local thistype this
        local real remain               = 0.0
        local real cz                   = 0.0
        local unit tent
        if (GetUnitAbilityLevel(UnitAuxHandler.curTransport, LUMBER_ABIL_ID) == 0) or /*
        */ (GetUnitTypeId(UnitAuxHandler.unit) != LUMBER_GARRISON_UNIT_ID) then
            return
        endif
        set tent                        = UnitAuxHandler.curTransport
        set this                        = thistype[tent]
        set this.workerCount            = this.workerCount + 1
        if (this.currentPhase == PHASE_HOLD) then
            return
        endif
        if (this.currentPhase == 0) then
            set this.inUse              = true
            set this.currentPhase       = PHASE_GENERATE
            //  Let this instance point to a node in the list
            //  that manages the visibility of certain fx.
            if (this.tentPtr == 0) then
                set this.tentPtr        = tentList.push(this).last
            endif
        endif
        if (this.workerCount == 1) then
            if (this.generatorTimer == null) then
                set this.generatorTimer = NewTimerEx(this)
                set remain              = LUMBER_GENERATE_WISP_INTERVAL
            else
                set remain              = TimerGetRemaining(this.generatorTimer)
            endif
            if (this.generatorFx == null) then
                set this.generatorFx    = AddSpecialEffect(LUMBER_GENERATE_MODEL, GetUnitX(tent), GetUnitY(tent))
                set cz                  = BlzGetLocalSpecialEffectZ(this.generatorFx) + LUMBER_GENERATE_MODEL_HEIGHT
                call BlzSetSpecialEffectMatrixScale(this.generatorFx, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE, LUMBER_GENERATE_MODEL_SCALE)
                //  The coordinates of this particular special effect
                //  are not meant to be used synchronously.
                set this.generatorZ     = cz
                call BlzSetSpecialEffectZ(this.generatorFx, cz)
                if (DNCycle.isDay) and (not IsUnitVisible(this.unit, GetLocalPlayer())) then
                    call BlzSetSpecialEffectX(this.generatorFx, WorldBounds.minX)
                    call BlzSetSpecialEffectY(this.generatorFx, WorldBounds.minY)
                    call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
                endif
            endif

        elseif (this.currentPhase == PHASE_GENERATE) then
            set remain                  = TimerGetRemaining(this.generatorTimer)
            call PauseTimer(this.generatorTimer)
            call TimerStart(this.generatorTimer, 0.0, false, null)
            call PauseTimer(this.generatorTimer)
            set remain                  = remain / I2R(this.workerCount) * (this.workerCount - 1)
        endif
        call BlzSetSpecialEffectTimeScale(this.generatorFx, LUMBER_GENERATE_MODEL_TIME / LUMBER_GENERATE_WISP_INTERVAL * this.workerCount)
        call TimerStart(this.generatorTimer, remain, false, function thistype.onGenerateWisp)
        set tent                        = null
    endmethod

    private static method onTentUnload takes nothing returns nothing
        local thistype this
        local real remain           = 0.0
        local unit tent
        set tent                    = UnitAuxHandler.curTransport
        set this                    = thistype[tent]
        if (not this.inUse) then
            set tent                = null
            return
        endif
        set this.workerCount        = IMaxBJ(this.workerCount - 1, 0)
        if (this.currentPhase != PHASE_GENERATE) then
            set tent                = null
            return
        endif
        call BlzSetSpecialEffectTimeScale(this.generatorFx, LUMBER_GENERATE_MODEL_TIME / LUMBER_GENERATE_WISP_INTERVAL * this.workerCount)
        if (this.workerCount == 0) then
            call PauseTimer(this.generatorTimer)
        else
            set remain              = TimerGetRemaining(this.generatorTimer)
            call PauseTimer(this.generatorTimer)
            call TimerStart(this.generatorTimer, 0.0, false, null)
            call PauseTimer(this.generatorTimer)
            set remain              = remain / I2R(this.workerCount) * (this.workerCount + 1)
            call TimerStart(this.generatorTimer, remain, false, function thistype.onGenerateWisp)
        endif
        set tent                    = null
    endmethod

    private static method onTentDeath takes nothing returns nothing
        local thistype this         = thistype[UnitAuxHandler.unit]
        call this.destroy()
    endmethod

    private static method onTentRemove takes nothing returns nothing
        local thistype this         = thistype[GetIndexedUnit()]
        call this.destroy()
    endmethod

    private static method onForwardMissileHit takes nothing returns nothing
        local LumberTreeMap map                         = ObjectMovement.current.data
        local thistype this                             = map.owner
        if (not this.inUse) then
            return
        endif
        set map.lumberTimer                             = NewTimerEx(map)
        set map.treeFX                                  = AddSpecialEffect(LUMBER_GATHER_MODEL, map.x, map.y)
        set map.vision                                  = CreateFogModifierRadius(GetOwningPlayer(this.unit), FOG_OF_WAR_VISIBLE, /*
                                                                               */ map.x, map.y, LUMBER_VISION_RADIUS, true, true)
        call FogModifierStart(map.vision)
        if (DNCycle.isDay) and (not IsUnitVisible(this.unit, GetLocalPlayer())) then
            call BlzSetSpecialEffectX(map.treeFX, WorldBounds.minX)
            call BlzSetSpecialEffectY(map.treeFX, WorldBounds.minY)
        endif
        if (DNCycle.isDay) then
            call VisibilityManager.effectApply(map.treeFX, LUMBER_ALPHA_START, /*
                                            */ LUMBER_ALPHA_END, LUMBER_FADE_TRANSITION)
        endif

        call BlzSetSpecialEffectZ(map.treeFX, BlzGetLocalSpecialEffectZ(map.treeFX) + LUMBER_GATHER_MODEL_Z)
        call TimerStart(map.lumberTimer, LUMBER_GENERATE_INTERVAL, true, function thistype.onFeedbackLumber)
    endmethod

    private static method onReturnMissileHit takes nothing returns nothing
        local LumberTreeMap map     = ObjectMovement.current.data
        local thistype this         = map.owner
        local player p
        local texttag tag
        if (not this.inUse) then
            return
        endif
        set p                       = GetOwningPlayer(this.unit)
        set tag                     = CreateTextTag()
        call SetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER, /* 
                        */ GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER) + LUMBER_GENERATE_AMOUNT)
        call SetPlayerState(p, PLAYER_STATE_LUMBER_GATHERED, /* 
                        */ GetPlayerState(p, PLAYER_STATE_LUMBER_GATHERED) + LUMBER_GENERATE_AMOUNT)
        //  ===============================
        //      Text tag handling.
        //  ===============================
        call SetTextTagPermanent(tag, false)
        call SetTextTagLifespan(tag, 3.0)
        call SetTextTagFadepoint(tag, 2.25)
        call SetTextTagColor(tag, 0x40, 0xff, 0x40, 0xff)
        call SetTextTagPosUnit(tag, this.unit, 20.0)
        call SetTextTagText(tag, "+ " + I2S(LUMBER_GENERATE_AMOUNT), TextTagSize2Height(10.5))
        call SetTextTagVelocity(tag, 0.0, TextTagSpeed2Velocity(100.0))
        if (GetLocalPlayer() != p) then
            call SetTextTagVisibility(tag, false)
        endif
    endmethod

    private static method onMissileMonitor takes nothing returns nothing
        local LumberTreeMap map         = ObjectMovement.current.data
        local thistype this             = map.owner
        if (not this.inUse) then
            call ObjectMovement.current.stop()
        endif
    endmethod

    private static method onTentStart takes nothing returns nothing
        local thistype this             = thistype[StructureHandler.structure]
        if (GetUnitAbilityLevel(this.unit, LUMBER_ABIL_ID) == 0) then
            return
        endif
        set this.wasConstructing        = true
        call BlzUnitDisableAbility(this.unit, LUMBER_ABIL_ID, true, true)
    endmethod
    private static method onTentEnter takes nothing returns nothing
        local thistype this             = thistype[StructureHandler.structure]
        if (GetUnitAbilityLevel(this.unit, LUMBER_ABIL_ID) == 0) then
            return
        endif
        if (this.wasConstructing) then
            set this.wasConstructing    = false
            call BlzUnitDisableAbility(this.unit, LUMBER_ABIL_ID, false, false)
        endif
    endmethod

    private static method onTentFXShowHide takes nothing returns nothing
        local IntegerListItem iter      = tentList.first
        local IntegerListItem subIter   = 0
        local LumberTreeMap map         = 0
        local thistype this             = iter.data
        local boolean isVisible         = true
        local real cz                   = 0.0
        loop
            exitwhen (tentList.empty())
            if (DNCycle.isDay) then
                call GTimer[UPDATE_TICK].requestCallback(tentResp)
            else
                call GTimer[UPDATE_TICK].releaseCallback(tentResp)
            endif
            exitwhen true
        endloop
        loop
            exitwhen (iter == 0)
            set iter                    = iter.next
            set isVisible               = IsUnitVisible(this.unit, GetLocalPlayer())
            loop
                exitwhen (this.generatorFx == null)
                if (not DNCycle.isDay) then
                    call BlzSetSpecialEffectX(this.generatorFx, GetUnitX(this.unit))
                    call BlzSetSpecialEffectY(this.generatorFx, GetUnitY(this.unit))
                    call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
                    call VisibilityManager.effectApply(this.generatorFx, LUMBER_ALPHA_END, /*
                                                    */ LUMBER_ALPHA_START, LUMBER_FADE_TRANSITION)
                else
                    if (not isVisible) then
                        call BlzSetSpecialEffectX(this.generatorFx, WorldBounds.minX)
                        call BlzSetSpecialEffectY(this.generatorFx, WorldBounds.minY)
                        call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
                    endif
                    call VisibilityManager.effectApply(this.generatorFx, LUMBER_ALPHA_START, /*
                                                    */ LUMBER_ALPHA_END, LUMBER_FADE_TRANSITION)
                endif
                exitwhen true
            endloop

            set subIter = this.spiritList.first
            set map     = subIter.data
            loop
                exitwhen (subIter == 0)
                loop
                    exitwhen (map.treeFX == null)
                    set cz              = BlzGetLocalSpecialEffectZ(map.treeFX)
                    if (not DNCycle.isDay) then
                        call BlzSetSpecialEffectX(map.treeFX, map.x)
                        call BlzSetSpecialEffectY(map.treeFX, map.y)
                        call BlzSetSpecialEffectZ(map.treeFX, cz)
                        call VisibilityManager.effectApply(map.treeFX, LUMBER_ALPHA_END, /*
                                                        */ LUMBER_ALPHA_START, LUMBER_FADE_TRANSITION)
                    else
                        if (not isVisible) then
                            call BlzSetSpecialEffectX(map.treeFX, WorldBounds.minX)
                            call BlzSetSpecialEffectY(map.treeFX, WorldBounds.minY)
                            call BlzSetSpecialEffectZ(map.treeFX, cz)
                        endif
                        call VisibilityManager.effectApply(map.treeFX, LUMBER_ALPHA_START, /*
                                                        */ LUMBER_ALPHA_END, LUMBER_FADE_TRANSITION)
                    endif
                    exitwhen true
                endloop
                set subIter = subIter.next
                set map     = subIter.data
            endloop
            set this        = iter.data
        endloop
    endmethod

    private static method checkTreeStatus takes nothing returns nothing
        local IntegerListItem iter      = destList.first
        local LumberTreeMap map         = iter.data
        local thistype this             = 0
        loop
            exitwhen (iter == 0)
            set iter                    = iter.next
            loop
                exitwhen (IsDestructableAlive(map.dest))
                set this                = map.owner

                call DestroyEffect(map.treeFX)
                call FogModifierStop(map.vision)
                call DestroyFogModifier(map.vision)
                set map.treeFX          = null
                set map.vision          = null

                if (not this.findNextTree(map)) then
                    call this.removeTree(map)
                else
                    call this.moveToTree(map)
                endif
                exitwhen true
            endloop
            set map                     = iter.data
        endloop
    endmethod

    private static method checkTentVisibility takes nothing returns nothing
        local IntegerListItem iter      = tentList.first
        local IntegerListItem subIter   = 0
        local LumberTreeMap map         = 0
        local thistype this             = iter.data
        local boolean isVisible         = true
        local real cz                   = 0.0
        loop
            exitwhen (iter == 0)
            set iter                    = iter.next
            set isVisible               = IsUnitVisible(this.unit, GetLocalPlayer())
            loop
                exitwhen (this.generatorFx == null)
                if (isVisible) then
                    call BlzSetSpecialEffectX(this.generatorFx, GetUnitX(this.unit))
                    call BlzSetSpecialEffectY(this.generatorFx, GetUnitY(this.unit))
                else
                    call BlzSetSpecialEffectX(this.generatorFx, WorldBounds.minX)
                    call BlzSetSpecialEffectY(this.generatorFx, WorldBounds.minY)
                endif
                call BlzSetSpecialEffectZ(this.generatorFx, this.generatorZ)
                exitwhen true
            endloop

            set subIter = this.spiritList.first
            set map     = subIter.data
            loop
                exitwhen (subIter == 0) or (this.spiritList == 0)
                loop
                    exitwhen (map.treeFX == null)
                    set cz              = BlzGetLocalSpecialEffectZ(map.treeFX)
                    if (isVisible) then
                        call BlzSetSpecialEffectX(map.treeFX, map.x)
                        call BlzSetSpecialEffectY(map.treeFX, map.y)
                    else
                        call BlzSetSpecialEffectX(map.treeFX, WorldBounds.minX)
                        call BlzSetSpecialEffectY(map.treeFX, WorldBounds.minY)
                    endif
                    call BlzSetSpecialEffectZ(map.treeFX, cz)
                    exitwhen true
                endloop
                set subIter = subIter.next
                set map     = subIter.data
            endloop
            set this        = iter.data
        endloop
    endmethod
    //  ======================================================

    //  ======================================================
    //              Initializer Function
    //  ======================================================
    private static method onInit takes nothing returns nothing
        call UnitAuxHandler.ON_LOAD.register(function thistype.onTentLoad)
        call UnitAuxHandler.ON_UNLOAD.register(function thistype.onTentUnload)
        call UnitAuxHandler.ON_DEATH.register(function thistype.onTentDeath)
        call StructureHandler.ON_START.register(function thistype.onTentStart)
        call StructureHandler.ON_ENTER.register(function thistype.onTentEnter)
        call DNCycle.ON_DAY.register(function thistype.onTentFXShowHide)
        call DNCycle.ON_NIGHT.register(function thistype.onTentFXShowHide)
        call OnUnitDeindex(function thistype.onTentRemove)
        set generateWispPtr             = function thistype.onGenerateWisp
        set LumberMissile.forwardResp   = EventResponder.create(function thistype.onForwardMissileHit)
        set LumberMissile.returnResp    = EventResponder.create(function thistype.onReturnMissileHit)
        set LumberMissile.monitorResp   = EventResponder.create(function thistype.onMissileMonitor)
        set destResp                    = GTimer.register(UPDATE_TICK, function thistype.checkTreeStatus)
        set tentResp                    = GTimer.register(UPDATE_TICK, function thistype.checkTentVisibility)
        set destList                    = IntegerList.create()
        set tentList                    = IntegerList.create()
    endmethod
endstruct

endscope

//  ======================================================================
//                      Tent Load Unload Mechanics
//  ======================================================================
scope TentLoadUnload

private struct TentLoadUnload extends array
    implement TentLoadUnloadConfig

    private static EventResponder intervalResp          = 0
    private static IntegerList objectList               = 0
    private static IntegerListItem array objectListPtr

    private static real ACTUAL_REGEN_HP_AMOUNT_DAY      = 0.0
    private static real ACTUAL_REGEN_MP_AMOUNT_DAY      = 0.0
    private static real ACTUAL_REGEN_HP_AMOUNT_NIGHT    = 0.0
    private static real ACTUAL_REGEN_MP_AMOUNT_NIGHT    = 0.0

    private method operator unit takes nothing returns unit
        return GetUnitById(this)
    endmethod

    private static method onTentLoad takes nothing returns nothing
        local integer tentID
        if (GetUnitAbilityLevel(UnitAuxHandler.curTransport, REGEN_ABIL_ID) == 0) then
            return
        endif
        set tentID  = GetUnitId(UnitAuxHandler.curTransport)
        if (objectListPtr[tentID] == 0) then
            set objectListPtr[tentID]   = objectList.push(tentID).last
            if (objectList.size() == 1) then
                call GTimer[REGEN_TICK].requestCallback(intervalResp)
            endif
        endif
    endmethod
    private static method onTentUnload takes nothing returns nothing
        local UnitAuxHandler tentID = UnitAuxHandler[UnitAuxHandler.curTransport]
        local unit tent
        if (objectListPtr[tentID] == 0) then
            return
        endif
        if (tentID.transportCount <= 0) then
            call objectList.erase(objectListPtr[tentID])
            set objectListPtr[tentID]   = 0
            if (objectList.empty()) then
                call GTimer[REGEN_TICK].releaseCallback(intervalResp)
            endif
        endif
    endmethod
    private static method onUnitRecover takes nothing returns nothing
        local IntegerListItem iter  = objectList.first
        local thistype this         = iter.data
        local integer i             = 0
        local integer n             = 0
        local unit temp
        loop
            exitwhen (iter == 0)
            set iter                = iter.next
            set n                   = UnitAuxHandler(this).transportCount
            loop
                exitwhen (i >= n)
                set temp            = BlzGroupUnitAt(UnitAuxHandler(this).transportGroup, i)
                set i               = i + 1
                if (DNCycle.isDay) then
                    call SetWidgetLife(temp, GetWidgetLife(temp) + ACTUAL_REGEN_HP_AMOUNT_DAY)
                    call SetUnitState(temp, UNIT_STATE_MANA, GetUnitState(temp, UNIT_STATE_MANA) + ACTUAL_REGEN_MP_AMOUNT_DAY)
                else
                    call SetWidgetLife(temp, GetWidgetLife(temp) + ACTUAL_REGEN_HP_AMOUNT_NIGHT)
                    call SetUnitState(temp, UNIT_STATE_MANA, GetUnitState(temp, UNIT_STATE_MANA) + ACTUAL_REGEN_MP_AMOUNT_NIGHT)
                endif
            endloop
            set i                   = 0
            set this                = iter.data
        endloop
        set temp                    = null
    endmethod

    //  ==================================================================
    private static method onInit takes nothing returns nothing
        set ACTUAL_REGEN_HP_AMOUNT_DAY      = REGEN_HP_AMOUNT_DAY / I2R(REGEN_TICK)
        set ACTUAL_REGEN_MP_AMOUNT_DAY      = REGEN_MP_AMOUNT_DAY / I2R(REGEN_TICK)
        set ACTUAL_REGEN_HP_AMOUNT_NIGHT    = REGEN_HP_AMOUNT_NIGHT / I2R(REGEN_TICK)
        set ACTUAL_REGEN_MP_AMOUNT_NIGHT    = REGEN_MP_AMOUNT_NIGHT / I2R(REGEN_TICK)
        set intervalResp                    = GTimer.register(REGEN_TICK, function thistype.onUnitRecover)
        call UnitAuxHandler.ON_LOAD.register(function thistype.onTentLoad)
        call UnitAuxHandler.ON_UNLOAD.register(function thistype.onTentUnload)
    endmethod
endstruct

endscope
//  ======================================================================

endscope