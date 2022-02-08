scope UnitAuxEventTest initializer Init

private function OnUnitTransform takes nothing returns nothing
    call BJDebugMsg("A unit has transformed")
    call BJDebugMsg("The unit's previous unit type: " + UnitAuxEvents_FourCC(UnitAuxHandler.prevTransformID))
    call BJDebugMsg("The unit's current unit type: " + UnitAuxEvents_FourCC(UnitAuxHandler.curTransformID))
endfunction
private function OnUnitDeath takes nothing returns nothing
    call BJDebugMsg("A unit has dead")
    call BJDebugMsg("Current dead unit: " + GetUnitName(UnitAuxHandler.unit))
endfunction
private function OnUnitResurrect takes nothing returns nothing
    call BJDebugMsg("A unit has alive")
    call BJDebugMsg("Current alive unit: " + GetUnitName(UnitAuxHandler.unit))
endfunction
private function OnUnitLoad takes nothing returns nothing
    call BJDebugMsg("A unit has loaded")
    call BJDebugMsg("Current loaded unit: " + GetUnitName(UnitAuxHandler.unit))
    call BJDebugMsg("Current loaded transport: " + GetUnitName(UnitAuxHandler.curTransport))
endfunction
private function OnUnitUnload takes nothing returns nothing
    call BJDebugMsg("A unit has unloader")
    call BJDebugMsg("Current unloaded unit: " + GetUnitName(UnitAuxHandler.unit))
    call BJDebugMsg("Current unloaded transport: " + GetUnitName(UnitAuxHandler.curTransport))
endfunction
private function Init takes nothing returns nothing
    call UnitAuxHandler.ON_TRANSFORM.register(function OnUnitTransform)
    call UnitAuxHandler.ON_DEATH.register(function OnUnitDeath)
    call UnitAuxHandler.ON_RESURRECT.register(function OnUnitResurrect)
    call UnitAuxHandler.ON_LOAD.register(function OnUnitLoad)
    call UnitAuxHandler.ON_UNLOAD.register(function OnUnitUnload)
endfunction

endscope