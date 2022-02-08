scope UpgradeHall

native GetUnitGoldCost takes integer unitid returns integer
native GetUnitWoodCost takes integer unitid returns integer

private function B2S takes boolean flag returns string
    if (flag) then
        return "true"
    endif
    return "false"
endfunction

private module UpgradeHallConfig
    static integer array HALL_ID
    static integer array ABIL_ID
    static integer index            = 0
    static TableArray idMap         = 0

    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A@01'
    endmethod
    static method operator unitMap takes nothing returns Table
        return idMap[1]
    endmethod
    static method operator abilMap takes nothing returns Table
        return idMap[0]
    endmethod
    private static method onDefineMap takes nothing returns nothing
        loop
            exitwhen (ABIL_ID[index + 1] == 0)
            set index                       = index + 1
            set idMap[0][ABIL_ID[index]]    = index
            set idMap[1][HALL_ID[index]]    = index
        endloop
    endmethod
    private static method onInit takes nothing returns nothing
        set idMap                           = TableArray[2]
        set HALL_ID[1]                      = 'e106'
        set HALL_ID[2]                      = 'e107'
        set ABIL_ID[1]                      = 'A00V'
        set ABIL_ID[2]                      = 'A00W'
        call thistype.onDefineMap()
    endmethod
endmodule

//! runtextmacro DEFINE_LIST("private", "UnitList", "unit")

private struct UpgradeBuilder extends array
    readonly static unit builder    = null

    static constant method operator UNIT_ID takes nothing returns integer
        return 'e008'
    endmethod

    private static method onInit takes nothing returns nothing
        set builder                 = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_ID, 0.0, 0.0, 0.0)
        call ShowUnit(builder, false)
        call PauseUnit(builder, true)
    endmethod
endstruct

private struct QueueUpgradeBuilder
    private  static EventResponder monitorResp  = 0
    private  static IntegerList builderList     = 0
    private  static thistype array builderMap
    private  static constant integer TICK       = 2

    private  IntegerListItem listPtr
    private  timer           buildTimer
    private  boolean         unordered

    readonly player          owner
    readonly integer         buildID
    readonly real            cx
    readonly real            cy

    readonly unit            builder

    static constant method operator UNIT_ID takes nothing returns integer
        return 'e008'
    endmethod

    private method destroy takes nothing returns nothing
        if (this.builder == null) then
            return
        endif
        call builderList.erase(this.listPtr)
        if (builderList.empty()) then
            call GTimer[TICK].releaseCallback(monitorResp)
        endif
        set builderMap[GetUnitId(this.builder)] = 0
        call ReleaseTimer(this.buildTimer)
        call RemoveUnit(this.builder)

        set this.unordered                      = false
        set this.listPtr                        = 0
        set this.buildID                        = 0
        set this.cx                             = 0.0
        set this.cy                             = 0.0
        set this.builder                        = null
        set this.buildTimer                     = null
        set this.owner                          = null
        call this.deallocate()
    endmethod

    private static method attemptBuild takes nothing returns nothing
        local thistype this     = GetTimerData(GetExpiredTimer())
        local boolean result    = (GetPlayerState(this.owner, PLAYER_STATE_RESOURCE_GOLD) < GetUnitGoldCost(this.buildID)) or /*
                               */ (GetPlayerState(this.owner, PLAYER_STATE_RESOURCE_LUMBER) < GetUnitWoodCost(this.buildID))
        set this.unordered      = false
        //  Turns out this function caused a nasty race-condition that went
        //  undetected for some time. Fixed as of v.1.1.0
        if (not IssueBuildOrderById(this.builder, this.buildID, cx, cy)) or /*
        */ (result) then
            call this.destroy()
        endif
    endmethod

    method start takes real dur returns nothing
        if (this.buildTimer != null) then
            return
        endif
        set this.buildTimer = NewTimerEx(this)
        call TimerStart(this.buildTimer, dur, false, function thistype.attemptBuild)
    endmethod

    private static method onBuilderCheckOrder takes nothing returns nothing
        local IntegerListItem iter              = builderList.first
        local thistype this                     = iter.data
        loop
            exitwhen (iter == 0)
            set iter                            = iter.next
            //  Actions here.
            if (not this.unordered) and (GetUnitCurrentOrder(this.builder) == 0) then
                call this.destroy()
            endif
            set this                            = iter.data
        endloop
    endmethod

    static method create takes player owner, real x, real y, integer buildID returns thistype
        local thistype this                     = thistype.allocate()
        set this.owner                          = owner
        set this.cx                             = x
        set this.cy                             = y
        set this.buildID                        = buildID
        set this.builder                        = CreateUnit(owner, UNIT_ID, x, y, 0.0)
        set this.listPtr                        = builderList.push(this).last
        set this.unordered                      = true
        set builderMap[GetUnitId(this.builder)] = this
        if (builderList.size() == 1) then
            call GTimer[TICK].requestCallback(monitorResp)
        endif
        return this
    endmethod

    private static method init takes nothing returns nothing
        set builderList                         = IntegerList.create()
        set monitorResp                         = GTimer.register(TICK, function thistype.onBuilderCheckOrder)
    endmethod
    implement Init
endstruct

private struct UpgradeStructure extends array
    UnitListItem listPtr
    integer data

    method operator unit takes nothing returns unit
        return GetUnitById(this)
    endmethod

    static method operator [] takes unit whichUnit returns thistype
        return GetUnitId(whichUnit)
    endmethod

    method destroy takes nothing returns nothing
        set this.listPtr    = 0
        set this.data       = 0
    endmethod
endstruct

private struct UpgradeHall extends array
    implement UpgradeHallConfig

    private static Table tempTable      = 0
    private static group tempGroup      = null
    private static group hallGroup      = null

    private integer mode
    private UnitList list
    private unit curWing

    private static method operator [] takes unit whichUnit returns thistype
        return GetUnitId(whichUnit)
    endmethod

    private method operator unit takes nothing returns unit
        return GetUnitById(this)
    endmethod

    private method disableMode takes nothing returns nothing
        call UnitRemoveAbilityTimed(this.unit, ABIL_ID[this.mode], 0.0)
    endmethod

    private method activateMode takes nothing returns nothing
        //  Move the ability up the stack.
        if (this.mode < 1) or (this.mode > index) then
            return
        endif
        call UnitAddAbilityTimed(this.unit, ABIL_ID[this.mode], 0.0)
    endmethod

    //  ============================================================
    //                      Wing Handlers
    //  ============================================================
    private method addWing takes unit wing returns nothing
        local UpgradeStructure object   = UpgradeStructure[wing]
        set object.listPtr              = this.list.push(wing).last
        set object.data                 = this
        if (this.list.size() == 1) then
            call UnitAddAbility(this.unit, 'Avul')
        endif
    endmethod

    private method removeWing takes unit wing returns nothing
        local UpgradeStructure object   = UpgradeStructure[wing]
        if (thistype(object.data) != this) then
            return
        endif
        call this.list.erase(object.listPtr)
        call object.destroy()
        if (this.list.empty()) then
            call UnitRemoveAbility(this.unit, 'Avul')
        endif
    endmethod

    //  ============================================================
    //                     Misc Functions
    //  ============================================================
    private method updateMode takes nothing returns nothing
        local UnitListItem iter                         = this.list.first
        local integer misIndex                          = 1
        local integer unitType                          = 0
        local unit temp
        //  Flag entries already occupied
        call this.disableMode()
        loop
            exitwhen (iter == 0)
            set temp                                    = iter.data
            set unitType                                = GetUnitTypeId(temp)
            set iter                                    = iter.next
            //  Inspect unit type
            set tempTable.integer[unitMap[unitType]]    = tempTable[unitMap[unitType]] + 1
        endloop
        loop
            exitwhen (misIndex > index) or (tempTable.integer[unitMap[HALL_ID[misIndex]]] == 0)
            call tempTable.integer.remove(unitMap[HALL_ID[misIndex]])
            set misIndex                                = misIndex + 1
        endloop
        set this.mode                                   = misIndex
        call this.activateMode()
    endmethod

    private method chargeToPlayer takes player p, integer index returns nothing
        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - GetUnitGoldCost(HALL_ID[index]))
        call SetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER) - GetUnitWoodCost(HALL_ID[index]))
    endmethod

    private static method getNearestHall takes unit wing returns thistype
        local integer i             = 0
        local integer n             = BlzGroupGetSize(hallGroup)
        local thistype result       = 0
        local unit temp             = null
        local real minDist          = 9999999999.00
        local real distX
        local real distY
        loop
            exitwhen (i >= n)
            set temp                = BlzGroupUnitAt(hallGroup, i)
            loop
                exitwhen (GetOwningPlayer(wing) != GetOwningPlayer(temp))
                set distX           = (GetUnitX(wing)-GetUnitX(temp))
                set distY           = (GetUnitY(wing)-GetUnitY(temp))
                set distX           = distX*distX + distY*distY
                if (minDist >= distX) then
                    set result      = thistype[temp]
                    set minDist     = distX
                endif
                exitwhen true
            endloop
            set i                   = i + 1
        endloop
        set temp                    = null
        return result
    endmethod

//  ================================================================================
//                              Event Responses
//  ================================================================================

    //  ============================================================================
    //                      Construct Start event
    //  ============================================================================
    private static method onWingStart takes nothing returns nothing
        local thistype this
        local UpgradeStructure object
        local unit wing             = StructureHandler.structure
        if (not unitMap.integer.has(GetUnitTypeId(wing))) then
            set wing                = null
            return
        endif
        //  Locate builder unit
        set this                    = thistype.getNearestHall(wing)
        set this.curWing            = wing
        call this.addWing(wing)
        call this.disableMode()
    endmethod

    //  ============================================================================
    //                  Structure enter / construct finish event
    //  ============================================================================
    private static method onHallEnter takes nothing returns nothing
        local unit hall
        local thistype this
        if (GetUnitAbilityLevel(StructureHandler.structure, ABILITY_ID) == 0) then
            return
        endif
        set hall            = StructureHandler.structure
        set this            = thistype[hall]
        set this.mode       = 1
        set this.list       = UnitList.create()

        //  Oddly enough, I didn't spot this flaw earlier where hall was nullified b4
        //  it could be added to the group. lol.
        call GroupAddUnit(hallGroup, hall)
        call this.activateMode()
        set hall            = null
    endmethod

    private static method onWingEnter takes nothing returns nothing
        local unit wing                 = StructureHandler.structure
        local UpgradeStructure object   = UpgradeStructure[wing]
        local thistype this
        if (not unitMap.has(GetUnitTypeId(wing))) then
            set wing                    = null
            return
        endif
        loop
            set this                    = object.data
            exitwhen (object.listPtr != 0)
            set this                    = thistype.getNearestHall(wing)
            call this.addWing(wing)
            exitwhen true
        endloop
        if (wing == this.curWing) then
            set this.curWing            = null
        endif
        set wing                        = null
        call this.updateMode()
    endmethod

    private static method onStructureEnter takes nothing returns nothing
        call thistype.onHallEnter()
        call thistype.onWingEnter()
    endmethod

    //  ============================================================================
    //                  Structure death event
    //  ============================================================================
    private static method onHallDeath takes nothing returns nothing
        local thistype this             = thistype[StructureHandler.structure]
        local UnitListItem iter         = 0
        local unit temp
        //  Any structure with a mode == 0 did not proceed on HallEnter.
        if (this.mode == 0) then
            return
        endif
        set this.mode                   = 0
        set this.curWing                = null
        set iter                        = this.list.last
        loop
            exitwhen (iter == 0)
            set temp                    = iter.data
            set iter                    = iter.prev
            //  Trigger a sub-call here.
            call KillUnit(temp)
        endloop
        call GroupRemoveUnit(hallGroup, this.unit)
    endmethod

    private static method onWingDeath takes nothing returns nothing
        local unit wing                 = StructureHandler.structure
        local UpgradeStructure object   = UpgradeStructure[wing]
        local thistype this             = 0
        if (object.listPtr == 0) then
            set wing                    = null
            return
        endif
        set this                        = object.data
        call this.removeWing(wing)

        if (this.list.empty()) and (this.mode == 0) then
            call this.list.destroy()
            set this.list               = 0
            return
        endif
        if (wing == this.curWing) then
            set this.curWing            = null
        endif
        call this.updateMode()
    endmethod

    private static method onStructureDeath takes nothing returns nothing
        call thistype.onHallDeath()
        call thistype.onWingDeath()
    endmethod

    //  ============================================================================
    //                  Structure removal event.
    //  ============================================================================
    private static method onStructureLeave takes nothing returns nothing
        call thistype.onHallDeath()
        call thistype.onWingDeath()
    endmethod

    //  ============================================================================
    //                  Hall Construction (pending).
    //  ============================================================================
    private static method onHallAttemptConstruct takes nothing returns nothing
        local thistype this                         = thistype[SpellHandler.unit]
        local integer index                         = 0
        local QueueUpgradeBuilder queue             = 0
        local player p
        local real tx
        local real ty
        if (not abilMap.has(SpellHandler.current.curAbility)) then
            return
        endif
        
        set tx                                      = SpellHandler.current.curTargetX
        set ty                                      = SpellHandler.current.curTargetY
        set p                                       = GetOwningPlayer(SpellHandler.unit)
        set index                                   = abilMap[SpellHandler.current.curAbility]
        set queue                                   = QueueUpgradeBuilder.create(p, tx, ty, HALL_ID[index])
        //  Cancel ability cast.
        call PauseUnit(SpellHandler.unit, true)
        call IssueImmediateOrderById(SpellHandler.unit, 851972)
        call PauseUnit(SpellHandler.unit, false)

        //  Attempt build order after 0 seconds.
        call queue.start(0.0)
    endmethod

    //  ============================================================================
    //                  Hall Construction (final).
    //  ============================================================================
    /*
    private static method onHallConstruct takes nothing returns nothing
        local thistype this                         = thistype[SpellHandler.unit]
        local integer index                         = 0
        local player p
        local real tx
        local real ty
        if (not abilMap.has(SpellHandler.current.curAbility)) then
            return
        endif
        set index                                   = abilMap[SpellHandler.current.curAbility]
        set p                                       = GetOwningPlayer(SpellHandler.unit)
        call this.chargeToPlayer(p, index)
        call this.disableMode()
    endmethod
    */

    //  ============================================================================
    //                              Initialization
    //  ============================================================================
    private static method onInit takes nothing returns nothing
        set tempTable                           = Table.create()
        set tempGroup                           = CreateGroup()
        set hallGroup                           = CreateGroup()
        call StructureHandler.ON_ENTER.register(function thistype.onStructureEnter)
        call StructureHandler.ON_DEATH.register(function thistype.onStructureDeath)
        call StructureHandler.ON_LEAVE.register(function thistype.onStructureLeave)
        call StructureHandler.ON_START.register(function thistype.onWingStart)
        call SpellHandler.ON_CHANNEL.register(function thistype.onHallAttemptConstruct)
        //call SpellHandler.ON_EFFECT.register(function thistype.onHallConstruct)
    endmethod
endstruct

endscope