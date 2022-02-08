scope DispelTrace initializer Init

private function OnSpellEffect takes nothing returns nothing
    call BJDebugMsg("Caster's current order: " + I2S(GetUnitCurrentOrder(SpellHandler.unit)))
    call BJDebugMsg("Ability being cast: " + GetAbilityName(SpellHandler.current.curAbility))
endfunction
private function Init takes nothing returns nothing
    call SpellHandler.ON_EFFECT.register(function OnSpellEffect)
endfunction

endscope