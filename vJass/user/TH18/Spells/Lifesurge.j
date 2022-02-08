scope Lifesurge

//  TO-DO: Create an energy missile that goes back and forth from the caster's position
//  to the target area.
private module LifesurgeConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00S'
    endmethod
    static method PULSE_DAMAGE_HEAL_FACTOR takes integer level returns real
        return 0.05*level
    endmethod
    static constant method operator PULSE_TIME takes nothing returns real
        return 0.75
    endmethod
    static constant method operator PULSE_SPEED takes nothing returns real
        return 500.0
    endmethod
    static constant method operator PULSE_MODEL takes nothing returns string
        return "Custom\\Model\\Effect\\Radiance Nature.mdx"
    endmethod
    static constant method operator PULSE_HEAL_MODEL takes nothing returns string
        return "Abilities\\Spells\\Human\\Heal\\HealTarget.mdl"
    endmethod
    static constant method operator PULSE_HARM_MODEL takes nothing returns string
        return "Abilities\\Spells\\NightElf\\Barkskin\\BarkSkinTarget.mdl"
    endmethod
    static constant method operator PULSE_MODEL_SCALE takes nothing returns real
        return 2.0
    endmethod
    static constant method operator PULSE_MODEL_HEIGHT takes nothing returns real
        return 200.0
    endmethod
    static method PULSE_DAMAGE takes integer level returns real
        return 20.0*((level - 1)*(level) + 2)
    endmethod
    static method PULSE_HEAL takes integer level returns real
        return 10.0*((level - 1)*(level) + 2)
    endmethod
    static method PULSE_AOE_EFFECT takes integer level returns real
        return 150.0
    endmethod
    static constant method operator PULSE_ATTACK_TYPE takes nothing returns attacktype
        return ATTACK_TYPE_NORMAL
    endmethod
    static constant method operator PULSE_DAMAGE_TYPE takes nothing returns damagetype
        return DAMAGE_TYPE_PLANT
    endmethod
    static constant method operator PULSE_WEAPON_TYPE takes nothing returns weapontype
        return null
    endmethod
    static method filterEnemy takes unit source, unit target returns boolean
        return (UnitAlive(target)) and /*
            */ (IsUnitEnemy(target, GetOwningPlayer(source))) and /*
            */ (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MECHANICAL)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_FLYING))
    endmethod
    static method filterAlly takes unit source, unit target returns boolean
        return (UnitAlive(target)) and /*
            */ (IsUnitAlly(target, GetOwningPlayer(source))) and /*
            */ (not IsUnitType(target, UNIT_TYPE_STRUCTURE)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_MECHANICAL)) and /*
            */ (not IsUnitType(target, UNIT_TYPE_FLYING)) and /*
            */ (GetPlayerAlliance(GetOwningPlayer(source), GetOwningPlayer(target), ALLIANCE_SHARED_SPELLS))
    endmethod
    static method printTextTag takes unit source, real amount returns nothing
        local texttag tag   = CreateTextTag()
        call SetTextTagPermanent(tag, false)
        call SetTextTagLifespan(tag, 2.5)
        call SetTextTagFadepoint(tag, 1.75)
        call SetTextTagText(tag, "+ " + I2S(R2I(amount)), TextTagSize2Height(10.5))
        call SetTextTagVelocity(tag, 0.0, TextTagSpeed2Velocity(80.0))
        call SetTextTagColor(tag, 0x40, 0xff, 0x40, 0xff)
        call SetTextTagVisibility(tag, GetOwningPlayer(source) == GetLocalPlayer())
        call SetTextTagPosUnit(tag, source, 30.0)
        set tag             = null
    endmethod
endmodule

private struct Lifesurge extends array
    implement LifesurgeConfig

    private static  constant        integer     PHASE_OUTGOING  = 1
    private static  constant        integer     PHASE_INCOMING  = 2
    
    private static  BezierEasing    bezierIn                    = 0
    private static  BezierEasing    bezierOut                   = 0
    private static  group           tempGroup                   = null
    private group   filterGroup
    private integer phase
    private integer level
    private unit    source
    private real    damage

    private static method FLAGSET takes nothing returns integer
        return ObjectMovement.FLAG_NO_TARGET_ON_STOP + ObjectMovement.FLAG_DESTROY_ON_TARGET_DEATH + /*
            */ ObjectMovement.FLAG_DESTROY_ON_TARGET_REMOVE
    endmethod

    private static method operator current takes nothing returns thistype
        return ObjectMovement.current
    endmethod

    private static method onDest takes nothing returns nothing
        local ObjectMovement object = ObjectMovement.current
        local thistype this         = object

        call DestroyGroup(this.filterGroup)
        set this.source             = null
        set this.filterGroup        = null
        set this.phase              = 0
        set this.level              = 0
        set this.damage             = 0.0
    endmethod

    private static method onStop takes nothing returns nothing
        local ObjectMovement object = ObjectMovement.current
        local thistype this         = object
        local real healAmount       = 0.0

        if (this.phase == PHASE_OUTGOING) then
            set this.phase          = PHASE_INCOMING
            call GroupClear(this.filterGroup)

            set object.veloc        = 0.0
            set object.easeMode     = bezierOut
            call object.setTargetUnitOffset(this.source, PULSE_MODEL_HEIGHT)
            call object.launch()
            set object.veloc        = object.time2Veloc(PULSE_TIME)

        elseif (this.phase == PHASE_INCOMING) then
            set healAmount          = PULSE_HEAL(this.level) + this.damage * PULSE_DAMAGE_HEAL_FACTOR(this.level)
            call SetWidgetLife(this.source, GetWidgetLife(this.source) + healAmount)
            call DestroyEffect(AddSpecialEffectTarget(PULSE_HEAL_MODEL, this.source, "chest"))
            call thistype.printTextTag(this.source, healAmount)
            call object.destroy()
        endif
    endmethod

    private static method onMove takes nothing returns nothing
        local ObjectMovement object = ObjectMovement.current
        local thistype this         = object
        local real cx               = BlzGetLocalSpecialEffectX(object.effect)
        local real cy               = BlzGetLocalSpecialEffectY(object.effect)
        local real prev             = 0.0
        local unit targ
        //  Filter targets
        call GroupEnumUnitsInRange(tempGroup, cx, cy, PULSE_AOE_EFFECT(this.level), null)
        loop
            set targ                = FirstOfGroup(tempGroup)
            call GroupRemoveUnit(tempGroup, targ)
            exitwhen (targ == null)
            loop
                exitwhen (targ == this.source) or (IsUnitInGroup(targ, this.filterGroup))
                if thistype.filterEnemy(this.source, targ) then
                    set prev        = GetWidgetLife(targ)
                    call AddSpecialEffectTargetTimed(PULSE_HARM_MODEL, targ, "chest", 3.0)
                    call UnitDamageTarget(this.source, targ, PULSE_DAMAGE(this.level), false, /*
                                       */ true, PULSE_ATTACK_TYPE, PULSE_DAMAGE_TYPE, PULSE_WEAPON_TYPE)
                    set this.damage = this.damage + (prev - GetWidgetLife(targ))
                    call GroupAddUnit(this.filterGroup, targ)

                elseif thistype.filterAlly(this.source, targ) then
                    call AddSpecialEffectTargetTimed(PULSE_HEAL_MODEL, targ, "chest", 1.0)
                    call SetWidgetLife(targ, GetWidgetLife(targ) + PULSE_HEAL(this.level))
                    call GroupAddUnit(this.filterGroup, targ)
                endif
                exitwhen true
            endloop
        endloop
    endmethod

    private static method onSpellEffect takes nothing returns nothing
        local ObjectMovement object = thistype.applyCustomMovement(PULSE_MODEL, GetUnitX(SpellHandler.unit), GetUnitY(SpellHandler.unit))
        local thistype this         = thistype(object)
        set this.source             = SpellHandler.unit
        set this.phase              = PHASE_OUTGOING
        set this.level              = SpellHandler.current.curAbilityLevel
        set this.filterGroup        = CreateGroup()

        call SetSpecialEffectHeight(object.effect, PULSE_MODEL_HEIGHT)
        call BlzSetSpecialEffectMatrixScale(object.effect, PULSE_MODEL_SCALE, PULSE_MODEL_SCALE, PULSE_MODEL_SCALE)
        set object.veloc            = 0.0
        set object.easeMode         = bezierIn
        call object.setTargetArea(SpellHandler.current.curTargetX, SpellHandler.current.curTargetY, /*
                               */ PULSE_MODEL_HEIGHT)
        call object.launch()
        set object.veloc            = object.time2Veloc(PULSE_TIME)
    endmethod

     private static method onInit takes nothing returns nothing
        set tempGroup               = CreateGroup()
        set bezierIn                = BezierEase.inOutSine
        set bezierOut               = BezierEase.inOutSine
        call SpellHandler.register(EVENT_EFFECT, ABILITY_ID, function thistype.onSpellEffect)
    endmethod
    implement ObjectMovementTemplate
endstruct

endscope