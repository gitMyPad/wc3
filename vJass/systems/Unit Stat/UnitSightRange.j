library UnitSightRange requires CustomUnitStatFactory, DNCycle, UnitAuxEvents, ResearchChecker

globals
    private constant integer ABILITY_ID                         = '!002'
    private constant abilityintegerlevelfield SIGHT_MOD_FIELD   = ABILITY_ILF_SIGHT_RANGE_BONUS
    private constant integer ULTRAVISION                        = 'Ault'
    private constant integer ULTRATECH                          = 'Reuv'
endglobals

private function print takes string msg, boolean exp returns nothing
    if exp then
        call BJDebugMsg(msg)
    endif
endfunction

struct UnitSightRangeStat extends array
    //  To save on computational resources later on.
    private static EventResponder trackResp     = 0
    private static TableArray visionMap         = 0
    private static constant integer TICK        = 2
    private static group visionGroup            = null
    private static group adjustVisionGroup      = null

    private static real array dayBase
    private static real array nightBase
    private static real array tempBase

    private real curBase

    private method onApply takes unit whichUnit, real amount returns nothing
        local real animRun      = 0.0
        local real animWalk     = 0.0
        local real strLevel     = 0.0
        local real agiLevel     = 0.0
        local real intLevel     = 0.0
        if (IsUnitInGroup(whichUnit, adjustVisionGroup)) then
            return
        endif
        //  Credits to BloodSoul for figuring out the vision bug.
        //  Since there is a hierarchy for these things (I guess
        //  this must've been a union struct), the system will
        //  attempt to restore the old values afterwards.
        set animRun             = BlzGetUnitRealField(whichUnit, UNIT_RF_ANIMATION_RUN_SPEED)
        set animWalk            = BlzGetUnitRealField(whichUnit, UNIT_RF_ANIMATION_WALK_SPEED)
        set strLevel            = BlzGetUnitRealField(whichUnit, UNIT_RF_STRENGTH_PER_LEVEL)
        set agiLevel            = BlzGetUnitRealField(whichUnit, UNIT_RF_AGILITY_PER_LEVEL)
        set intLevel            = BlzGetUnitRealField(whichUnit, UNIT_RF_INTELLIGENCE_PER_LEVEL)
        call BlzSetUnitRealField(whichUnit, UNIT_RF_SIGHT_RADIUS, RMaxBJ(amount, 0.0))
        call BlzSetUnitRealField(whichUnit, UNIT_RF_ANIMATION_RUN_SPEED, animRun)
        call BlzSetUnitRealField(whichUnit, UNIT_RF_ANIMATION_WALK_SPEED, animWalk)
        call BlzSetUnitRealField(whichUnit, UNIT_RF_STRENGTH_PER_LEVEL, strLevel)
        call BlzSetUnitRealField(whichUnit, UNIT_RF_AGILITY_PER_LEVEL, agiLevel)
        call BlzSetUnitRealField(whichUnit, UNIT_RF_INTELLIGENCE_PER_LEVEL, intLevel)
    endmethod

    private method onBonusCalc takes real base, real sum, real product, boolean zeroMultiple returns real
        set this.curBase    = base
        if (zeroMultiple) then
            return sum
        endif
        return base*product + sum
    endmethod

    static method onUnregister takes unit whichUnit returns nothing
        local integer id            = GetUnitId(whichUnit)
        call GroupRemoveUnit(visionGroup, whichUnit)
        call GroupRemoveUnit(adjustVisionGroup, whichUnit)
        set dayBase[id]             = 0.0
        set nightBase[id]           = 0.0
        set tempBase[id]            = 0.0
        if (BlzGroupGetSize(adjustVisionGroup) == 0) then
            call GTimer[TICK].releaseCallback(trackResp)
        endif
    endmethod

    static method onTrackVision takes unit whichUnit returns nothing
        local integer id            = GetUnitId(whichUnit)
        local integer vIndex        = IntegerTertiaryOp(DNCycle.isDay, 1, 0)
        local integer uTypeID       = GetUnitTypeId(whichUnit)
        if (not visionMap[vIndex].real.has(uTypeID)) then
            call GroupAddUnit(adjustVisionGroup, whichUnit)
            set tempBase[id]        = BlzGetUnitRealField(whichUnit, UNIT_RF_SIGHT_RADIUS)
            if (BlzGroupGetSize(adjustVisionGroup) == 1) then
                call GTimer[TICK].requestCallback(trackResp)
            endif
            return
        endif
        if (DNCycle.isDay) then
            set dayBase[id]         = visionMap[vIndex].real[uTypeID]
        else
            set nightBase[id]       = visionMap[vIndex].real[uTypeID]
        endif
        call thistype.setBaseValue(whichUnit, visionMap[vIndex].real[uTypeID])
    endmethod

    static method onRegister takes unit whichUnit returns nothing
        call GroupAddUnit(visionGroup, whichUnit)
        call thistype.onTrackVision(whichUnit)
    endmethod

    private static method transformVision takes nothing returns nothing
        //  Temporarily cancel out any sight range bonus effects
        call thistype.onTrackVision(UnitAuxHandler.unit)
    endmethod

    private static method changeBaseVision takes nothing returns nothing
        //  Enumerate over all tracked units
        local integer uTypeID           = 0
        local integer id                = 0
        local integer i                 = 0
        local integer n                 = BlzGroupGetSize(visionGroup)
        local integer vIndex            = IntegerTertiaryOp(DNCycle.isDay, 1, 0)
        local unit temp
        loop
            exitwhen (i >= n)
            set temp                    = BlzGroupUnitAt(visionGroup, i)
            set id                      = GetUnitId(temp)
            set uTypeID                 = GetUnitTypeId(temp)
            loop
                exitwhen (not visionMap[vIndex].real.has(uTypeID))
                if ((GetUnitAbilityLevel(temp, ULTRAVISION) == 1) and /*
                */ (IsTechResearched(GetOwningPlayer(temp), ULTRATECH, 1))) then
                    exitwhen (not visionMap[0].real.has(uTypeID))
                endif
                call thistype.setBaseValue(temp, visionMap[vIndex].real[uTypeID])
                exitwhen true
            endloop
            loop
                exitwhen (visionMap[vIndex].real.has(uTypeID))
                call GroupAddUnit(adjustVisionGroup, temp)
                set tempBase[id]        = BlzGetUnitRealField(temp, UNIT_RF_SIGHT_RADIUS)
                if (BlzGroupGetSize(adjustVisionGroup) == 1) then
                    call GTimer[TICK].requestCallback(trackResp)
                endif
                exitwhen true
            endloop
            set i                       = i + 1
        endloop
        set temp                        = null
    endmethod

    private static method trackSightRadius takes nothing returns nothing
        //  Enumerate over all tracked units
        local integer uTypeID           = 0
        local integer id                = 0
        local integer i                 = 0
        local integer n                 = BlzGroupGetSize(adjustVisionGroup)
        local unit temp
        loop
            exitwhen (i >= n)
            set temp                    = BlzGroupUnitAt(adjustVisionGroup, i)
            set id                      = GetUnitId(temp)
            set uTypeID                 = GetUnitTypeId(temp)
            if (RAbsBJ(tempBase[id] - BlzGetUnitRealField(temp, UNIT_RF_SIGHT_RADIUS)) <= 0.01) then
                set tempBase[id]        = 0.00
                set i                   = i - 1
                set n                   = n - 1
                call GroupRemoveUnit(adjustVisionGroup, temp)
                //call BJDebugMsg("Finalizing sight radius")
                if (DNCycle.isDay) and ((GetUnitAbilityLevel(temp, ULTRAVISION) == 0) or /*
                */ (not IsTechResearched(GetOwningPlayer(temp), ULTRATECH, 1))) then
                    //call BJDebugMsg("Setting daytime sight radius")
                    set dayBase[id]     = BlzGetUnitRealField(temp, UNIT_RF_SIGHT_RADIUS)
                    if (not visionMap[1].real.has(uTypeID)) then
                        set visionMap[1].real[uTypeID]   = dayBase[id]
                    endif
                    call thistype.setBaseValue(temp, dayBase[id])
                else
                    set nightBase[id]   = BlzGetUnitRealField(temp, UNIT_RF_SIGHT_RADIUS)
                    if (not visionMap[0].real.has(uTypeID)) then
                        set visionMap[0].real[uTypeID]   = nightBase[id]
                    endif
                    call thistype.setBaseValue(temp, nightBase[id])
                endif
            else
                set tempBase[id]        = BlzGetUnitRealField(temp, UNIT_RF_SIGHT_RADIUS)
            endif
            set i                       = i + 1
        endloop
        set temp                        = null
    endmethod

    private static method init takes nothing returns nothing
        set visionMap                   = TableArray[2]
        set trackResp                   = GTimer.register(TICK, function thistype.trackSightRadius)
        set visionGroup                 = CreateGroup()
        set adjustVisionGroup           = CreateGroup()
        call DNCycle.ON_DAY.register(function thistype.changeBaseVision)
        call DNCycle.ON_NIGHT.register(function thistype.changeBaseVision)
        call UnitAuxHandler.ON_TRANSFORM.register(function thistype.transformVision)
    endmethod

    implement CUnitStatFactory
    implement Init
endstruct

endlibrary