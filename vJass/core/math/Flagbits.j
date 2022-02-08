library Flagbits

function IsFlagSet takes integer value, integer flag returns boolean
    return BlzBitAnd(value, flag) == flag
endfunction

function SetFlag takes integer value, integer flag returns integer
    return BlzBitOr(value, flag)
endfunction

function UnsetFlag takes integer value, integer flag returns integer
    return BlzBitAnd(value, -flag - 1)
endfunction

endlibrary
