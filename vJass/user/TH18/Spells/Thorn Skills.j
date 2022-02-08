scope ThornSkills

private module PrisonOfThornsConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00R'
    endmethod
    static constant method operator ORDER_ID takes nothing returns integer
        return 852171
    endmethod
    static constant method operator RECYCLE_DELAY takes nothing returns real
        //  Keep this above 1.5 at the very least
        return 2.0
    endmethod
    static method filterTarget takes unit source, unit target returns boolean
        return (UnitAlive(target)) and /*
            */ (IsUnitEnemy(target, GetOwningPlayer(source))) and /*
            */ (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MECHANICAL)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_FLYING)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE)) and /*
            */ (not UnitIsSleeping(target))
    endmethod
endmodule
//  ======================================
//      GrassyGlide Config
//  ======================================
private module GrassyGlideConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00Q'
    endmethod
    static constant method operator THORNS_MODEL takes nothing returns string
        return "Abilities\\Spells\\NightElf\\EntanglingRoots\\EntanglingRootsTarget.mdl"
    endmethod
    //  Additional scalar multiplier.
    static constant method operator THORNS_SCALE_Z takes nothing returns real
        return 1.67
    endmethod
    static constant method operator THORNS_SCALE takes nothing returns real
        return 3.0
    endmethod
    static constant method operator THORNS_MODEL_LIFETIME takes nothing returns real
        return 3.0
    endmethod

    static method CASTER_AOE_RADIUS takes integer level returns real
        return 250.0
    endmethod
    static method TARGET_AOE_RADIUS takes integer level returns real
        return 250.0
    endmethod
    static constant method operator AOE_EFFECT_DELAY takes nothing returns real
        return 0.5
    endmethod
    static constant method operator BLINK_DELAY takes nothing returns real
        return 1.0
    endmethod
endmodule

//  ======================================
//      Deadly Thorns Config
//  ======================================
private module DeadlyThornsConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00T'
    endmethod
    static constant method operator GLIDE_ID takes nothing returns integer
        return 'A00Q'
    endmethod
    static method ROOT_CHANCE takes integer level returns integer
        return 5*((level - 1)*level + 2) / 2
    endmethod
endmodule

//  ================================================================
//                          Prison of Thorns
//  ================================================================
private struct PrisonOfThorns extends array
    implement PrisonOfThornsConfig

    private static group    tempGroup               = null

    //  ======================================================
    //              Dummy actions
    //  ======================================================
    private static method onDummyCleanup takes nothing returns nothing
        local Dummy dummy       = Dummy.current
        call dummy.disableAbil('Aatk', false, false)
        call dummy.removeAbil(ABILITY_ID)
    endmethod

    static method attemptRootArea takes unit source, real cx, real cy, real r, integer level returns nothing
        local Dummy dummy       = Dummy.request(GetOwningPlayer(source), cx, cy, 0.0)
        local unit targ
        local real maxRecycle   = 0.0
        local ability abil      

        if (level <= 0) then
            call dummy.recycle()
            return
        endif
        call dummy.disableAbil('Aatk', true, true)
        call dummy.addAbil(ABILITY_ID)
        call dummy.setAbilLvl(ABILITY_ID, level)

        //  Get the maximum duration of the ability.
        set abil                = BlzGetUnitAbility(dummy.dummy, ABILITY_ID)
        set maxRecycle          = RMaxBJ(BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1), /*
                                      */ BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)) + RECYCLE_DELAY
        call GroupEnumUnitsInRange(tempGroup, cx, cy, r, null)
        loop
            set targ            = FirstOfGroup(tempGroup)
            exitwhen (targ == null)
            call GroupRemoveUnit(tempGroup, targ)
            loop
                exitwhen (targ == source) or (not thistype.filterTarget(source, targ))
                set dummy.x     = GetUnitX(targ)
                set dummy.y     = GetUnitY(targ)
                call dummy.issueTargetOrderId(ORDER_ID, targ)
                exitwhen true
            endloop
        endloop
        call dummy.recycleTimed(maxRecycle, function thistype.onDummyCleanup)
        set abil                = null
        set targ                = null
    endmethod

    static method attemptRoot takes unit source, unit target, integer level returns nothing
        local Dummy dummy       = Dummy.request(GetOwningPlayer(source), GetUnitX(target), GetUnitY(target), 0.0)
        local real maxRecycle   = 0.0
        local ability abil      

        if (level <= 0) then
            call dummy.recycle()
            return
        endif
        call dummy.disableAbil('Aatk', true, true)
        call dummy.addAbil(ABILITY_ID)
        call dummy.setAbilLvl(ABILITY_ID, level)

        //  Get the maximum duration of the ability.
        set abil                = BlzGetUnitAbility(dummy.dummy, ABILITY_ID)
        set maxRecycle          = RMaxBJ(BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_NORMAL, level - 1), /*
                                      */ BlzGetAbilityRealLevelField(abil, ABILITY_RLF_DURATION_HERO, level - 1)) + RECYCLE_DELAY
        call dummy.issueTargetOrderId(ORDER_ID, target)
        call dummy.recycleTimed(maxRecycle, function thistype.onDummyCleanup)
        set abil                = null
    endmethod

    private static method init takes nothing returns nothing
        set tempGroup           = CreateGroup()
    endmethod
    implement Init
endstruct

//  ================================================================
//                          Grassy Glide
//  ================================================================
scope GrassyGlide

private struct GrassyGlideEffect
    private     boolean active

    readonly    timer   rootTimer
    readonly    timer   timer
    effect      fx

    unit        source
    integer     level
    integer     data
    real        cx
    real        cy
    real        radius

    method destroy takes nothing returns nothing
        if (not this.active) then
            return
        endif
        call ReleaseTimer(this.timer)
        call ReleaseTimer(this.rootTimer)
        call DestroyEffect(this.fx)
        set this.timer      = null
        set this.source     = null
        set this.fx         = null
        set this.active     = false
        set this.level      = 0
        set this.data       = 0
        set this.cx         = 0.0
        set this.cy         = 0.0
        call this.deallocate()
    endmethod

    private static method onRemoveFX takes nothing returns nothing
        call thistype(GetTimerData(GetExpiredTimer())).destroy()
    endmethod

    method start takes real dur returns nothing
        call TimerStart(this.timer, dur, false, function thistype.onRemoveFX)
    endmethod

    method configure takes unit source, real cx, real cy, real radius, integer level returns nothing
        set this.source     = source
        set this.cx         = cx
        set this.cy         = cy
        set this.radius     = radius
        set this.level      = level
    endmethod

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set this.active     = true
        set this.rootTimer  = NewTimerEx(this)
        set this.timer      = NewTimerEx(this)
        return this
    endmethod
endstruct

private struct GrassyGlide extends array
    implement GrassyGlideConfig

    private static constant integer STATE_CASTING   = 1
    private static constant integer STATE_EFFECT    = 2
    private static constant integer STATE_DONE      = 4

    private integer stateFlag
    private real cx
    private real cy
    private real tx
    private real ty

    private GrassyGlideEffect casterFx
    private GrassyGlideEffect targetFx
    private timer  delayTimer

    private method operator unit takes nothing returns unit
        return GetUnitById(this)
    endmethod

    private static method operator [] takes unit whichUnit returns thistype
        return GetUnitId(whichUnit)
    endmethod

    //  ======================================================
    //              Timer callback functions
    //  ======================================================
    private static method onCasterTeleport takes nothing returns nothing
        local thistype this     = ReleaseTimer(GetExpiredTimer())
        set this.stateFlag      = STATE_DONE
        set this.casterFx       = 0
        set this.targetFx       = 0
        call SetUnitX(this.unit, this.tx)
        call SetUnitY(this.unit, this.ty)
    endmethod

    private static method onCasterFxRoot takes nothing returns nothing
        local GrassyGlideEffect fx  = GetTimerData(GetExpiredTimer())
        local thistype this         = fx.data
        set this.casterFx           = 0
        call PrisonOfThorns.attemptRootArea(fx.source, fx.cx, fx.cy, fx.radius, fx.level)
    endmethod

    private static method onTargetFxRoot takes nothing returns nothing
        local GrassyGlideEffect fx  = GetTimerData(GetExpiredTimer())
        local thistype this         = fx.data
        set this.targetFx           = 0
        call PrisonOfThorns.attemptRootArea(fx.source, fx.cx, fx.cy, fx.radius, fx.level)
    endmethod
    //  ======================================================
    //              Event callback functions
    //  ======================================================
    private static method onSpellCast takes nothing returns nothing
        local thistype this     = thistype[SpellHandler.unit]
        local integer level     = SpellHandler[this.unit].curAbilityLevel
        set this.stateFlag      = STATE_CASTING
        set this.cx             = GetUnitX(SpellHandler.unit)
        set this.cy             = GetUnitY(SpellHandler.unit)
        set this.casterFx       = GrassyGlideEffect.create()
        set this.casterFx.data  = this
        set this.casterFx.fx    = AddSpecialEffect(THORNS_MODEL, this.cx, this.cy)
        call this.casterFx.start(THORNS_MODEL_LIFETIME)
        call this.casterFx.configure(SpellHandler.unit, this.cx, this.cy, CASTER_AOE_RADIUS(level), level)
        call TimerStart(this.casterFx.rootTimer, AOE_EFFECT_DELAY, false, function thistype.onCasterFxRoot)
        call BlzSetSpecialEffectMatrixScale(this.casterFx.fx, THORNS_SCALE, THORNS_SCALE, THORNS_SCALE*THORNS_SCALE_Z)
    endmethod

    private static method onSpellEffect takes nothing returns nothing
        local thistype this     = thistype[SpellHandler.unit]
        local integer level     = SpellHandler[this.unit].curAbilityLevel
        set this.stateFlag      = STATE_EFFECT
        set this.tx             = SpellHandler.current.curTargetX
        set this.ty             = SpellHandler.current.curTargetY
        set this.delayTimer     = NewTimerEx(this)
        set this.targetFx       = GrassyGlideEffect.create()
        set this.targetFx.data  = this
        set this.targetFx.fx    = AddSpecialEffect(THORNS_MODEL, this.tx, this.ty)
        call this.targetFx.start(THORNS_MODEL_LIFETIME)
        call this.targetFx.configure(SpellHandler.unit, this.tx, this.ty, TARGET_AOE_RADIUS(level), level)
        call TimerStart(this.targetFx.rootTimer, AOE_EFFECT_DELAY, false, function thistype.onTargetFxRoot)
        call BlzSetSpecialEffectMatrixScale(this.targetFx.fx, THORNS_SCALE, THORNS_SCALE, THORNS_SCALE*THORNS_SCALE_Z)
        call SetUnitX(SpellHandler.unit, this.cx)
        call SetUnitY(SpellHandler.unit, this.cy)
        
        call TimerStart(this.delayTimer, BLINK_DELAY, false, function thistype.onCasterTeleport)
    endmethod

    private static method onSpellEndcast takes nothing returns nothing
        local thistype this     = thistype[SpellHandler.unit]
        loop
            exitwhen (this.stateFlag == STATE_DONE)
            if (this.casterFx != 0) then
                call this.casterFx.destroy()
            endif
            if (this.targetFx != 0) then
                call this.targetFx.destroy()
            endif
            if (this.delayTimer != null) then
                call ReleaseTimer(this.delayTimer)
            endif
            exitwhen true
        endloop
        set this.stateFlag      = 0
        set this.tx             = 0.0
        set this.ty             = 0.0
        set this.cx             = 0.0
        set this.cy             = 0.0
        set this.casterFx       = 0
        set this.targetFx       = 0
        set this.delayTimer     = null
    endmethod

    //  ======================================================
    //              Initializer function
    //  ======================================================
    private static method onInit takes nothing returns nothing
        call SpellHandler.register(EVENT_CAST, ABILITY_ID, function thistype.onSpellCast)
        call SpellHandler.register(EVENT_EFFECT, ABILITY_ID, function thistype.onSpellEffect)
        call SpellHandler.register(EVENT_ENDCAST, ABILITY_ID, function thistype.onSpellEndcast)
    endmethod
endstruct

endscope

//  ================================================================
//                          Deadly Thorns
//  ================================================================
scope DeadlyThorns

private struct DeadlyThorns extends array
    implement DeadlyThornsConfig

    private static method onDamage takes nothing returns nothing
        local integer level = GetUnitAbilityLevel(DamageHandler.target, GLIDE_ID)
        if (GetUnitAbilityLevel(DamageHandler.target, ABILITY_ID) == 0) or /*
        */ (level == 0) or /*
        */ (not DamageHandler.isDamageAttack()) or /*
        */ (not DamageHandler.isDamageMelee()) or /*
        */ (not PrisonOfThorns.filterTarget(DamageHandler.target, DamageHandler.source)) or /*
        */ (GetRandomInt(1,100) > ROOT_CHANCE(level)) then
            return
        endif
        call PrisonOfThorns.attemptRoot(DamageHandler.target, DamageHandler.source, level)
    endmethod
    private static method onInit takes nothing returns nothing
        call DamageHandler.ON_DAMAGE.register(function thistype.onDamage)
    endmethod
endstruct

endscope
//  ================================================================
//                          Deadly Thorns End
//  ================================================================

endscope