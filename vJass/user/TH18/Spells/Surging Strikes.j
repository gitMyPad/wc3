scope SurgingStrikes

//  Hehe, Surging Strikes go brrr...
private module SurgingStrikesConfig
    static constant method operator CARGO_HOLD_ID takes nothing returns integer
        return 'SPAS'
    endmethod
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A003'
    endmethod
    static constant method operator STRIKE_COUNT takes nothing returns integer
        return 3
    endmethod
    //  The base timeframe from which the delay will be considered is at the 
    //  moment when the unit get launched from it's original position.
    static constant method operator STRIKE_DAMAGE_DELAY takes nothing returns real
        return 0.15
    endmethod
    static constant method operator STRIKE_SPEED takes nothing returns real
        return 900.0
    endmethod
    static constant method operator STRIKE_OFFSET_DIST takes nothing returns real
        return 150.0
    endmethod
    static constant method operator STRIKE_ATTACK_TYPE takes nothing returns attacktype
        return ATTACK_TYPE_MELEE
    endmethod
    static constant method operator STRIKE_DAMAGE_TYPE takes nothing returns damagetype
        return DAMAGE_TYPE_NORMAL
    endmethod
    static constant method operator STRIKE_WEAPON_TYPE takes nothing returns weapontype
        return WEAPON_TYPE_METAL_LIGHT_SLICE
    endmethod
    static constant method operator STRIKE_ATTACK_INDEX takes nothing returns integer
        return 0
    endmethod
    static constant method operator STRIKE_ANIM_INDEX takes nothing returns integer
        return 8
    endmethod
    static constant method operator STRIKE_ANIM_SPEED_FACTOR takes nothing returns real
        return 3.0
    endmethod
    static method CRIT_RATIO takes integer level returns real
        return 0.5*(level + 2)
    endmethod
    static constant method operator CRIT_TEXT_COLOR takes nothing returns integer
        return 0xffc000ff
    endmethod
    static constant method operator MAX_DAMAGE_WEIGHT takes nothing returns real
        return 5.0
    endmethod
    static constant method operator CRIT_MODEL takes nothing returns string
        return "Abilities\\Weapons\\WaterElementalMissile\\WaterElementalMissile.mdl"
    endmethod
    static method CRIT_MODEL_ATTACH takes integer index returns string
        if (index == 1) then
            return "left hand"
        elseif (index == 2) then
            return "right hand"
        endif
        return ""
    endmethod
    static method filterTarget takes unit source, unit target returns boolean
        return UnitAlive(target) and /*
            */ IsUnitEnemy(target, GetOwningPlayer(source)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_FLYING))
    endmethod
endmodule

private struct SurgingStrikesData extends array
    implement SurgingStrikesConfig
endstruct

private struct SurgingStrikesAction extends array
    integer strikeCount
    unit    strikeTarget

    effect rightHandFX
    effect leftHandFX

    static method FLAGSET takes nothing returns integer
        return ObjectMovement.FLAG_DESTROY_ON_TARGET_DEATH + /*
            */ ObjectMovement.FLAG_DESTROY_ON_TARGET_REMOVE + /*
            */ ObjectMovement.FLAG_DESTROY_ON_OBJECT_DEATH + /*
            */ ObjectMovement.FLAG_STOP_ON_UNIT_ROOT
    endmethod

    static method setProjectedTarget takes ObjectMovement move, unit target returns nothing
        local real cx                               = GetUnitX(move.unit)
        local real cy                               = GetUnitY(move.unit)
        local real tx                               = GetUnitX(target)
        local real ty                               = GetUnitY(target)
        local real rad                              = Atan2(ty - cy, tx - cx)
        set tx                                      = tx + SurgingStrikesData.STRIKE_OFFSET_DIST * Cos(rad)
        set ty                                      = ty + SurgingStrikesData.STRIKE_OFFSET_DIST * Sin(rad)
        call SetUnitFacing(move.unit, rad * bj_RADTODEG)
        call move.setTargetAreaXY(tx, ty)
    endmethod

    private method presentDamage takes unit source, unit target, real baseDmg returns nothing
        local texttag tag           = null
        local integer red           = (BlzBitAnd(SurgingStrikesData.CRIT_TEXT_COLOR / 0x10000, 0xff) )
        local integer green         = (BlzBitAnd(SurgingStrikesData.CRIT_TEXT_COLOR / 0x100, 0xff) )
        local integer blue          = (BlzBitAnd(SurgingStrikesData.CRIT_TEXT_COLOR, 0xff))
        local integer alpha         = 0
        //  First bit is 1.
        if (SurgingStrikesData.CRIT_TEXT_COLOR < 0) then
            set alpha               = 0x80 + (BlzBitAnd((SurgingStrikesData.CRIT_TEXT_COLOR - 0x80000000) / 0x1000000, 0xff))
        else
            set alpha               = (BlzBitAnd((SurgingStrikesData.CRIT_TEXT_COLOR) / 0x1000000, 0xff))
        endif
        set tag                     = CreateTextTag()
        call SetTextTagColor(tag, red, green, blue, alpha)
        call SetTextTagText(tag, I2S(R2I(baseDmg)) + "!", TextTagSize2Height(11.5))
        call SetTextTagPosUnit(tag, target, 75.0 / SurgingStrikesData.STRIKE_COUNT * this.strikeCount)
        call SetTextTagPermanent(tag, false)
        call SetTextTagLifespan(tag, 2.0)
        call SetTextTagFadepoint(tag, 1.4)
        call SetTextTagVelocityBJ(tag, 80.0, 90.0)
        //  Manage visibility
        //  Only the owners of the attacker and the target
        //  can see the text tag.
        if ((GetLocalPlayer() != GetOwningPlayer(source)) and /*
        */ (GetLocalPlayer() != GetOwningPlayer(target))) then
            call SetTextTagVisibility(tag, false)
        endif
    endmethod

    private static method onDamageTarget takes nothing returns nothing
        local thistype this         = ReleaseTimer(GetExpiredTimer())
        local ObjectMovement move   = ObjectMovement(this)
        local real baseDmg          = BlzGetUnitBaseDamage(move.unit, SurgingStrikesData.STRIKE_ATTACK_INDEX)
        local real roll             = GetRandomInt(1, BlzGetUnitDiceSides(move.unit, SurgingStrikesData.STRIKE_ATTACK_INDEX)) * BlzGetUnitDiceNumber(move.unit, SurgingStrikesData.STRIKE_ATTACK_INDEX)
        local integer level         = GetUnitAbilityLevel(move.unit, SurgingStrikesData.ABILITY_ID)
        //  Factor in the crit
        set baseDmg                 = (baseDmg + roll) * SurgingStrikesData.CRIT_RATIO(level)
        call UnitDamageTarget(move.unit, this.strikeTarget, baseDmg, true, false, SurgingStrikesData.STRIKE_ATTACK_TYPE, /*
                            */SurgingStrikesData.STRIKE_DAMAGE_TYPE, SurgingStrikesData.STRIKE_WEAPON_TYPE)
        call this.presentDamage(move.unit, this.strikeTarget, baseDmg)
    endmethod

    private static method onDest takes nothing returns nothing
        local thistype this         = thistype(ObjectMovement.current)
        call BlzPauseUnitEx(ObjectMovement.current.unit, false)
        call QueueUnitAnimation(ObjectMovement.current.unit, "stand")
        call SetUnitTimeScale(ObjectMovement.current.unit, 1.0)
        call DestroyEffect(this.rightHandFX)
        call DestroyEffect(this.leftHandFX)
        set this.strikeCount        = 0
        set this.strikeTarget       = null
        set this.rightHandFX        = null
        set this.leftHandFX         = null
    endmethod

    private static method onStop takes nothing returns nothing
        local thistype this         = thistype(ObjectMovement.current)
        set this.strikeCount        = this.strikeCount - 1
        if (this.strikeCount < 1) then
            call ObjectMovement.current.destroy()
            return
        endif
        set ObjectMovement.current.veloc  = SurgingStrikesData.STRIKE_SPEED
        call thistype.setProjectedTarget(ObjectMovement.current, this.strikeTarget)
        call ObjectMovement.current.launch()
    endmethod

    private static method onMove takes nothing returns nothing
        local thistype this         = thistype(ObjectMovement.current)
        if (not UnitAlive(this.strikeTarget)) then
            call ObjectMovement.current.destroy()
        endif
    endmethod
    private static method onLaunch takes nothing returns nothing
        local thistype this         = thistype(ObjectMovement.current)
        if (this.strikeCount == SurgingStrikesData.STRIKE_COUNT) then
            call BlzPauseUnitEx(ObjectMovement.current.unit, true)
            call SetUnitAnimationByIndex(ObjectMovement.current.unit, SurgingStrikesData.STRIKE_ANIM_INDEX)
            call SetUnitTimeScale(ObjectMovement.current.unit, SurgingStrikesData.STRIKE_ANIM_SPEED_FACTOR)
        endif
        call TimerStart(NewTimerEx(this), SurgingStrikesData.STRIKE_DAMAGE_DELAY, false, function thistype.onDamageTarget)
    endmethod

    implement ObjectMovementTemplate
endstruct

//  This will handle the event detection.
private struct SurgingStrikes extends array
    private static integer array queryProcCount
    private static unit array queryProcTarget

    private static method onAbilReset takes nothing returns nothing
        local unit dragon                   = GetUnitById(ReleaseTimer(GetExpiredTimer()))
        call BlzEndUnitAbilityCooldown(dragon, SurgingStrikesData.ABILITY_ID)
        set dragon                          = null
    endmethod

    private static method onAbilCooldown takes nothing returns nothing
        local integer id                    = GetUnitId(SpellHandler.unit)
        local ObjectMovement move           = 0
        local SurgingStrikesAction sMove    = 0
        call UnitRemoveAbility(SpellHandler.unit, SurgingStrikesData.CARGO_HOLD_ID)
        if (queryProcTarget[id] == null) then
            //  Invalid target
            call TimerStart(NewTimerEx(id), 0.00, false, function thistype.onAbilReset)
            return
        endif

        set move                = SurgingStrikesAction.applyUnitMovement(SpellHandler.unit)
        set move.veloc          = SurgingStrikesData.STRIKE_SPEED
        set sMove               = SurgingStrikesAction(move)
        set sMove.strikeCount   = SurgingStrikesData.STRIKE_COUNT
        set sMove.strikeTarget  = queryProcTarget[id]
        set sMove.rightHandFX   = AddSpecialEffectTarget(SurgingStrikesData.CRIT_MODEL, /*
                                                          */ SpellHandler.unit, SurgingStrikesData.CRIT_MODEL_ATTACH(1))
        set sMove.leftHandFX    = AddSpecialEffectTarget(SurgingStrikesData.CRIT_MODEL, /*
                                                          */ SpellHandler.unit, SurgingStrikesData.CRIT_MODEL_ATTACH(2))
        call SurgingStrikesAction.setProjectedTarget(move, queryProcTarget[id])
        call move.launch()

        set queryProcCount[id]  = 0
        set queryProcTarget[id] = null
    endmethod
    private static method procPassiveCooldown takes unit source, unit target, integer id returns nothing
        //  Might revamp this later on. For now, go with hard-coded behavior.
        set queryProcCount[id]  = queryProcCount[id] + 1
        set queryProcTarget[id] = target
        if UnitAddAbility(source, SurgingStrikesData.CARGO_HOLD_ID) then
            call UnitMakeAbilityPermanent(source, true, SurgingStrikesData.CARGO_HOLD_ID)
        endif
    endmethod

    private static method onAttackLaunched takes nothing returns nothing
        local unit attacker     = GetAttacker()
        local unit target       = GetTriggerUnit()
        local integer atkID     = GetUnitId(attacker)
        //  Insert tech requirement check later.

        //  Check if attacker has the ability,
        //  if the target is valid, and if
        //  the ability is not on cooldown.
        if (GetUnitAbilityLevel(attacker, SurgingStrikesData.ABILITY_ID) == 0) or /*
        */ (not SurgingStrikesData.filterTarget(attacker, target)) or /*
        */ (BlzGetUnitAbilityCooldownRemaining(attacker, SurgingStrikesData.ABILITY_ID) != 0.0) or /*
        */ (queryProcCount[atkID] != 0) then
            set target      = null
            set attacker    = null
            return
        endif
        call thistype.procPassiveCooldown(attacker, target, atkID)
        set target      = null
        set attacker    = null
    endmethod

    private static method onInit takes nothing returns nothing
        local trigger trig  = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(trig, EVENT_PLAYER_UNIT_ATTACKED)
        call TriggerAddCondition(trig, Condition(function thistype.onAttackLaunched))
        call SpellHandler.register(EVENT_ENDCAST, SurgingStrikesData.ABILITY_ID, function thistype.onAbilCooldown)
    endmethod
endstruct

endscope