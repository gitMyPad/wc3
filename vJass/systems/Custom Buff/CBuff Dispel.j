library CBuffEx requires CBuff, SpellHandler, Init

private struct BuffEx extends array
    private static group tempGroup  = null
    private static boolean array VALID_ORDER_ID

    private static method attemptDispel takes unit source, unit target, integer removeType returns nothing
        if (removeType == CustomBuff.BUFF_TYPE_BOTH) then
            call Buff.dispelEx(target, 1, false, removeType)
            return
        endif
        if (GetOwningPlayer(source) == GetOwningPlayer(target)) or /*
        */ (GetPlayerAlliance(GetOwningPlayer(source), GetOwningPlayer(target), /*
                            */ ALLIANCE_SHARED_SPELLS)) then
            call Buff.dispelEx(target, 1, false, CustomBuff.BUFF_TYPE_NEGATIVE)
        else
            call Buff.dispelEx(target, 1, false, CustomBuff.BUFF_TYPE_POSITIVE)
        endif
    endmethod
    private static method onSpellEffect takes nothing returns nothing
        local integer orderID       = GetUnitCurrentOrder(SpellHandler.unit)
        local integer removeType    = 0
        local real range            = 0.0
        local real tx
        local real ty
        local unit target
        if (not VALID_ORDER_ID[orderID - 0xD0000]) then
            return
        endif
        if (orderID == 852057) or (orderID == 852536) then
            set removeType          = CustomBuff.BUFF_TYPE_BOTH
            set range               = SpellHandler.current.curTargetAOE
            set tx                  = SpellHandler.current.curTargetX
            set ty                  = SpellHandler.current.curTargetY
            call GroupEnumUnitsInRange(tempGroup, tx, ty, range + 100.0, null)
            loop
                set target          = FirstOfGroup(tempGroup)
                exitwhen (target == null)
                call GroupRemoveUnit(tempGroup, target)

                if IsUnitInRangeXY(target, tx, ty, range) then
                    call BuffEx.attemptDispel(SpellHandler.unit, target, removeType)
                endif
            endloop
            return
        endif
        if (orderID == 852111) then
            set removeType          = CustomBuff.BUFF_TYPE_BOTH
        endif
        call BuffEx.attemptDispel(SpellHandler.unit, SpellHandler.current.curTargetUnit, removeType)
    endmethod

    private static method onObserveDispel takes nothing returns nothing
        if (DamageHandler.attacktype == ATTACK_TYPE_NORMAL) and /*
        */ (DamageHandler.damagetype == DAMAGE_TYPE_UNKNOWN) then
            call Buff.onMonitorUnitBuff(DamageHandler.target)
        endif
        if (DamageHandler.damagetype == DAMAGE_TYPE_MAGIC) and /*
        */ ((IsUnitType(DamageHandler.target, UNIT_TYPE_SUMMONED)) or /*
        */ (DamageHandler.dmg == 0.0)) then
            call BuffEx.attemptDispel(DamageHandler.source, DamageHandler.target, 0)
        endif
    endmethod

    //  ====================================================
    private static method init takes nothing returns nothing
        //  0xD0000 is the smallest baseline offset for these order ids.
        set tempGroup                           = CreateGroup()
        set VALID_ORDER_ID[852057 - 0xD0000]    = true
        set VALID_ORDER_ID[852111 - 0xD0000]    = true
        set VALID_ORDER_ID[852132 - 0xD0000]    = true
        set VALID_ORDER_ID[852536 - 0xD0000]    = true
        call DamageHandler.ON_DAMAGE.register(function BuffEx.onObserveDispel)
        call SpellHandler.ON_EFFECT.register(function BuffEx.onSpellEffect)
    endmethod
    implement Init
endstruct

endlibrary