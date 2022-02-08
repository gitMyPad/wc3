library GenericFilter /*

     ------------------------------------------------------
    |
    |       Generic Filter
    |       - MyPad
    |
    |------------------------------------------------------
    |
    |   Tired of having to declare your own filter functions
    |   for targets? Let this snippet help you. With just
    |   a single integer flagbit, you can easily filter out
    |   unwanted units.
    |
    |------------------------------------------------------
    |
    |   API:
    |
    |       function FilterTarget(unit source, unit target, integer filter) -> bool
    |           - Depending on the exact value of the flagbit specified, this
    |             function will filter out certain types of units.
    |
    |       function NewTarget(bool noBuildings, bool noMechanical, bool enemyOnly, bool allyOnly) -> integer
    |           - Returns a flagbit integer value which will filter out the
    |             types of targets as specified in the arguments.
    |           - This is mostly used to make things easier for those not yet
    |             familiar with bit manipulation.
    |
     ------------------------------------------------------
*/

native UnitAlive takes unit id returns boolean

//  What should each filter do?
//  In all cases, the filter should include certain units
//  if not succeeded by a _NO suffix. Otherwise, act to
//  exclude these units.
globals
    constant integer FILTER_ALIVE               = 0x1
    constant integer FILTER_NO_INVULNERABLE     = 0x2
    constant integer FILTER_NO_SPELL_IMMUNE     = 0x4
    constant integer FILTER_NO_STRUCTURE        = 0x8
    constant integer FILTER_NO_MECHANICAL       = 0x10
    constant integer FILTER_NO_GROUND           = 0x20
    constant integer FILTER_NO_AIR              = 0x40
    constant integer FILTER_NO_INVISIBLE        = 0x80
    constant integer FILTER_ENEMY               = 0x100
    constant integer FILTER_ALLY                = 0x200
    constant integer FILTER_HERO                = 0x400
    constant integer FILTER_RESISTANT           = 0x800
    constant integer FILTER_PURE_INVISIBLE      = 0x1000
    private  player  INVISIBLE_DETECTOR         = null
endglobals

function FilterTarget takes unit source, unit target, integer filter returns boolean
    local player pSource    = GetOwningPlayer(source)
    local player pTarget    = GetOwningPlayer(target)
    return ((BlzBitAnd(filter, FILTER_ALIVE) == 0) or (UnitAlive(target))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_INVULNERABLE) == 0) or (not BlzIsUnitInvulnerable(target))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_SPELL_IMMUNE) == 0) or (not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_STRUCTURE) == 0) or (not IsUnitType(target, UNIT_TYPE_STRUCTURE))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_MECHANICAL) == 0) or (not IsUnitType(target, UNIT_TYPE_MECHANICAL))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_GROUND) == 0) or (not IsUnitType(target, UNIT_TYPE_GROUND))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_AIR) == 0) or (not IsUnitType(target, UNIT_TYPE_FLYING))) and /*
        */ ((BlzBitAnd(filter, FILTER_NO_INVISIBLE) == 0) or (not IsUnitInvisible(target, pSource))) and /*
        */ ((BlzBitAnd(filter, FILTER_ENEMY) == 0) or (IsUnitEnemy(target, pSource))) and /*
        */ ((BlzBitAnd(filter, FILTER_ALLY) == 0) or (IsUnitAlly(target, pSource))) and /*
        */ (((BlzBitAnd(filter, FILTER_HERO) == 0) or (IsUnitType(target, UNIT_TYPE_HERO))) or /*
        */  ((BlzBitAnd(filter, FILTER_RESISTANT) == 0) or (IsUnitType(target, UNIT_TYPE_RESISTANT))) ) and /*
        */ ((BlzBitAnd(filter, FILTER_PURE_INVISIBLE) == 0) or (IsUnitInvisible(target, INVISIBLE_DETECTOR)))
endfunction

//  A basic filter for generic use.
function NewFilter takes boolean noBuildings, boolean noMechanical, boolean enemyOnly, boolean allyOnly returns integer
    local integer i = FILTER_ALIVE
    if (noBuildings) then
        set i       = i + FILTER_NO_STRUCTURE
    endif
    if (noMechanical) then
        set i       = i + FILTER_NO_MECHANICAL
    endif
    //  If both of these values are the same, then
    //  filtering if the target is an enemy or an ally
    //  is useless.
    if (enemyOnly != allyOnly) then
        if (enemyOnly) then
            set i       = i + FILTER_ENEMY
        endif
        if (allyOnly) then
            set i       = i + FILTER_ALLY
        endif
    endif
    return i
endfunction

//  =========================================================
//              Initializer function.
//  =========================================================
private module M
    private static method onInit takes nothing returns nothing
        set INVISIBLE_DETECTOR                  = Player(bj_PLAYER_NEUTRAL_VICTIM)
    endmethod
endmodule
private struct S extends array
    implement M
endstruct

endlibrary