scope ClusterRockets

private module ClusterRocketConfig
    static constant method operator ABILITY_ID takes nothing returns integer
        return 'A00D'
    endmethod
    static constant method operator DUMMY_ABIL_ID takes nothing returns integer
        return 'A00E'
    endmethod
    static constant method operator DUMMY_ORDER_ID takes nothing returns integer
        return 852652
    endmethod
endmodule

private struct ClusterRockets extends array
    implement ClusterRocketConfig

    private static EventResponder       positionResp    = 0
    private static IntegerList          dummyList       = 0
    //  For Dummy owners
    private static integer array        dummyCount
    //  For Dummy objects
    private static IntegerListItem array dummyPtr

    private static method onDummyAbilEffect takes nothing returns nothing
        local unit cast         = SpellHandler.unit
        local integer unitID    = GetUnitId(cast)
        local Dummy dummy       = Dummy.request(GetOwningPlayer(cast), GetUnitX(cast), /*
                                            */  GetUnitY(cast), 0.0)
        set dummy.data          = unitID
        set dummyCount[unitID]  = dummyCount[unitID + 1]
        call dummy.addAbil(DUMMY_ABIL_ID)
        call dummy.issuePointOrderId(DUMMY_ORDER_ID, SpellHandler.current.curTargetX, /*
                                */ SpellHandler.current.curTargetY)
        
        //  Bind dummy to caster
        set dummyPtr[dummy]     = dummyList.push(dummy).last
        if (dummyList.size() == 1) then
            call GTimer[UPDATE_TICK].requestCallback(positionResp)
        endif
        set cast                = null
    endmethod

    private static method onDummyUpdatePos takes nothing returns nothing
        local IntegerListItem iter  = dummyList.first
        local Dummy dummy           = iter.data
        local unit source
        loop
            exitwhen iter == 0
            set iter    = iter.next
            //  Update dummy position only. Handle possible situational
            //  development in other threads.
            set source  = GetUnitById(dummy.data)
            loop
                if (not UnitAlive(source)) then
                    //  Issuing this order will trigger the ENDCAST callback below.
                    call dummy.issueOrderId(851972)
                    exitwhen true
                endif
                set dummy.x = GetUnitX(source)
                set dummy.y = GetUnitY(source)
                set dummy.z = GetUnitFlyHeight(source)
                exitwhen true
            endloop
            set dummy   = iter.data
        endloop
        if (dummyList.empty()) then
            call GTimer[UPDATE_TICK].releaseCallback(positionResp)
        endif
        set source      = null
    endmethod

    private static method onDummyFinishCast takes nothing returns nothing
        local Dummy dummy       = Dummy[SpellHandler.unit]
        local unit source       = GetUnitById(dummy.data)
        local integer srcID     = dummy.data
        
        //  Refresh dummy
        set dummy.paused        = true
        call dummy.removeAbil(DUMMY_ABIL_ID)
        call dummy.issueOrderId(851972)
        set dummy.paused        = false

        call dummyList.erase(dummyPtr[dummy])
        set dummyPtr[dummy]     = 0
        set dummyCount[srcID]   = dummyCount[srcID + 1]
        call dummy.recycle()

        set source              = null
    endmethod

    private static method onCasterRemove takes nothing returns nothing
        local IntegerListItem iter  = dummyList.first
        local Dummy dummy           = iter.data
        local unit uncaster         = GetIndexedUnit()
        local unit source
        local integer uncastID      = GetIndexedUnitId()

        if (dummyCount[uncastID] == 0) then
            set uncaster            = null
            return
        endif
        //  Iterate through all active instances and prune off
        //  those associated with the unit.
        loop
            exitwhen iter == 0
            set iter    = iter.next
            //  Update dummy position only. Handle possible situational
            //  development in other threads.
            loop
                set source  = GetUnitById(dummy.data)
                exitwhen (source != uncaster)
                //  Issuing this order will trigger the ENDCAST callback above.
                call dummy.issueOrderId(851972)
                exitwhen true
            endloop
            set dummy   = iter.data
        endloop
        set source      = null
        set uncaster    = null
    endmethod

    private static method onInit takes nothing returns nothing
        set dummyList           = IntegerList.create()
        set positionResp        = GTimer.register(UPDATE_TICK, function thistype.onDummyUpdatePos)
        call SpellHandler.register(EVENT_EFFECT, ABILITY_ID, function thistype.onDummyAbilEffect)
        call SpellHandler.register(EVENT_ENDCAST, DUMMY_ABIL_ID, function thistype.onDummyFinishCast)
        call OnUnitDeindex(function thistype.onCasterRemove)
    endmethod
endstruct

endscope