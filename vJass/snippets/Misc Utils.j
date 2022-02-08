library MiscUtils requires /*
    
    ----------------------------------
    */  GTimer, ListT, Alloc, Init  /*
    ----------------------------------

    --------------------------------
    */  BezierEasing, Flagbits    /*
    --------------------------------
*/

//  a -> Starting point
//  b -> End point
private function GetMedianValue takes real a, real b, real weight returns real
    return a*(1.0 - weight) + b*(weight)
endfunction

struct EffectVisibility extends array
    private static Table visCountMap    = 0
    private static Table visAlphaMap    = 0
    private static Table effectMap      = 0

    static method operator [] takes effect whichEffect returns thistype
        local integer id            = GetHandleId(whichEffect)
        set effectMap.effect[id]    = whichEffect
        return id
    endmethod

    method operator visible takes nothing returns boolean
        return visCountMap.integer[this] >= 0
    endmethod

    method operator visible= takes boolean flag returns nothing
        local integer incr                  = 1
        if (not flag) then
            set incr                        = -1
        endif
        set visCountMap.integer[this]       = visCountMap.integer[this] + incr
        if (visCountMap.integer[this] == 0) then
            if (not visAlphaMap.integer.has(this)) then
                set visAlphaMap.integer[this]   = 0xff
            endif
            call BlzSetSpecialEffectAlpha(effectMap.effect[this], visAlphaMap.integer[this])

        elseif (visCountMap.integer[this] == -1) then
            call BlzSetSpecialEffectAlpha(effectMap.effect[this], 0)
        endif
    endmethod

    method operator alpha takes nothing returns integer
        //  This always assumes that nothing else calls BlzSetSpecialEffectAlpha.
        if (not visAlphaMap.integer.has(this)) then
            set visAlphaMap.integer[this]   = 0xff
        endif
        return visAlphaMap.integer[this]
    endmethod

    method operator alpha= takes integer value returns nothing
        set visAlphaMap.integer[this]       = BlzBitAnd(value, 0xff)
        if (visCountMap.integer[this] >= 0) then
            call BlzSetSpecialEffectAlpha(effectMap.effect[this], visAlphaMap.integer[this])
        endif            
    endmethod

    static method clearInfo takes effect whichEffect returns nothing
        local thistype this = GetHandleId(whichEffect)
        if (effectMap.effect.has(this)) then
            call visCountMap.integer.remove(this)
            call visAlphaMap.integer.remove(this)
            call effectMap.effect.remove(this)
        endif
    endmethod

    private static method init takes nothing returns nothing
        set visCountMap                     = Table.create()
        set visAlphaMap                     = Table.create()
        set effectMap                       = Table.create()
    endmethod
    implement Init
endstruct

struct VisibilityManager extends array
    implement Alloc
    private static constant integer VISIBILITY_TICK = 5
    private static constant real    TICK_INTERVAL   = 1.0 / I2R(VISIBILITY_TICK)

    private static constant integer MASK_UNIT       = 1
    private static constant integer MASK_EFFECT     = 2

    private static EventResponder objectResp        = 0
    private static IntegerList objectList           = 0

    private IntegerListItem objectListPtr
    private integer         objectMask

    readonly unit           unit
    readonly effect         effect

    private integer         startVis
    private integer         endVis
    private integer         curTick
    private integer         maxTick
    private real            curProg
    private real            auxChange
    BezierEasing            easeMode

    //  ====================================================
    //              Cleanup.
    //  ====================================================
    private method destroy takes nothing returns nothing
        call objectList.erase(this.objectListPtr)
        set this.unit           = null
        set this.objectListPtr  = 0
        set this.startVis       = 0
        set this.endVis         = 0
        set this.curTick        = 0
        set this.curProg        = 0.0
        set this.auxChange      = 0.0
        set this.easeMode       = 0
        set this.maxTick        = 0
        set this.objectMask     = 0
        call this.deallocate()
    endmethod

    //  ====================================================
    //              Visibility changing function
    //  ====================================================
    private method changeVisibility takes real curValue, real prev returns nothing
        local real change           = GetMedianValue(this.startVis, this.endVis, curValue) - /*
                                   */ GetMedianValue(this.startVis, this.endVis, prev)
        local integer finalValue    = 0
        if (this.objectMask == MASK_UNIT) then
            set finalValue          = BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_ALPHA) + R2I(change)
            call SetUnitVertexColor(this.unit, /*
                                */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_RED), /*
                                */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_GREEN), /*
                                */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_BLUE), /*
                                */  finalValue)
            call BlzSetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_ALPHA, /*
                                    */  finalValue)
            set this.auxChange      = this.auxChange + (change - R2I(change))
            //  Compensate for any straggling changes.
            if (RAbsBJ(auxChange) > 1.0) then
                set finalValue      = finalValue + R2I(auxChange)
                call SetUnitVertexColor(this.unit, /*
                                    */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_RED), /*
                                    */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_GREEN), /*
                                    */  BlzGetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_BLUE), /*
                                    */  finalValue)
                call BlzSetUnitIntegerField(this.unit, UNIT_IF_TINTING_COLOR_ALPHA, /*
                                    */  finalValue)
                set this.auxChange  = this.auxChange - R2I(this.auxChange)
            endif
        
        elseif (this.objectMask == MASK_EFFECT) then
            set this.auxChange                      = this.auxChange + (change - R2I(change))
            set finalValue                          = EffectVisibility[this.effect].alpha + R2I(change) + R2I(this.auxChange)
            set EffectVisibility[this.effect].alpha = finalValue
            if (RAbsBJ(auxChange) > 1.0) then
                set this.auxChange                  = this.auxChange - R2I(this.auxChange)
            endif
        endif
        set this.curProg            = curValue
    endmethod

    private static method onVisChange takes nothing returns nothing
        local IntegerListItem iter  = objectList.first
        local thistype this         = iter.data
        loop
            exitwhen iter == 0
            set iter            = iter.next
            //  Fill Contents here
            //  ==================================
            set this.curTick    = this.curTick + 1
            call this.changeVisibility(this.easeMode[I2R(this.curTick) / I2R(this.maxTick)], /*
                                    */ this.curProg)
            if (this.curTick >= this.maxTick) then
                call this.destroy()
            endif
            //  ==================================
            set this            = iter.data
        endloop
        if (objectList.empty()) then
            call GTimer[VISIBILITY_TICK].releaseCallback(objectResp)
        endif
    endmethod

    //  ====================================================
    //              Public API
    //  ====================================================
    private method objectPush takes nothing returns nothing
        set this.objectListPtr  = objectList.push(this).last
        if (objectList.size() == 1) then
            call GTimer[VISIBILITY_TICK].requestCallback(objectResp)
        endif
    endmethod

    static method unitApply takes unit whichUnit, integer start, integer finish, real dur returns nothing
        local thistype this     = thistype.allocate()
        set this.unit           = whichUnit
        set this.startVis       = start
        set this.endVis         = finish
        set this.curTick        = 0
        set this.curProg        = 0.0
        set this.easeMode       = BezierEase.linear
        set this.maxTick        = IMaxBJ(R2I(dur / TICK_INTERVAL + 0.50), 1)
        set this.objectMask     = MASK_UNIT
        call this.objectPush()
    endmethod

    static method effectApply takes effect whichEffect, integer start, integer finish, real dur returns nothing
        local thistype this     = thistype.allocate()
        set this.effect         = whichEffect
        set this.startVis       = start
        set this.endVis         = finish
        set this.curTick        = 0
        set this.curProg        = 0.0
        set this.easeMode       = BezierEase.linear
        set this.maxTick        = IMaxBJ(R2I(dur / TICK_INTERVAL + 0.50), 1)
        set this.objectMask     = MASK_EFFECT
        call this.objectPush()
    endmethod

    //  ====================================================
    //              Initialization Function
    //  ====================================================
    private static method init takes nothing returns nothing
        set objectList  = IntegerList.create()
        set objectResp  = GTimer.register(VISIBILITY_TICK, function thistype.onVisChange)
    endmethod
    implement Init
endstruct

struct UnitAbilityAction extends array
    implement Alloc

    private static constant integer MASK_DISABLE    = 1
    private static constant integer MASK_REMOVE     = 2
    private integer mask

    private unit    unit
    private integer abilID
    private boolean flag

    private static method onUnapply takes nothing returns nothing
        local thistype this = ReleaseTimer(GetExpiredTimer())
        if (this.mask == MASK_DISABLE) then
            call BlzUnitDisableAbility(this.unit, this.abilID, this.flag, this.flag)

        elseif (this.mask == MASK_REMOVE) then
            if (this.flag) then
                call UnitAddAbility(this.unit, this.abilID)
            else
                call UnitRemoveAbility(this.unit, this.abilID)
            endif
        endif
        call this.deallocate()
    endmethod
        
    static method applyEx takes unit whichUnit, integer abilID, real dur, boolean flag returns nothing
        local thistype this = thistype.allocate()
        set this.unit       = whichUnit
        set this.abilID     = abilID
        set this.flag       = flag
        set this.mask       = MASK_DISABLE
        call TimerStart(NewTimerEx(this), dur, false, function thistype.onUnapply)
    endmethod

    static method addEx takes unit whichUnit, integer abilID, real dur, boolean flag returns nothing
        local thistype this = thistype.allocate()
        set this.unit       = whichUnit
        set this.abilID     = abilID
        set this.flag       = flag
        set this.mask       = MASK_REMOVE
        call TimerStart(NewTimerEx(this), dur, false, function thistype.onUnapply)
    endmethod
endstruct

function UnitDisableAbilityTimed takes unit whichUnit, integer abilID, real dur returns nothing
    call UnitAbilityAction.applyEx(whichUnit, abilID, dur, true)
endfunction
function UnitEnableAbilityTimed takes unit whichUnit, integer abilID, real dur returns nothing
    call UnitAbilityAction.applyEx(whichUnit, abilID, dur, false)
endfunction
function UnitAddAbilityTimed takes unit whichUnit, integer abilID, real dur returns nothing
    call UnitAbilityAction.addEx(whichUnit, abilID, dur, true)
endfunction
function UnitRemoveAbilityTimed takes unit whichUnit, integer abilID, real dur returns nothing
    call UnitAbilityAction.addEx(whichUnit, abilID, dur, false)
endfunction

endlibrary