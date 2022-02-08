library GenericMorph requires /*

    ------------------------------
    */ Table, UnitDex, Init     /*
    ------------------------------

    ------------------------------
    */ Alloc, EventListener     /*
    ------------------------------

    ------------------------------
    */ SpellHandler, TimerUtils /*
    ------------------------------

    Since this is specialized for the techtree contest map, it is
    separated from the rest of the snippets/systems. If there is
    a need to integrate this bundle into other maps, then the
    file will be moved to systems.
*/

struct GenericMorphResponse extends array
    implement Alloc

    readonly EventResponder enterResponse
    readonly EventResponder leaveResponse
    readonly EventResponder skillResponse
    readonly EventResponder skillStartResponse
    readonly EventResponder transformResponse

    static method create takes nothing returns thistype
        local thistype this         = thistype.allocate()
        set this.enterResponse      = EventResponder.create(null)
        set this.leaveResponse      = EventResponder.create(null)
        set this.skillResponse      = EventResponder.create(null)
        set this.skillStartResponse = EventResponder.create(null)
        set this.transformResponse  = EventResponder.create(null)
        return this
    endmethod
endstruct

struct GenericMorph extends array
    private static IntegerList responseList = 0
    private static GenericMorphResponse array responseMap

    private static constant integer EVENT_TYPE_ENTER        = 1
    private static constant integer EVENT_TYPE_LEAVE        = 2
    private static constant integer EVENT_TYPE_SKILL        = 3
    private static constant integer EVENT_TYPE_MORPH        = 4
    private static constant integer EVENT_TYPE_SKILL_START  = 5

    static method addResponse takes integer classID, GenericMorphResponse response returns nothing
        if (responseMap[classID] != 0) then
            return
        endif
        set responseMap[classID]    = response
        call responseList.push(response)
    endmethod

    private static method throwResponse takes integer eventType returns nothing
        local IntegerListItem iter      = responseList.first
        local GenericMorphResponse obj  = 0
        loop
            exitwhen iter == 0
            set obj     = GenericMorphResponse(iter.data)
            set iter    = iter.next
            if (eventType == EVENT_TYPE_ENTER) then
                call obj.enterResponse.conditionalRun()
            elseif (eventType == EVENT_TYPE_LEAVE) then
                call obj.leaveResponse.conditionalRun()
            elseif (eventType == EVENT_TYPE_SKILL) then
                call obj.skillResponse.conditionalRun()
            elseif (eventType == EVENT_TYPE_SKILL_START) then
                call obj.skillStartResponse.conditionalRun()
            elseif (eventType == EVENT_TYPE_MORPH) then
                call obj.transformResponse.conditionalRun()
            endif
        endloop
    endmethod
    private static method onUnitEnter takes nothing returns nothing
        call thistype.throwResponse(EVENT_TYPE_ENTER)
    endmethod
    private static method onUnitLeave takes nothing returns nothing
        call thistype.throwResponse(EVENT_TYPE_LEAVE)
    endmethod
    private static method onUnitTransform takes nothing returns nothing
        call thistype.throwResponse(EVENT_TYPE_MORPH)
    endmethod
    private static method onUnitAttemptMorph takes nothing returns nothing
        call thistype.throwResponse(EVENT_TYPE_SKILL)
    endmethod
    private static method onGroupAttemptMorph takes nothing returns nothing
        call thistype.throwResponse(EVENT_TYPE_SKILL_START)
    endmethod
    private static method init takes nothing returns nothing
        set responseList    = IntegerList.create()
        call OnUnitIndex(function thistype.onUnitEnter)
        call OnUnitDeindex(function thistype.onUnitLeave)
        call UnitAuxHandler.ON_TRANSFORM.register(function thistype.onUnitTransform)
        call SpellHandler.ON_FINISH.register(function thistype.onUnitAttemptMorph)
        call SpellHandler.ON_CHANNEL.register(function thistype.onGroupAttemptMorph)
    endmethod
    implement Init
endstruct

struct GenericMorphData extends array
    implement Alloc

    private unit unit
    private integer order
    private integer abil
    private integer level

    private static method enqueue takes nothing returns nothing
        local thistype this = ReleaseTimer(GetExpiredTimer())
        call BlzUnitDisableAbility(this.unit, this.abil, false, false)
        call SetUnitAbilityLevel(this.unit, this.abil, this.level)
        call IssueImmediateOrderById(this.unit, this.order)
        call BlzUnitDisableAbility(this.unit, this.abil, true, true)
    endmethod

    static method queue takes unit source, integer orderID, integer abilID, integer level returns nothing
        local thistype this = thistype.allocate()
        set this.unit       = source
        set this.order      = orderID
        set this.abil       = abilID
        set this.level      = level
        call TimerStart(NewTimerEx(this), 0.0, false, function thistype.enqueue)
    endmethod
endstruct
//  Note: This module assumes that the number of
//  registered unit ids is the same with the number
//  of registered morph skill id's. Base transformation
//  skill is Bear Form.
module GenericMorphHandler
    private static GenericMorphResponse resp    = 0
    private static integer index                = 0
    private static integer rows                 = 0
    private static Table unitIDMap              = 0
    private static Table morphSkillMap          = 0
    private static integer array unitType
    private static integer array trueUnitTypeID

    static integer ABIL_ID                      = 0
    static integer array UNIT_ID
    static integer array MORPH_SKILL_ID

    static if not thistype.TRANSFORM_ORDER.exists then
    static method TRANSFORM_ORDER takes nothing returns integer
        return 852138
    endmethod
    endif

    static if not thistype.UNTRANSFORM_ORDER.exists then
    static method UNTRANSFORM_ORDER takes nothing returns integer
        return 852139
    endmethod
    endif

    static if not thistype.GROUPED_MORPH.exists then
    static method GROUPED_MORPH takes nothing returns boolean
        return true
    endmethod
    endif

    private static method mapUnitIDs takes nothing returns nothing
        loop
            exitwhen (UNIT_ID[index + 1] == 0)
            set index                                           = index + 1
            set unitIDMap.integer[UNIT_ID[index]]               = index
            set morphSkillMap.integer[MORPH_SKILL_ID[index]]    = index
        endloop
        set rows                = index - 1
    endmethod

    private static method onUnitEnter takes nothing returns nothing
        local unit u            = GetIndexedUnit()
        local integer curTypeID = GetUnitTypeId(u)
        local integer id        = GetUnitId(u)
        local integer iter      = 1
        if (not unitIDMap.integer.has(curTypeID)) then
            set u   = null
            return
        endif
        set unitType[id]        = unitIDMap.integer[curTypeID]
        set trueUnitTypeID[id]  = unitType[id]
        loop
            exitwhen iter > index
            call UnitMakeAbilityPermanent(u, true, MORPH_SKILL_ID[iter])
            set iter            = iter + 1
        endloop
        call UnitAddAbility(u, ABIL_ID)
        call UnitMakeAbilityPermanent(u, true, ABIL_ID)
        call BlzUnitDisableAbility(u, ABIL_ID, true, true)
        call BlzUnitDisableAbility(u, MORPH_SKILL_ID[unitType[id]], true, true)
        static if thistype.onEnter.exists then
            call thistype.onEnter(u, unitType[id])
        endif
        set u                   = null
    endmethod

    private static method onUnitLeave takes nothing returns nothing
        local unit u            = GetIndexedUnit()
        local integer curTypeID = GetUnitTypeId(u)
        local integer id        = GetUnitId(u)
        if (unitType[id] == 0) then
            return
        endif
        static if thistype.onLeave.exists then
            call thistype.onLeave(u, unitType[id])
        endif
        set unitType[id]        = 0
        set trueUnitTypeID[id]  = 0
        set u                   = null
    endmethod

    private static method onUnitTransform takes nothing returns nothing
        local unit u            = UnitAuxHandler.unit
        local integer curTypeID = UnitAuxHandler.curTransformID
        local integer id        = GetUnitId(u)
        local integer iter      = 1
        if (unitType[id] == 0) then
            //  If current type has an unmapped ID, ignore
            if (not unitIDMap.integer.has(curTypeID)) then
                set u   = null
                return
            endif
            loop
                exitwhen iter > index
                call UnitMakeAbilityPermanent(u, true, MORPH_SKILL_ID[iter])
                set iter        = iter + 1
            endloop
        else
            call BlzUnitDisableAbility(u, MORPH_SKILL_ID[unitType[id]], false, false)
        endif
        set unitType[id]        = unitIDMap.integer[curTypeID]
        call BlzUnitDisableAbility(u, MORPH_SKILL_ID[unitType[id]], true, true)
        static if thistype.onTransform.exists then
            call thistype.onTransform(u, unitType[id])
        endif
        set u                   = null
    endmethod

    private static method onUnitAttemptMorph takes nothing returns nothing
        local unit u            = SpellHandler.unit
        local integer id        = GetUnitId(u)
        local integer abilID    = SpellHandler[u].curAbility
        local integer abilType  = 0
        local integer uType     = unitType[id]
        local boolean wasDec    = false
        if (not morphSkillMap.integer.has(abilID)) then
            set u           = null
            return
        endif
        set abilType        = morphSkillMap.integer[abilID]
        if (abilType > uType) then
            set abilType    = abilType - 1
            set wasDec      = true
        endif
        //  Do something funky
        static if thistype.onAttemptMorph.exists then
        if wasDec then
            set abilType    = abilType + 1
        endif
        call thistype.onAttemptMorph(u, uType, abilType)
        if wasDec then
            set abilType    = abilType - 1
        endif
        endif
        //  Set unit ability level
        call BlzUnitDisableAbility(u, ABIL_ID, false, false)
        call IssueImmediateOrderById(u, thistype.UNTRANSFORM_ORDER())
        call BlzUnitDisableAbility(u, ABIL_ID, true, true)

        call GenericMorphData.queue(u, thistype.TRANSFORM_ORDER(), ABIL_ID, (uType - 1)*rows + abilType)
        //call SetUnitAbilityLevel(u, ABIL_ID, (uType - 1)*rows + abilType)
        //call IssueImmediateOrderById(u, thistype.TRANSFORM_ORDER())
        set u               = null
    endmethod

    private static method onGroupAttemptMorph takes nothing returns nothing
        local unit u            = SpellHandler.unit
        local unit foG
        local integer id        = GetUnitId(u)
        local integer uTypeID   = GetUnitTypeId(u)
        local integer abilID    = SpellHandler[u].curAbility
        local group g

        if (not morphSkillMap.integer.has(abilID)) or /*
        */ (not thistype.GROUPED_MORPH()) then
            set u           = null
            return
        endif

        call resp.skillStartResponse.enable(false)
        set g               = CreateGroup()
        call GroupEnumUnitsSelected(g, GetOwningPlayer(u), null)
        loop
            set foG         = FirstOfGroup(g)
            exitwhen (foG == null)
            loop
                exitwhen (foG == u)
                if (GetUnitTypeId(foG) == uTypeID) then
                    call IssueTargetOrderById(foG, GetUnitCurrentOrder(u), foG)
                endif
                exitwhen true
            endloop
            call GroupRemoveUnit(g, foG)
        endloop
        call resp.skillStartResponse.enable(true)

        call DestroyGroup(g)
        set g               = null
        set u               = null
    endmethod

    private static method onInit takes nothing returns nothing
        set resp                = GenericMorphResponse.create()
        set unitIDMap           = Table.create()
        set morphSkillMap       = Table.create()

        call resp.enterResponse.change(function thistype.onUnitEnter)
        call resp.leaveResponse.change(function thistype.onUnitLeave)
        call resp.transformResponse.change(function thistype.onUnitTransform)
        call resp.skillResponse.change(function thistype.onUnitAttemptMorph)
        call resp.skillStartResponse.change(function thistype.onGroupAttemptMorph)
        
        call thistype.initVars()
        call thistype.mapUnitIDs()
        call GenericMorph.addResponse(thistype.typeid, resp)
    endmethod
endmodule

endlibrary