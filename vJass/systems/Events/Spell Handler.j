library SpellHandler requires /*

    ------------------
    */  UnitDex     /*
    ------------------

    ------------------
    */  Init        /*
    ------------------

    ------------------
    */  ListT       /*
    ------------------

    ---------------------------
    */  EventListener        /*
    ---------------------------

     -------------------------------------
    |
    |   SpellHandler   - vJASS
    |
    |-------------------------------------
    |
    |   A library that handles the processing
    |   and information derived from spell events.
    |
    |-------------------------------------
    |
    |   API
    |
    |-------------------------------------
    |
    |   Good luck, lol
    |
     -------------------------------------
*/

globals
    constant integer EVENT_CAST       = 0
    constant integer EVENT_CHANNEL    = 1
    constant integer EVENT_EFFECT     = 2
    constant integer EVENT_ENDCAST    = 3
    constant integer EVENT_FINISH     = 4
    constant integer EVENT_SKILL      = 5
endglobals

private module SpellHandlerEventHandles
    readonly static EventListener ON_CAST       = 0
    readonly static EventListener ON_CHANNEL    = 0
    readonly static EventListener ON_EFFECT     = 0
    readonly static EventListener ON_ENDCAST    = 0
    readonly static EventListener ON_FINISH     = 0
    readonly static EventListener ON_SKILL      = 0

    private static method onInit takes nothing returns nothing
        set ON_CAST         = EventListener.create()
        set ON_CHANNEL      = EventListener.create()
        set ON_EFFECT       = EventListener.create()
        set ON_ENDCAST      = EventListener.create()
        set ON_FINISH       = EventListener.create()
        set ON_SKILL        = EventListener.create()
    endmethod
endmodule

private module SpellHandlerInfoModule
    readonly static constant integer MASK_NO_TARGET     = 1
    readonly static constant integer MASK_POINT_TARGET  = 2
    readonly static constant integer MASK_TARGET        = 4
    readonly static constant integer MASK_UNIT_TARGET   = 8
    readonly static constant integer MASK_DEST_TARGET   = 16
    readonly static constant integer MASK_ITEM_TARGET   = 32

    static method requestGroup takes nothing returns group
        if (recycleGIndex > 0) then
            set recycleGIndex   = recycleGIndex - 1
            return recycleGroup[recycleGIndex + 1]
        endif
        return CreateGroup()
    endmethod
    static method releaseGroup takes group g returns nothing
        call GroupClear(g)
        set recycleGIndex               = recycleGIndex + 1
        set recycleGroup[recycleGIndex] = g
    endmethod
    private static method onInit takes nothing returns nothing
        local integer i = 1
        loop
            exitwhen i > 12
            set recycleGIndex   = recycleGIndex + 1
            set recycleGroup[i] = CreateGroup()
            set i               = i + 1
        endloop
    endmethod
endmodule

//! runtextmacro DEFINE_LIST("private", "SpellHandlerInfoList", "integer")

private struct SpellHandlerInfo extends array
    implement Alloc

    private static integer     recycleGIndex    = 0
    private static group array recycleGroup

    readonly integer         curAbility
    readonly integer         curAbilityLevel
    readonly boolean         isCasting
    readonly boolean         channelFinished

    readonly integer         curTargetType
    readonly unit            curTargetUnit
    readonly item            curTargetItem
    readonly destructable    curTargetDest

    readonly real            curTargetX
    readonly real            curTargetY
    readonly real            curTargetAOE
    readonly integer         curOrderType
    readonly integer         curOrder

    static method operator [] takes unit whichUnit returns thistype
        return thistype(GetUnitId(whichUnit))
    endmethod

    static method pushAbilityInfo takes unit whichUnit, integer abil, integer level, boolean checkPrevious returns nothing
        local thistype self = thistype[whichUnit]
        if ((checkPrevious) and (self.curAbility == abil)) then
            return
        endif
        set self.curAbility         = abil
        set self.curAbilityLevel    = level
        set self.isCasting          = true
        set self.channelFinished    = false
        set self.curOrder           = GetUnitCurrentOrder(whichUnit)
        set self.curTargetAOE       = BlzGetAbilityRealLevelField(BlzGetUnitAbility(whichUnit, abil), ABILITY_RLF_AREA_OF_EFFECT, level - 1)

        set self.curTargetUnit      = GetSpellTargetUnit()
        set self.curTargetDest      = GetSpellTargetDestructable()
        set self.curTargetItem      = GetSpellTargetItem()

        if (self.curTargetUnit != null) then
            set self.curTargetType  = BlzBitOr(MASK_TARGET, MASK_UNIT_TARGET)
        elseif (self.curTargetDest != null) then
            set self.curTargetType  = BlzBitOr(MASK_TARGET, MASK_DEST_TARGET)
        elseif (self.curTargetItem != null) then
            set self.curTargetType  = BlzBitOr(MASK_TARGET, MASK_ITEM_TARGET)
        endif

        if (BlzBitAnd(self.curTargetType, MASK_TARGET) != 0) then
            set self.curOrderType   = MASK_TARGET
            set self.curTargetType  = BlzBitAnd(self.curTargetType, -MASK_TARGET - 1)
            return
        endif

        set self.curTargetX         = GetSpellTargetX()
        set self.curTargetY         = GetSpellTargetY()
        if ((self.curTargetX == 0) and (self.curTargetY == 0)) then
            set self.curOrderType   = MASK_NO_TARGET
            return
        endif
        set self.curOrderType   = MASK_POINT_TARGET
    endmethod

    static method markAbilityAsFinished takes unit whichUnit returns nothing
        set thistype[whichUnit].channelFinished   = true
    endmethod

    static method popAbilityInfo takes unit whichUnit returns nothing
        local thistype self         = thistype[whichUnit]
        set self.curAbility         = 0
        set self.curAbilityLevel    = 0
        set self.isCasting          = false
        set self.channelFinished    = false
        set self.curOrder           = 0
        set self.curTargetAOE       = 0.0

        set self.curTargetUnit      = null
        set self.curTargetDest      = null
        set self.curTargetItem      = null
        set self.curTargetX         = 0.0
        set self.curTargetY         = 0.0
        set self.curOrderType       = 0
    endmethod
    implement SpellHandlerInfoModule
endstruct

struct SpellHandler extends array
    private  static TableArray localEventMap    = 0
    private  static integer stackLevel          = 0
    private  static unit    array unitStack
    private  static integer array abilityStack
    private  static integer array levelStack
    
    readonly static unit    unit                = null
    readonly static integer ability             = 0
    readonly static integer level               = 0

    implement SpellHandlerEventHandles

    //  =========================================================   //
    //              Available Public Operators                      //
    //  =========================================================   //
    static method operator [] takes unit whichUnit returns SpellHandlerInfo
        return SpellHandlerInfo(GetUnitId(whichUnit))
    endmethod

    static method operator current takes nothing returns SpellHandlerInfo
        return SpellHandlerInfo(GetUnitId(unit))
    endmethod

    //  =========================================================   //
    //                     Public API                               //
    //  =========================================================   //
    static method register takes integer eventType, integer abilID, code callback returns EventResponder
        local EventListener listener    = 0
        //  Check if eventType is invalid
        if ((eventType > 5) or (eventType < 0)) then
            return 0
        endif
        if (not localEventMap[eventType].has(abilID)) then
            set listener                            = EventListener.create()
            set localEventMap[eventType][abilID]    = listener
        else
            set listener                            = EventListener(localEventMap[eventType][abilID])
        endif
        return listener.register(callback)
    endmethod

    //  =========================================================   //
    //              Global value handlers                           //
    //  =========================================================   //
    private static method pushStack takes nothing returns nothing
        set stackLevel                  = stackLevel + 1
        set unitStack[stackLevel]       = unit
        set abilityStack[stackLevel]    = ability
        set levelStack[stackLevel]      = level
    endmethod

    private static method popStack takes nothing returns nothing
        set unit        = unitStack[stackLevel]
        set ability     = abilityStack[stackLevel]
        set level       = levelStack[stackLevel]
        set stackLevel  = stackLevel - 1
    endmethod

    //  =========================================================   //
    //              Event Handling function                         //
    //  =========================================================   //
    private static method onEventHandle takes nothing returns nothing
        local eventid eventID           = GetTriggerEventId()
        local integer unitID
        local EventListener listener

        call thistype.pushStack()
        set unit        = GetTriggerUnit()
        set unitID      = GetUnitId(unit)
        if (eventID == EVENT_PLAYER_HERO_SKILL) then
            set ability = GetLearnedSkill()
            set level   = GetLearnedSkillLevel()
        else
            set ability = GetSpellAbilityId()
            set level   = GetUnitAbilityLevel(thistype.unit, ability)
        endif

        if (eventID == EVENT_PLAYER_UNIT_SPELL_CAST) then
            set listener    = EventListener(localEventMap[EVENT_CAST][ability])
            call SpellHandlerInfo.pushAbilityInfo(unit, ability, level, true)
            if (listener != 0) then
                call listener.run()
            endif
            call ON_CAST.run()

        elseif (eventID == EVENT_PLAYER_UNIT_SPELL_CHANNEL) then
            set listener    = EventListener(localEventMap[EVENT_CHANNEL][ability])
            call SpellHandlerInfo.pushAbilityInfo(unit, ability, level, false)
            if (listener != 0) then
                call listener.run()
            endif
            call ON_CHANNEL.run()

        elseif (eventID == EVENT_PLAYER_UNIT_SPELL_EFFECT) then
            set listener    = EventListener(localEventMap[EVENT_EFFECT][ability])
            call SpellHandlerInfo.pushAbilityInfo(unit, ability, level, true)
            if (listener != 0) then
                call listener.run()
            endif
            call ON_EFFECT.run()

        elseif (eventID == EVENT_PLAYER_UNIT_SPELL_ENDCAST) then
            set listener    = EventListener(localEventMap[EVENT_ENDCAST][ability])
            if (listener != 0) then
                call listener.run()
            endif
            call ON_ENDCAST.run()
            call SpellHandlerInfo.popAbilityInfo(unit)

        elseif (eventID == EVENT_PLAYER_UNIT_SPELL_FINISH) then
            set listener    = EventListener(localEventMap[EVENT_FINISH][ability])
            call SpellHandlerInfo.markAbilityAsFinished(unit)
            if (listener != 0) then
                call listener.run()
            endif
            call ON_FINISH.run()

        elseif (eventID == EVENT_PLAYER_HERO_SKILL) then
            set listener    = EventListener(localEventMap[EVENT_SKILL][ability])
            call SpellHandlerInfo.pushAbilityInfo(unit, ability, level, true)
            if (listener != 0) then
                call listener.run()
            endif
            call ON_SKILL.run()
            call SpellHandlerInfo.popAbilityInfo(unit)
        endif
        call thistype.popStack()
    endmethod

    //  =========================================================   //
    //              Initialization API                              //
    //  =========================================================   //
    private static method initEvents takes nothing returns nothing
        local trigger trig  = CreateTrigger()
        local integer i     = 0
        local player p      = null
        call TriggerAddCondition(trig, Condition(function thistype.onEventHandle))
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set p = Player(i)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_SPELL_CAST, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_SPELL_CHANNEL, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_SPELL_ENDCAST, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_UNIT_SPELL_FINISH, null)
            call TriggerRegisterPlayerUnitEvent(trig, p, EVENT_PLAYER_HERO_SKILL, null)
            set i = i + 1
        endloop
    endmethod
    private static method initVars takes nothing returns nothing
        set localEventMap   = TableArray[6]
    endmethod
    private static method init takes nothing returns nothing
        call initVars()
        call initEvents()
    endmethod
    implement Init
endstruct

endlibrary