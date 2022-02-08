library DamageHandler requires /*

    ------------------
    */  UnitDex     /*
    ------------------

    ------------------
    */  Init        /*
    ------------------

    ---------------------------
    */  EventListener        /*
    ---------------------------

    ---------------------------
    */  Flagbits             /*
    ---------------------------

     -------------------------------------
    |
    |   DamageHandler   - vJASS
    |       v.1.1.0.0
    |
    |-------------------------------------
    |
    |   A library that handles the processing
    |   and modification of damage events.
    |
    |-------------------------------------
    |
    |   API
    |
    |-------------------------------------
    |
    |   class DamageHandler {
    |
    |   ------------------------------------------
    |   Event Hierarchy: (Highest to Lowest Order)
    |       All of the following events are members of the class.
    |
    |       - MODIFIER_SYSTEM       - (Will always run)
    |       - MODIFIER_OUTGOING     - (Runs on DAMAGING_EVENT)
    |       - MODIFIER_INCOMING     - (Runs on DAMAGED_EVENT)
    |       - ON_DAMAGE             - (Runs on DAMAGED_EVENT. Cannot modify dmg amount at this point.)
    |       - ON_LETHAL_DAMAGE      - (Runs on DAMAGED_EVENT. Sets the final health of the target if damage dealt will kill.)
    |       - AFTER_DAMAGE          - (Runs after DAMAGED_EVENT. Be careful with this event, though.)
    |   ------------------------------------------
    |
    |   ------------------------------------------
    |   Operators:
    |       static real dmg
    |           - The amount of damage dealt. Cannot be changed
    |             from an ON_DAMAGE event onwards.
    |
    |       static attacktype attacktype
    |       static damagetype damagetype
    |       static weapontype weapontype
    |           - The amount of damage dealt. Cannot be changed
    |             from a MODIFIER_INCOMING event onwards.
    |
    |       static integer dmgFlags
    |           - The flag mask of the damage instance. By
    |             changing this value, certain properties of
    |             the damage instance can be changed.
    |
    |       static real finalHP
    |           - The target's health after damage has been
    |             applied. Only meaningful in ON_LETHAL_DAMAGE.
    |
    |       readonly static unit source
    |       readonly static unit target
    |           - Damage source and target respectively.
    |
    |       readonly static unit pureDmg
    |           - Damage value before triggered modifications.
    |
    |       readonly static unit outgoingDmg
    |           - Damage value after triggered modifications, but before
    |             any game modifications.
    |
    |       readonly static unit incomingDmg
    |           - Immediate damage value after game modifications.
    |
    |       readonly static unit calcFactor
    |           - Ratio between incomingDmg and outgoingDmg
    |
    |   ------------------------------------------
    |
    |   ------------------------------------------
    |   Methods:
    |       static method isTriggeredDmg() -> bool
    |           - Returns true if damage is dealt via UnitDamageTarget.
    |
    |       static method isGameDmg() -> bool
    |           - Returns true if damage is dealt by the game.
    |             It assumes the first damage instance comes from
    |             the game.
    |
    |       static method isDamageAttack() -> bool
    |           - Returns true if damage came from an attack.
    |             (Primarily checked through the comparison
    |              pDamageTypeA[index] == DAMAGE_TYPE_NORMAL)
    |
    |       static method isDamagePhysical() -> bool
    |       static method isDamageMagical() -> bool
    |           - Pretty self-explanatory.
    |
    |        -------------------------------------
    |       |   Added in v.1.1.0.0
    |        -------------------------------------
    |       static method isDamageMelee() -> bool
    |           - Only sensible in direct attacks
    |           - Always returns false otherwise.
    |
    |       static method isDamageRanged() -> bool
    |           - Only sensible in direct attacks
    |           - Always returns true otherwise.
    |        -------------------------------------
    |
    |       static method isDamagePure() -> bool
    |           - Returns true if damage instance was applied
    |             via dealPureDamage(src, targ, amt)
    |
    |       static method setPureDamage(real value)
    |           - Changes the value of pure damage dealt.
    |           - Only works when damage instance is pure damage.
    |
    |       static method dealPureDamage(unit src, unit targ, real amt) -> bool
    |           - Deals a pure damage instance. Still fires damage handlers.
    |           - Returns the result from UnitDamageTarget.
    |
    |       static method dealSilentDamage(unit src, unit targ, real amt,
    |                                      bool isAtk, bool ranged, attacktype a,
    |                                      damagetype d, weapontype w) -> bool
    |           - Deals a damage instance that does not fire most damage handlers.
    |               - Callbacks registered to the MODIFIER_SYSTEM event will
    |                 still run with this type of damage instance.
    |   ------------------------------------------
    |   }
    |-------------------------------------
    |
    |   Event Registration:
    |
    |-------------------------------------
    |
    |   Copy the following line:
    |   - call DamageHandler.{YOUR_DESIRED_EVENT}.register({YOUR_CALLBACK})
    |       - See Event Hierarchy for the list of events.
    |       - YOUR_CALLBACK must be a function parameter
    |
     -------------------------------------
*/

native UnitAlive takes unit id returns boolean

private struct DamageType extends array
    readonly static constant integer PHYSICAL_DAMAGE    = 1
    readonly static constant integer MAGIC_DAMAGE       = 2
    readonly static constant integer UNIVERSAL_DAMAGE   = 4

    private static integer array damageType

    static method operator [] takes damagetype d returns integer
        return damageType[GetHandleId(d)]
    endmethod

    private static method init takes nothing returns nothing
        set damageType[0]   = UNIVERSAL_DAMAGE
        set damageType[24]  = UNIVERSAL_DAMAGE
        set damageType[26]  = UNIVERSAL_DAMAGE

        set damageType[8]   = MAGIC_DAMAGE
        set damageType[9]   = MAGIC_DAMAGE
        set damageType[10]  = MAGIC_DAMAGE
        set damageType[13]  = MAGIC_DAMAGE
        set damageType[14]  = MAGIC_DAMAGE
        set damageType[15]  = MAGIC_DAMAGE
        set damageType[17]  = MAGIC_DAMAGE
        set damageType[18]  = MAGIC_DAMAGE
        set damageType[19]  = MAGIC_DAMAGE
        set damageType[20]  = MAGIC_DAMAGE
        set damageType[21]  = MAGIC_DAMAGE
        set damageType[25]  = MAGIC_DAMAGE

        set damageType[4]   = PHYSICAL_DAMAGE
        set damageType[5]   = PHYSICAL_DAMAGE
        set damageType[11]  = PHYSICAL_DAMAGE
        set damageType[12]  = PHYSICAL_DAMAGE
        set damageType[16]  = PHYSICAL_DAMAGE
        set damageType[22]  = PHYSICAL_DAMAGE
        set damageType[23]  = PHYSICAL_DAMAGE
    endmethod
    implement Init
endstruct

private struct AttackType extends array
    readonly static constant integer NORMAL_DAMAGE  = 1
    readonly static constant integer SPELLS_DAMAGE  = 2
    readonly static constant integer MAGIC_DAMAGE   = 4

    private static integer array attackType

    static method operator [] takes attacktype a returns integer
        return attackType[GetHandleId(a)]
    endmethod
    
    private static method init takes nothing returns nothing
        set attackType[1]   = NORMAL_DAMAGE
        set attackType[2]   = NORMAL_DAMAGE
        set attackType[3]   = NORMAL_DAMAGE
        set attackType[5]   = NORMAL_DAMAGE
        set attackType[6]   = NORMAL_DAMAGE

        set attackType[0]   = SPELLS_DAMAGE

        set attackType[4]   = MAGIC_DAMAGE
    endmethod
    implement Init
endstruct

globals
    constant integer DAMAGE_FLAG_IS_ATTACK                  = 1
    constant integer DAMAGE_FLAG_IS_PHYSICAL                = 2
    constant integer DAMAGE_FLAG_IS_MAGICAL                 = 4
    constant integer DAMAGE_FLAG_IS_UNIVERSAL               = DAMAGE_FLAG_IS_PHYSICAL + DAMAGE_FLAG_IS_MAGICAL
    constant integer DAMAGE_FLAG_IS_GAME                    = 8
    constant integer DAMAGE_FLAG_IS_CODE                    = 0x10
    constant integer DAMAGE_FLAG_IS_MELEE                   = 0x20
    constant integer DAMAGE_FLAG_IS_PURE                    = 0x40      // When a damage instance has this flag, it will override wc3's damage calculations.
    constant integer DAMAGE_FLAG_OVERRIDE_PURE              = 0x80      // Tells the system that the amount of pure damage dealt can be changed. Will immediately be unflagged after changing the value of pure damage.
    constant integer DAMAGE_FLAG_USES_ARMOR                 = 0x100

    private constant integer DAMAGE_FLAG_LOCK_INFO          = 0x200     // Tells the system that the damagetype, weapontype or the attacktype of the damage instance cannot be changed.
    private constant integer DAMAGE_FLAG_SUPPRESS_EVENTS    = 0x400     // When a damage instance has this flag, it will not proc all events associated with damage detection (except system modifiers).
    private constant integer DAMAGE_FLAG_WILL_BE_CODE       = 0x800     // An anticipatory flag that tells the system that the next source of (recursive) damage is from triggers/code.
    private constant integer DAMAGE_FLAG_WILL_BE_GAME       = 0x1000    // An anticipatory flag that tells the system that the next source of (recursive) damage is from the game.
    private constant integer DAMAGE_FLAG_PHASE_OUTGOING     = 0x2000
    private constant integer DAMAGE_FLAG_PHASE_INCOMING     = 0x4000
    private constant integer DAMAGE_FLAG_PHASE_RECEIVED     = DAMAGE_FLAG_PHASE_OUTGOING + DAMAGE_FLAG_PHASE_INCOMING
    private constant integer DAMAGE_FLAG_LOCK_DAMAGE        = 0x8000    // Indicates that the damage observation phase has begun. One can no longer change the damage dealt directly.
endglobals

private struct DamageHandlerData extends array
endstruct

private module DamageHandlerEvents
    readonly static EventListener MODIFIER_SYSTEM   = 0
    readonly static EventListener MODIFIER_OUTGOING = 0
    readonly static EventListener MODIFIER_INCOMING = 0
    readonly static EventListener ON_DAMAGE         = 0
    readonly static EventListener ON_LETHAL_DAMAGE  = 0
    readonly static EventListener AFTER_DAMAGE      = 0

    private static method onInit takes nothing returns nothing
        set MODIFIER_SYSTEM     = EventListener.create()
        set MODIFIER_OUTGOING   = EventListener.create()
        set MODIFIER_INCOMING   = EventListener.create()
        set ON_DAMAGE           = EventListener.create()
        set ON_LETHAL_DAMAGE    = EventListener.create()
        set AFTER_DAMAGE        = EventListener.create()
        
        call MODIFIER_SYSTEM.setMaxRecursionDepth(MAX_RECURSION)
        call MODIFIER_OUTGOING.setMaxRecursionDepth(MAX_RECURSION)
        call MODIFIER_INCOMING.setMaxRecursionDepth(MAX_RECURSION)
        call ON_DAMAGE.setMaxRecursionDepth(MAX_RECURSION)
        call ON_LETHAL_DAMAGE.setMaxRecursionDepth(MAX_RECURSION)
        call AFTER_DAMAGE.setMaxRecursionDepth(MAX_RECURSION)

        call MODIFIER_SYSTEM.setMaxCallbackDepth(MAX_CALLBACK_DEPTH)
        call MODIFIER_OUTGOING.setMaxCallbackDepth(MAX_CALLBACK_DEPTH)
        call MODIFIER_INCOMING.setMaxCallbackDepth(MAX_CALLBACK_DEPTH)
        call ON_DAMAGE.setMaxCallbackDepth(MAX_CALLBACK_DEPTH)
        call ON_LETHAL_DAMAGE.setMaxRecursionDepth(MAX_CALLBACK_DEPTH)
        call AFTER_DAMAGE.setMaxCallbackDepth(MAX_CALLBACK_DEPTH)
    endmethod
endmodule
private module DamageHandlerOperators
    static method operator dmg takes nothing returns real
        return pDmgA[index]
    endmethod
    static method operator dmg= takes real newValue returns nothing
        //  If damage can no longer be changed, terminate immediately.
        if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_LOCK_DAMAGE) != 0) then
            return
        endif
        if ((BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_PURE) == 0) or /*
        */ (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_OVERRIDE_PURE) != 0)) then
            set pDmgA[index]        = newValue
            set dmgFlagsA[index]    = BlzBitAnd(dmgFlagsA[index], -DAMAGE_FLAG_OVERRIDE_PURE - 1)
            if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_PURE) != 0) then
                set pureDmgA[index]     = newValue
            endif
        endif
    endmethod

    static method operator attacktype takes nothing returns attacktype
        return pAttacktypeA[index]
    endmethod
    static method operator attacktype= takes attacktype newAtk returns nothing
        if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_LOCK_INFO + DAMAGE_FLAG_PHASE_INCOMING) != 0) then
            return
        endif
        set pAttacktypeA[index] = newAtk
    endmethod

    static method operator damagetype takes nothing returns damagetype
        return pDamagetypeA[index]
    endmethod
    static method operator damagetype= takes damagetype newDmg returns nothing
        local integer temp  = 0
        if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_LOCK_INFO + DAMAGE_FLAG_PHASE_INCOMING) != 0) then
            return
        endif
        set pDamagetypeA[index] = newDmg
        set dmgFlagsA[index]    = BlzBitAnd(dmgFlagsA[index], -DAMAGE_FLAG_IS_UNIVERSAL - 1)
        set temp                = DamageType[pDamagetypeA[index]]
        if (temp == DamageType.PHYSICAL_DAMAGE) then
            set temp            = DAMAGE_FLAG_IS_PHYSICAL
        elseif (temp == DamageType.MAGIC_DAMAGE) then
            set temp            = DAMAGE_FLAG_IS_MAGICAL
        elseif (temp == DamageType.UNIVERSAL_DAMAGE) then
            set temp            = DAMAGE_FLAG_IS_UNIVERSAL
        endif
        set dmgFlagsA[index]    = dmgFlagsA[index] + temp
    endmethod

    static method operator weapontype takes nothing returns weapontype
        return pWeapontypeA[index]
    endmethod
    static method operator weapontype= takes weapontype newWpn returns nothing
        if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_LOCK_INFO + DAMAGE_FLAG_PHASE_INCOMING) != 0) then
            return
        endif
        set pWeapontypeA[index] = newWpn
    endmethod

    static method operator dmgFlags takes nothing returns integer
        return dmgFlagsA[index]
    endmethod
    static method operator dmgFlags= takes integer x returns nothing
        set dmgFlagsA[index]    = x
    endmethod

    static method operator finalHP takes nothing returns real
        return pFinalHPA[index]
    endmethod
    static method operator finalHP= takes real x returns nothing
        set pFinalHPA[index]    = x
    endmethod

    static method operator source takes nothing returns unit
        return sourceA[index]
    endmethod
    static method operator target takes nothing returns unit
        return targetA[index]
    endmethod
    static method operator pureDmg takes nothing returns real
        return pureDmgA[index]
    endmethod
    static method operator outgoingDmg takes nothing returns real
        return outgoingDmgA[index]
    endmethod
    static method operator incomingDmg takes nothing returns real
        return incomingDmgA[index]
    endmethod
    static method operator calcFactor takes nothing returns real
        return calcFactorA[index]
    endmethod
endmodule

struct DamageHandler extends array
    private  static constant integer MAX_RECURSION      = 8
    private  static constant integer MAX_CALLBACK_DEPTH = 1
    private  static Table detectorMap                   = 0

    private  static code  onCleanupInstances            = null
    private  static code  onInflictDamage               = null
    private  static timer cleanupTimer                  = null
    private  static integer index                       = 0

    private  static unit array sourceA
    private  static unit array targetA
    private  static real array pureDmgA
    private  static real array outgoingDmgA
    private  static real array incomingDmgA
    private  static real array calcFactorA

    private  static real array pDmgA
    private  static real array pFinalHPA
    private  static attacktype array pAttacktypeA
    private  static damagetype array pDamagetypeA
    private  static weapontype array pWeapontypeA

    private  static integer array dmgFlagsA
    private  static trigger array detectorA
    
    private  static integer dreamFlags                  = DAMAGE_FLAG_WILL_BE_GAME         // Indicates several flags that tell the handler how to handle the next nested damage instance.

    implement DamageHandlerEvents
    implement DamageHandlerOperators

    //  =========================================================   //
    //                      Public API                              //
    //  =========================================================   //
    static method isTriggeredDmg takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_CODE) != 0
    endmethod
    static method isGameDmg takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_GAME) != 0
    endmethod
    static method isDamageAttack takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_ATTACK) != 0
    endmethod
    static method isDamagePhysical takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_PHYSICAL) != 0
    endmethod
    static method isDamageMagical takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_MAGICAL) != 0
    endmethod
    static method isDamagePure takes nothing returns boolean
        return BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_PURE) != 0
    endmethod
    static method isDamageMelee takes nothing returns boolean
        return (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_MELEE) != 0)
    endmethod
    static method isDamageRanged takes nothing returns boolean
        return (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_MELEE) == 0)
    endmethod
    static method setPureDamage takes real newValue returns nothing
        set dmgFlagsA[index]    = BlzBitOr(dmgFlagsA[index], DAMAGE_FLAG_OVERRIDE_PURE)
        set dmg                 = newValue
    endmethod
    static method dealPureDamage takes unit src, unit targ, real amt returns boolean
        local integer prevDream = dreamFlags
        local boolean result    = false
        set dreamFlags          = DAMAGE_FLAG_WILL_BE_CODE + DAMAGE_FLAG_IS_PURE + DAMAGE_FLAG_LOCK_INFO
        set result              = UnitDamageTarget(src, targ, amt, false, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_UNIVERSAL, null)
        set dreamFlags          = prevDream
        return result
    endmethod
    static method dealSilentDamage takes unit src, unit targ, real amt, boolean isAtk, boolean ranged, attacktype atk, damagetype dmg, weapontype wpn returns boolean
        local integer prevDream = dreamFlags
        local boolean result    = false
        set dreamFlags          = DAMAGE_FLAG_WILL_BE_CODE + DAMAGE_FLAG_LOCK_INFO + DAMAGE_FLAG_SUPPRESS_EVENTS
        set result              = UnitDamageTarget(src, targ, amt, isAtk, ranged, atk, dmg, wpn)
        set dreamFlags          = prevDream
        return result
    endmethod

    //  =============================================================   //
    //              Global State Managers                               //
    //  =============================================================   //
    private static method removeDamageInfoRaw takes integer i returns nothing
        set pDmgA[i]        = 0.0
        set pureDmgA[i]     = 0.0
        set outgoingDmgA[i] = 0.0
        set incomingDmgA[i] = 0.0
        set pFinalHPA[i]    = 0.0
        set sourceA[i]      = null
        set targetA[i]      = null
        set pDamagetypeA[i] = null
        set pAttacktypeA[i] = null
        set pWeapontypeA[i] = null
        set dmgFlagsA[i]    = 0
        if (detectorA[i] != null) then
            call detectorMap.integer.remove(GetHandleId(detectorA[i]))
            call DisableTrigger(detectorA[i])
            call DestroyTrigger(detectorA[i])
        endif
        set detectorA[i]    = null
    endmethod

    private static method removeDamageInfo takes integer i returns nothing
        if ((i > index) or (i <= 0)) then
            return
        endif
        call removeDamageInfoRaw(i)
    endmethod

    private static method pushDamageInfo takes nothing returns nothing
        local integer temp          = dreamFlags
        set index                   = index + 1
        set sourceA[index]          = GetEventDamageSource()
        set targetA[index]          = GetTriggerUnit()
        set pureDmgA[index]         = GetEventDamage()
        set pDmgA[index]            = pureDmgA[index]
        set outgoingDmgA[index]     = pureDmgA[index]
        set pDamagetypeA[index]     = BlzGetEventDamageType()
        set pAttacktypeA[index]     = BlzGetEventAttackType()
        set pWeapontypeA[index]     = BlzGetEventWeaponType()
        //  Determine the starting value for dmgFlagsA[index]
        if (BlzBitAnd(temp, DAMAGE_FLAG_WILL_BE_GAME) != 0) then
            set dmgFlagsA[index]    = DAMAGE_FLAG_WILL_BE_GAME + DAMAGE_FLAG_IS_GAME + DAMAGE_FLAG_PHASE_OUTGOING
        elseif (BlzBitAnd(temp, DAMAGE_FLAG_WILL_BE_CODE) != 0) then
            set dmgFlagsA[index]    = DAMAGE_FLAG_WILL_BE_CODE + DAMAGE_FLAG_IS_CODE + DAMAGE_FLAG_PHASE_OUTGOING
        endif
        //  Tick additional flags as needed.
        if (BlzBitAnd(temp, DAMAGE_FLAG_IS_PURE) != 0) then
            set dmgFlagsA[index]    = dmgFlagsA[index] + DAMAGE_FLAG_IS_PURE
        endif
        if (BlzBitAnd(temp, DAMAGE_FLAG_SUPPRESS_EVENTS) != 0) then
            set dmgFlagsA[index]    = dmgFlagsA[index] + DAMAGE_FLAG_SUPPRESS_EVENTS
        endif
        if (BlzBitAnd(temp, DAMAGE_FLAG_LOCK_INFO) != 0) then
            set dmgFlagsA[index]    = dmgFlagsA[index] + DAMAGE_FLAG_LOCK_INFO
        endif

        if (index == 1) then
            call TimerStart(cleanupTimer, 0.00, false, onCleanupInstances)
        endif
        //  Check if damage came from an attack.
        if (pDamagetypeA[index] == DAMAGE_TYPE_NORMAL) then
            set dmgFlagsA[index]    = dmgFlagsA[index] + DAMAGE_FLAG_IS_ATTACK + DAMAGE_FLAG_USES_ARMOR
        endif
        if (BlzBitAnd(dmgFlagsA[index], DAMAGE_FLAG_IS_ATTACK) != 0) and /*
        */ ((IsUnitType(sourceA[index], UNIT_TYPE_MELEE_ATTACKER)) and /*
        */ ((not IsUnitType(sourceA[index], UNIT_TYPE_RANGED_ATTACKER)) or /*
        */ (pWeapontypeA[index] != null))) then
            set dmgFlagsA[index]    = dmgFlagsA[index] + DAMAGE_FLAG_IS_MELEE
        endif

        //  Check if damage is either physical, magic, or universal.
        set temp    = DamageType[pDamagetypeA[index]]
        if (temp == DamageType.PHYSICAL_DAMAGE) then
            set temp    = DAMAGE_FLAG_IS_PHYSICAL
        elseif (temp == DamageType.MAGIC_DAMAGE) then
            set temp    = DAMAGE_FLAG_IS_MAGICAL
        elseif (temp == DamageType.UNIVERSAL_DAMAGE) then
            set temp    = DAMAGE_FLAG_IS_UNIVERSAL
        endif
        set dmgFlagsA[index]    = dmgFlagsA[index] + temp
    endmethod

    private static method popDamageInfo takes nothing returns nothing
        call removeDamageInfoRaw(index)
        if (index > 0) then
            set index   = index - 1
        endif
    endmethod

    //  =========================================================   //
    //              Cleanup Callback                                //
    //  =========================================================   //
    private static method onCleanup takes nothing returns nothing
        call PauseTimer(cleanupTimer)
        loop
            exitwhen index <= 0
            call popDamageInfo()
        endloop
    endmethod

    //  =========================================================   //
    //                      Event Handlers                          //
    //  =========================================================   //
    private static method onDamagingEvent takes nothing returns nothing
        local integer i
        call pushDamageInfo()

        //  Throw events when appropriate
        set i                   = index
        set dreamFlags          = DAMAGE_FLAG_WILL_BE_CODE
        call MODIFIER_SYSTEM.run()
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_SUPPRESS_EVENTS) == 0) then
            //  Throw a modifier event here.
            call MODIFIER_OUTGOING.run()
        endif
        set dreamFlags          = BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_WILL_BE_GAME + DAMAGE_FLAG_WILL_BE_CODE)
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_IS_PURE) != 0) then
            set pDmgA[i]    = pureDmgA[i]
        endif
        call BlzSetEventDamage(pDmgA[i])
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_LOCK_INFO) == 0) then
            call BlzSetEventAttackType(pAttacktypeA[i])
            call BlzSetEventDamageType(pDamagetypeA[i])
            call BlzSetEventWeaponType(pWeapontypeA[i])
            set dmgFlagsA[i]    = dmgFlagsA[i] + DAMAGE_FLAG_LOCK_INFO
        endif
        set outgoingDmgA[i] = pDmgA[i]
        set dmgFlagsA[i]    = dmgFlagsA[i] - DAMAGE_FLAG_PHASE_OUTGOING + DAMAGE_FLAG_PHASE_INCOMING
    endmethod
    
    private static method onDamagedEvent takes nothing returns nothing
        local integer i         = index
        local real curHP        = 0.0
        set incomingDmgA[index] = GetEventDamage()
        set pDmgA[i]            = incomingDmgA[i]

        //  Ensure that calcFactor does not divide by 0.0
        //  To make it more safe, the equal comparison
        //  operation was used instead.
        if (not (outgoingDmgA[i] == 0.0)) then
            set calcFactorA[i]  = pDmgA[i] / outgoingDmgA[i]
        else
            set calcFactorA[i]  = 1.0
        endif

        set dreamFlags          = DAMAGE_FLAG_WILL_BE_CODE
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_SUPPRESS_EVENTS) == 0) then
            call MODIFIER_INCOMING.run()
        endif
        set dmgFlagsA[i]        = dmgFlagsA[i] + DAMAGE_FLAG_LOCK_DAMAGE
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_SUPPRESS_EVENTS) == 0) then
            call ON_DAMAGE.run()
        endif
        set curHP               = GetWidgetLife(targetA[i])
        set pFinalHPA[i]        = curHP - pDmgA[i]
        if ((curHP - pDmgA[i] <= 0.406) and /*
        */ (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_SUPPRESS_EVENTS) == 0)) then
            call ON_LETHAL_DAMAGE.run()
        endif
        set pDmgA[i]            = GetWidgetLife(targetA[i]) - pFinalHPA[i]
        call BlzSetEventDamage(pDmgA[i])
        set dreamFlags          = BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_WILL_BE_GAME + DAMAGE_FLAG_WILL_BE_CODE)

        //  Check if the unit is dead before proceeding
        //  with the after damage event.
        if (not UnitAlive(targetA[i])) then
            return
        endif
        set dmgFlagsA[i]        = dmgFlagsA[i] - DAMAGE_FLAG_PHASE_INCOMING + DAMAGE_FLAG_PHASE_RECEIVED
        set detectorA[i]        = CreateTrigger()
        set curHP               = RMaxBJ(GetWidgetLife(targetA[i]) - pDmgA[i], 0.406)
        set detectorMap.integer[GetHandleId(detectorA[i])]  = i
        call TriggerAddCondition(detectorA[i], Condition(onInflictDamage))
        call TriggerRegisterUnitStateEvent(detectorA[i], targetA[i], UNIT_STATE_LIFE, LESS_THAN, curHP)
        call TriggerRegisterUnitStateEvent(detectorA[i], targetA[i], UNIT_STATE_LIFE, GREATER_THAN, curHP)
    endmethod
    
    private static method onInflictEvent takes nothing returns nothing
        local integer i         = detectorMap.integer[GetHandleId(GetTriggeringTrigger())]
        local integer pIndex    = index
        if (i <= 0) then
            return
        endif
        set index               = i
        set dreamFlags          = DAMAGE_FLAG_WILL_BE_CODE
        if (BlzBitAnd(dmgFlagsA[i], DAMAGE_FLAG_SUPPRESS_EVENTS) == 0) then
            call AFTER_DAMAGE.run()
        endif
        if (i <= 1) then
            set dreamFlags          = DAMAGE_FLAG_WILL_BE_GAME
        else
            set dreamFlags          = BlzBitAnd(dmgFlagsA[i - 1], DAMAGE_FLAG_WILL_BE_GAME + DAMAGE_FLAG_WILL_BE_CODE)
        endif
        set index               = pIndex
        set dmgFlagsA[i]        = dmgFlagsA[i] - DAMAGE_FLAG_PHASE_RECEIVED
        call removeDamageInfo(i)
        if (i == index) then
            set index   = index - 1
        endif
    endmethod

    private static method onEventHandle takes nothing returns nothing
        local eventid eventID   = GetTriggerEventId()
        if (eventID == EVENT_PLAYER_UNIT_DAMAGING) then
            call thistype.onDamagingEvent()
        else
            call thistype.onDamagedEvent()
        endif
    endmethod

    //  =========================================================   //
    //              Initialization API                              //
    //  =========================================================   //
    private static method initVars takes nothing returns nothing
        set onCleanupInstances  = function thistype.onCleanup
        set onInflictDamage     = function thistype.onInflictEvent
        set cleanupTimer        = CreateTimer()
        set detectorMap         = Table.create()
    endmethod
    private static method initEvents takes nothing returns nothing
        local trigger trig      = CreateTrigger()
        local integer i         = 0
        local player p          = null
        call TriggerAddCondition(trig, Condition(function thistype.onEventHandle))
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set p = Player(i)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_DAMAGING, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_DAMAGED, null)
            set i = i + 1
        endloop
    endmethod
    private static method init takes nothing returns nothing
        call initVars()
        call initEvents()
    endmethod
    implement Init
endstruct

endlibrary
