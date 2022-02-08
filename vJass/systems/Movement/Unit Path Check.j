library UnitPathCheck requires Init, WorldBounds

globals
    private constant real DISP_THRESHOLD    = 100.0
    private constant real RECT_LENGTH       = 32.0
    private rect pathRect                   = null
    private item pathChecker                = null
    private item array tempHiddenItems      
    private integer tempIndex               = 0
    private real pathX                      = 0.0
    private real pathY                      = 0.0
endglobals

private struct UnitPathCheck extends array
    static method hideItems takes nothing returns nothing
        set tempIndex   = tempIndex + 1
        set tempHiddenItems[tempIndex]  = GetEnumItem()
        call SetItemVisible(tempHiddenItems[tempIndex], false)
    endmethod
    private static method init takes nothing returns nothing
        set pathChecker = CreateItem('ratf', WorldBounds.minX, WorldBounds.minY)
        set pathRect    = Rect(-RECT_LENGTH, -RECT_LENGTH, RECT_LENGTH, RECT_LENGTH)
        call SetItemVisible(pathChecker, false)
    endmethod
    implement Init
endstruct

function IsValidGroundPathing takes real cx, real cy returns boolean
    local real dist = 0.0
    //  Hide all present items
    call MoveRectTo(pathRect, cx, cy)
    call EnumItemsInRect(pathRect, null, function UnitPathCheck.hideItems)
    //  Place item.
    call SetItemVisible(pathChecker, true)
    call SetItemPosition(pathChecker, cx, cy)
    set pathX   = GetItemX(pathChecker)
    set pathY   = GetItemY(pathChecker)
    set dist    = (cx - pathX)*(cx - pathX) + /*
               */ (cy - pathY)*(cy - pathY)
    call SetItemPosition(pathChecker,  WorldBounds.minX, WorldBounds.minY)
    call SetItemVisible(pathChecker, false)
    //  Show all present items
    loop
        exitwhen tempIndex <= 0
        call SetItemVisible(tempHiddenItems[tempIndex], true)
        set tempIndex   = tempIndex - 1
    endloop
    return dist < DISP_THRESHOLD
endfunction
function GetGroundPathX takes nothing returns real
    return pathX
endfunction
function GetGroundPathY takes nothing returns real
    return pathY
endfunction

endlibrary