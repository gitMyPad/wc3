library TimedEffect requires Alloc, TimerUtils

private struct TimedEffect extends array
    implement Alloc

    private effect effect

    private static method onEffectDeath takes nothing returns nothing
        local thistype this = ReleaseTimer(GetExpiredTimer())
        call DestroyEffect(this.effect)
        call this.deallocate()
    endmethod

    static method create takes string model, real x, real y, real dur returns thistype
        local thistype this = thistype.allocate()
        set this.effect     = AddSpecialEffect(model, x, y)
        call TimerStart(NewTimerEx(this), dur, false, function thistype.onEffectDeath)
        return this
    endmethod

    static method createTarget takes string model, widget targ, string attach, real dur returns thistype
        local thistype this = thistype.allocate()
        set this.effect     = AddSpecialEffectTarget(model, targ, attach)
        call TimerStart(NewTimerEx(this), dur, false, function thistype.onEffectDeath)
        return this
    endmethod
endstruct

function AddSpecialEffectTimed takes string model, real x, real y, real dur returns nothing
    call TimedEffect.create(model, x, y, dur)
endfunction
function AddSpecialEffectTargetTimed takes string model, widget targ, string attach, real dur returns nothing
    call TimedEffect.createTarget(model, targ, attach, dur)
endfunction

endlibrary