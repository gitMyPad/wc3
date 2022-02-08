scope DamageTrace initializer Init

private function OnDamage takes nothing returns nothing
    call BJDebugMsg("Damage amount: " + R2S(DamageHandler.dmg))
    call BJDebugMsg("Damage attacktype id: " + I2S(GetHandleId(DamageHandler.attacktype)))
    call BJDebugMsg("Damage damagetype id: " + I2S(GetHandleId(DamageHandler.damagetype)))
endfunction
private function Init takes nothing returns nothing
    call DamageHandler.ON_DAMAGE.register(function OnDamage)
endfunction

endscope