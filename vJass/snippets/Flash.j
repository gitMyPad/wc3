library Flash

function Flash takes real x, real y returns nothing
    call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", x, y))
endfunction

endlibrary