//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~ Alloc ~~ By Sevion ~~ Version 1.09 ~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  What is Alloc?
//         - Alloc implements an intuitive allocation method for array structs
//
//    =Pros=
//         - Efficient.
//         - Simple.
//         - Less overhead than regular structs.
//
//    =Cons=
//         - Must use array structs (hardly a con).
//         - Must manually call OnDestroy.
//         - Must use Delegates for inheritance.
//         - No default values for variables (use onInit instead).
//         - No array members (use another Alloc struct as a linked list or type declaration).
//
//    Methods:
//         - struct.allocate()
//         - struct.deallocate()
//
//           These methods are used just as they should be used in regular structs.
//
//    Modules:
//         - Alloc
//           Implements the most basic form of Alloc. Includes only create and destroy
//           methods.
//
//  Details:
//         - Less overhead than regular structs
//
//         - Use array structs when using Alloc. Put the implement at the top of the struct.
//
//         - Alloc operates almost exactly the same as default structs in debug mode with the exception of onDestroy.
//
//  How to import:
//         - Create a trigger named Alloc.
//         - Convert it to custom text and replace the whole trigger text with this.
//
//  Thanks:
//         - Nestharus for the method of allocation and suggestions on further merging.
//         - Bribe for suggestions like the static if and method names.
//         - PurgeandFire111 for some suggestions like the merging of Alloc and AllocX as well as OnDestroy stuff.
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library Alloc requires /*

    ----------------------
    */  optional Table, /*
    ----------------------

*/
module Alloc
    private thistype recycle

    static method allocate takes nothing returns thistype
        local thistype this = thistype(0).recycle
        if (this.recycle == 0) then
            if (integer(this) >= JASS_MAX_ARRAY_SIZE - 2) then
                static if thistype.DEBUG_ALLOC then
                    call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Alloc ERROR: Attempted to allocate too many instances (thistype)!")
                endif
                return 0
            endif
            set this                = thistype(integer(this) + 1)
            set thistype(0).recycle = this
        else
            set thistype(0).recycle = this.recycle
            set this.recycle        = 0
        endif
        return this
    endmethod

    method deallocate takes nothing returns nothing
        if (this.recycle != 0) then
            static if thistype.DEBUG_ALLOC then
                call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "Alloc ERROR: Attempted to deallocate an invalid (thistype) instance at [" + I2S(this) + "]!")
            endif
            return
        endif
        set this.recycle        = thistype(0).recycle
        set thistype(0).recycle = this
    endmethod
endmodule

static if LIBRARY_Table then
module AllocT
    private static Table allocMap   = 0

    static method allocate takes nothing returns thistype
        local integer this = thistype.allocMap[0]
        if 0 == thistype.allocMap[this] then
            set this                    = this + 1
            set thistype.allocMap[0]    = this
        else
            set thistype.allocMap[0]    = thistype.allocMap[this]
            call thistype.allocMap.remove(this) 
        endif
        return thistype(this)
    endmethod
    method deallocate takes nothing returns nothing
        if 0 != thistype.allocMap[this] then
            static if thistype.ALLOC_DEBUG_MODE then
                call BJDebugMsg("thistype.deallocate >> Double-free detected on instance (" + I2S(this) + ")")
            endif
            return
        endif
        set thistype.allocMap[this] = thistype.allocMap[0]
        set thistype.allocMap[0]    = this
    endmethod

    private static method onInit takes nothing returns nothing
        set thistype.allocMap       = Table.create()
    endmethod
endmodule
endif

endlibrary