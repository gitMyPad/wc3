scope Pluck

private module PluckConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00Z'
    endmethod
    static constant method operator PLUCK_DAMAGE takes nothing returns real
        return 30.0
    endmethod
    static constant method operator PLUCK_DIVE_TIME takes nothing returns real
        return 0.80
    endmethod
    static constant method operator PLUCK_VISION_FACTOR takes nothing returns real
        return 1.00
    endmethod
    static constant method operator ATTACK_TYPE takes nothing returns attacktype
        return ATTACK_TYPE_NORMAL
    endmethod
    static constant method operator DAMAGE_TYPE takes nothing returns damagetype
        return DAMAGE_TYPE_ENHANCED
    endmethod
    static constant method operator WEAPON_TYPE takes nothing returns weapontype
        return WEAPON_TYPE_WOOD_HEAVY_BASH
    endmethod
endmodule

private module PluckDebuffConfig
    readonly static integer array DISABLE_PASSIVE_ABIL
    readonly static integer passiveAbilCount        = 0
    static method DEBUFF_ABIL_ID takes nothing returns integer
        return 'A@02'
    endmethod
    static method DEBUFF_BUFF_ID takes nothing returns integer
        return 'B@01'
    endmethod
    static method DEBUFF_DURATION takes nothing returns real
        return 10.0
    endmethod
    static method DEBUFF_MODEL takes nothing returns string
        return "Custom\\Model\\Buff\\Pluck.mdx"
    endmethod
    static method DEBUFF_ATTACH takes nothing returns string
        return "overhead"
    endmethod
    static method BEHAVIOR_ID takes integer level returns integer
        return CustomBuff.BEHAVIOR_DISPELLABLE
    endmethod
    private static method getPassiveCount takes nothing returns nothing
        set passiveAbilCount        = 1
        loop
            exitwhen (DISABLE_PASSIVE_ABIL[passiveAbilCount + 1] == 0)
            set passiveAbilCount    = passiveAbilCount + 1
        endloop
    endmethod
    private static method onInit takes nothing returns nothing
        set DISABLE_PASSIVE_ABIL[1]     = 'Agyv'
        set DISABLE_PASSIVE_ABIL[2]     = 'Atru'
        set DISABLE_PASSIVE_ABIL[3]     = 'Adtg'
        set DISABLE_PASSIVE_ABIL[4]     = 'ANtr'
        set DISABLE_PASSIVE_ABIL[5]     = 'Adt1'
        set DISABLE_PASSIVE_ABIL[6]     = 'Aeye'
        set DISABLE_PASSIVE_ABIL[7]     = 'AOfs'
        set DISABLE_PASSIVE_ABIL[8]     = 'Afae'
        set DISABLE_PASSIVE_ABIL[9]     = 'Afa2'
        set DISABLE_PASSIVE_ABIL[10]    = 'ACff'
        set DISABLE_PASSIVE_ABIL[11]    = 'Adts'
        set DISABLE_PASSIVE_ABIL[12]    = 'A00Z'
        set DISABLE_PASSIVE_ABIL[13]    = 'Apiv'
        set DISABLE_PASSIVE_ABIL[14]    = 'A00K'
        set DISABLE_PASSIVE_ABIL[15]    = 'Aivs'
        set DISABLE_PASSIVE_ABIL[16]    = 'AOwk'
        set DISABLE_PASSIVE_ABIL[17]    = 'ANwk'
        set DISABLE_PASSIVE_ABIL[18]    = 'Ashm'
        set DISABLE_PASSIVE_ABIL[19]    = 'Sshm'
        set DISABLE_PASSIVE_ABIL[20]    = 'Ahid'
        set DISABLE_PASSIVE_ABIL[21]    = 'A00Y'
        call thistype.getPassiveCount()
    endmethod
endmodule

private struct PluckData extends array
    implement PluckConfig
endstruct

private struct PluckDebuff extends array
    implement PluckDebuffConfig
    private effect fx
    private CStat mod

    private static method onBuffRemove takes nothing returns nothing
        local integer i             = 1
        local thistype this         = Buff.current
        call this.mod.destroy()
        call DestroyEffect(this.fx)
        set this.fx                 = null
        set this.mod                = 0
        loop
            exitwhen (i > passiveAbilCount)
            call BlzUnitDisableAbility(Buff.current.unit, DISABLE_PASSIVE_ABIL[i], false, false)
            call BlzUnitHideAbility(Buff.current.unit, DISABLE_PASSIVE_ABIL[i], true)
            set i                   = i + 1
        endloop
    endmethod
    private static method onBuffAdd takes nothing returns nothing
        local integer i             = 1
        local thistype this         = Buff.current
        set this.fx                 = AddSpecialEffectTarget(DEBUFF_MODEL(), Buff.current.unit, DEBUFF_ATTACH())
        set this.mod                = UnitSightRangeStat.apply(Buff.current.unit, 1.0 - PluckData.PLUCK_VISION_FACTOR, STAT_MULT)
        loop
            exitwhen (i > passiveAbilCount)
            call BlzUnitDisableAbility(Buff.current.unit, DISABLE_PASSIVE_ABIL[i], true, true)
            call BlzUnitHideAbility(Buff.current.unit, DISABLE_PASSIVE_ABIL[i], false)
            set i                   = i + 1
        endloop
    endmethod
    implement CustomBuffHandler
endstruct

private struct Pluck extends array
    private static BezierEasing easeMode    = 0
    private static thistype array instancePtr
    private unit  target
    private timer onHitTimer

    private static method FLAGSET takes nothing returns integer
        return ObjectMovement.FLAG_DESTROY_ON_STOP + ObjectMovement.FLAG_DESTROY_ON_OBJECT_DEATH + ObjectMovement.FLAG_IGNORE_GROUND_PATHING
    endmethod

    private static method MISSILE_CURVE_NODES takes nothing returns integer
        return 4
    endmethod

    private static method onTimedHit takes nothing returns nothing
        local thistype this         = ReleaseTimer(GetExpiredTimer())
        local ObjectMovement object = ObjectMovement(this)
        set this.onHitTimer         = null
        if (not UnitDamageTarget(object.unit, this.target, PluckData.PLUCK_DAMAGE, true, false, /*
        */ PluckData.ATTACK_TYPE, PluckData.DAMAGE_TYPE, PluckData.WEAPON_TYPE)) then
            return
        endif
        call PluckDebuff.applyBuff(this.target, PluckDebuff.DEBUFF_DURATION())
    endmethod

    private static method onSpellEffect takes nothing returns nothing
        local ObjectMovement object                     = thistype.applyUnitMovement(SpellHandler.unit)
        local thistype this                             = thistype(object)
        set instancePtr[GetUnitId(SpellHandler.unit)]   = this
        set this.target                                 = SpellHandler.current.curTargetUnit
        set this.onHitTimer                             = NewTimerEx(this)
        set object.veloc                                = 1.0
        
        call TimerStart(this.onHitTimer, PluckData.PLUCK_DIVE_TIME * 0.5, false, function thistype.onTimedHit)
        call object.setTargetArea(GetUnitX(this.target), GetUnitY(this.target), GetUnitFlyHeight(this.target))
        call object.launch()
        
        set object.veloc                                = object.time2Veloc(PluckData.PLUCK_DIVE_TIME)
    endmethod

    private static method onSpellEndcast takes nothing returns nothing
        local thistype this                             = instancePtr[GetUnitId(SpellHandler.unit)]
        local ObjectMovement object                     = ObjectMovement(this)
        if (this == 0) then
            return
        endif
        set instancePtr[GetUnitId(SpellHandler.unit)]   = 0
        call object.stop()
    endmethod

    //  Cleanup here
    private static method onDest takes nothing returns nothing
        local ObjectMovement object = ObjectMovement.current
        local thistype this         = thistype(object)
        set this.target             = null
        if (this.onHitTimer != null) then
            call ReleaseTimer(this.onHitTimer)
        endif
        set this.onHitTimer         = null
    endmethod

    //  ================================================================================
    //                          Initializing functions
    //  ================================================================================
    private static method defineMissileCurve takes BezierCurve curvePath returns nothing
        set curvePath[1].x  = 1.4
        set curvePath[1].y  = 0.0
        set curvePath[1].z  = 0.5

        set curvePath[2].x  = 1.73
        set curvePath[2].y  = 1.73
        set curvePath[2].z  = 1.0

        set curvePath[3].x  = 0.0
        set curvePath[3].y  = 1.4
        set curvePath[3].z  = 0.5

        set curvePath[4].x  = 0.0
        set curvePath[4].y  = 0.0
        set curvePath[4].z  = 0.0
    endmethod

    private static method onInit takes nothing returns nothing
        call SpellHandler.register(EVENT_EFFECT, PluckData.ABILITY_ID, function thistype.onSpellEffect)
        call SpellHandler.register(EVENT_ENDCAST, PluckData.ABILITY_ID, function thistype.onSpellEndcast)
    endmethod
    implement ObjectMovementTemplate
endstruct

endscope