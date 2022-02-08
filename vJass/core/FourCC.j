library FourCC

/*
    Mostly taken from this link:
    https://www.hiveworkshop.com/threads/dynamically-retrieve-object-editor-fields.307564/
*/

function CCFour takes integer value returns string // taken from Cheats.j
    local string charMap = "..................................!.#$%&'()*+,-./0123456789:;<=>.@ABCDEFGHIJKLMNOPQRSTUVWXYZ[.]^_`abcdefghijklmnopqrstuvwxyz{|}~................................................................................................................................."
    local string result = ""
    local integer remainingValue = value
    local integer charValue
    local integer byteno
    set byteno = 0
    loop
        set charValue = ModuloInteger(remainingValue, 256)
        set remainingValue = remainingValue / 256
        set result = SubString(charMap, charValue, charValue + 1) + result
        set byteno = byteno + 1
        exitwhen byteno == 4
    endloop
    return result
endfunction

function FourCC takes string char returns integer
    local string charMap = "..................................!.#$%&'()*+,-./0123456789:;<=>.@ABCDEFGHIJKLMNOPQRSTUVWXYZ[.]^_`abcdefghijklmnopqrstuvwxyz{|}~................................................................................................................................."
    local string subChar = ""
    local integer result = 0
    local integer pos    = 0
    local integer byteno
    set byteno = 0
    loop
        set subChar = SubString(char, byteno, byteno + 1)
        set result  = result*0x100
        loop
            if pos > 0x100 then
                set pos = 0
                exitwhen true
            endif
            set pos = pos + 1
            exitwhen SubString(charMap, pos, pos+1) == subChar
        endloop
        set result      = result + pos
        set pos         = 0
        set byteno      = byteno + 1
        exitwhen byteno >= 4
    endloop
    return result
endfunction

endlibrary