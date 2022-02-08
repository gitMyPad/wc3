library ResearchChecker requires Init, WorldBounds

globals
    private unit checker                = null
    private constant integer ABIL_ID    = '^^^^'
    private constant integer BUFF_ID    = 'BOwk'
    private constant integer UNIT_ID    = 'udet'
    private constant integer ORDER_ID   = 852129
endglobals

function IsSynergyActivated takes nothing returns boolean
    local boolean result    = false
    call PauseUnit(checker, false)
    set result              = IssueImmediateOrderById(checker, UNIT_ID) and IssueImmediateOrderById(checker, 851976)
    call PauseUnit(checker, true)
    return result
endfunction

function IsWhoisJohnGaltActivated takes nothing returns boolean
    local boolean result    = false
    call PauseUnit(checker, false)
    set result              = IssueImmediateOrderById(checker, ORDER_ID) and IssueImmediateOrderById(checker, 851972)
    call PauseUnit(checker, true)
    return result
endfunction

private struct ResearchCheck extends array
    private static method init takes nothing returns nothing
        set checker                     = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_ID, 0.0, 0.0, 0.0)
        call ShowUnit(checker, false)
        call PauseUnit(checker, true)
    endmethod
    implement Init
endstruct

function IsTechResearched takes player p, integer techID, integer level returns boolean
    return GetPlayerTechCount(p, techID, true) >= level
endfunction
function IsAbilityReqLifted takes player p, integer techID, integer level returns boolean
    return IsWhoisJohnGaltActivated() or IsTechResearched(p, techID, level)
endfunction

endlibrary