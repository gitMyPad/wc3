/*****************************************************************************
*
*    List<T> v2.1.2.4
*       by Bannar
*
*    Doubly-linked list.
*
******************************************************************************
*
*    Requirements:
*
*       Table by Bribe
*          hiveworkshop.com/threads/snippet-new-table.188084/
*
*       Alloc - choose whatever you like
*          e.g.: by Sevion hiveworkshop.com/threads/snippet-alloc.192348/
*
******************************************************************************
*
*    Implementation:
*
*       macro DEFINE_LIST takes ACCESS, NAME, TYPE
*
*       macro DEFINE_STRUCT_LIST takes ACCESS, NAME, TYPE
*
*          ACCESS - encapsulation, choose restriction access
*            NAME - name of list type
*            TYPE - type of values stored
*
*     Implementation notes:
*
*       - DEFINE_STRUCT_LIST macro purpose is to provide natural typecasting syntax for struct types.
*       - <NAME>Item structs inline directly into hashtable operations thus generate basically no code.
*       - Lists defined with DEFINE_STRUCT_LIST are inlined nicely into single create method and single integer array.
*
******************************************************************************
*
*    struct API:
*
*       struct <NAME>Item:
*
*        | <TYPE> data
*        | <NAME>Item next
*        | <NAME>Item prev
*
*
*       General:
*
*        | static method create takes nothing returns thistype
*        |    Default ctor.
*        |
*        | static method operator [] takes thistype other returns thistype
*        |    Copy ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
*        |
*        | method empty takes nothing returns boolean
*        |    Checks whether the list is empty.
*        |
*        | method size takes nothing returns integer
*        |    Returns size of a list.
*        |
*        | method terminated takes $TYPE$Name node returns boolean
*        |    Checks whether one has reached the end of the list.
*
*
*       Access:
*
*        | readonly <NAME>Item first
*        | readonly <NAME>Item last
*        | readonly integer count
*        |
*        | method front takes nothing returns $TYPE$
*        |    Retrieves first element.
*        |
*        | method back takes nothing returns $TYPE$
*        |    Retrieves last element.
*
*
*       Modifiers:
*
*        | method clear takes nothing returns nothing
*        |    Flushes list and recycles its nodes.
*        |
*        | method push takes $TYPE$ value returns thistype
*        |    Adds elements to the end.
*        |
*        | method unshift takes $TYPE$ value returns thistype
*        |    Adds elements to the front.
*        |
*        | method pop takes nothing returns thistype
*        |    Removes the last element.
*        |
*        | method shift takes nothing returns thistype
*        |    Removes the first element.
*        |
*        | method find takes $TYPE$ value returns $NAME$Item
*        |    Returns the first node which data equals value.
*        |
*        | method erase takes $NAME$Item node returns boolean
*        |    Removes node from the list, returns true on success.
*        |
*        | method removeElem takes $TYPE$ value returns thistype
*        |    Removes first element that equals value from the list.
*
******************************************************************************
*
*        Interfaces: (new addition)
*
*        - In the modified version, List structs now can optionally
*          implement additional functions aside from the base version
*          from the library. Some of these functions are called
*          when calling certain methods. These are documented below:
*
*        | method onInsert takes $NAME$Item node, $TYPE$ value, integer pos returns nothing
*        |    Runs upon calling push, or unshift.
*        |
*        | method onRemove takes $NAME$Item node, $TYPE$ value, boolean clearing returns nothing
*        |    Runs for each node when the list is being cleared or destroyed,
*        |    or when a node is removed via erase, removeElem, shift, pop, 
*        |    destroy.
*        |
*        | method destructor takes nothing returns nothing
*        |    Runs when the list is destroyed.
*
*****************************************************************************/
library DLList requires /*

    ===============
    */ Table,    /*
    ===============
        - Bribe
        - link: https://www.hiveworkshop.com/threads/snippet-new-table.188084/
    
    ===============
    */ Alloc,    /*
    ===============
        - Sevion
        - link: https://www.hiveworkshop.com/threads/snippet-alloc.192348/

    ======================
    */  optional Init,  /*
    ======================

     ---------------------------
    |
    |   DLList
    |
    |---------------------------
    |
    |   - A doubly linked list library written by Bannar.
    |     Updated to include external functionality to
    |     the base struct via modules.
    |
     ---------------------------

*/

//! textmacro_once DEFINE_LIST takes PRIVACY, NAME, TYPE
static if not LIBRARY_Init then
private module $NAME$Init
    private static method onInit takes nothing returns nothing
        call thistype.init()
    endmethod
endmodule
endif

$PRIVACY$ struct $NAME$Item extends array
    implement AllocT

    private static Table dataMap    = 0
    private static Table nextMap    = 0
    private static Table prevMap    = 0

    method operator data takes nothing returns $TYPE$
        return thistype.dataMap.$TYPE$[integer(this)]
    endmethod
    method operator next takes nothing returns thistype
        return thistype.nextMap[integer(this)]
    endmethod
    method operator prev takes nothing returns thistype
        return thistype.prevMap[integer(this)]
    endmethod

    method operator data= takes $TYPE$ value returns nothing
        set thistype.dataMap.$TYPE$[integer(this)]    = value
    endmethod
    method operator next= takes thistype value returns nothing
        set thistype.nextMap[integer(this)]           = value
    endmethod
    method operator prev= takes thistype value returns nothing
        set thistype.prevMap[integer(this)]           = value
    endmethod

    //  System only method. Do not touch!
    method destroy takes nothing returns nothing
        call thistype.dataMap.$TYPE$.remove(integer(this))
        call thistype.nextMap.remove(integer(this))
        call thistype.prevMap.remove(integer(this))
        call this.deallocate()
    endmethod

    private static method init takes nothing returns nothing
        set dataMap = Table.create()
        set nextMap = Table.create()
        set prevMap = Table.create()
    endmethod
    static if not LIBRARY_Init then
    implement $NAME$Init
    else
    implement Init
    endif
endstruct

$PRIVACY$ struct $NAME$ extends array
    implement Alloc

    private  static Table ownerMap   = 0

    private  boolean    activated
    private  integer    clearCount
    readonly $NAME$Item first
    readonly $NAME$Item last
    readonly integer    count

    method inList takes $NAME$Item node returns boolean
        return integer(thistype.ownerMap[node]) == integer(this)
    endmethod

    implement optional $NAME$Extras

    private static method createNode takes thistype owner returns $NAME$Item
        local $NAME$Item obj        = $NAME$Item.allocate()
        set thistype.ownerMap[obj]  = owner
        return obj
    endmethod

    private static method deleteNode takes $NAME$Item node returns nothing
        local thistype owner        = thistype.ownerMap[node]
        local boolean pointZero     = false
        if node == 0 then
            return
        endif
        set owner.count             = owner.count - 1
        if node == owner.first then
            set pointZero           = true
            set owner.first         = node.next
            set owner.first.prev    = node.prev
        endif
        if node == owner.last then
            set pointZero           = true
            set owner.last          = node.prev
            set owner.last.next     = node.next
        endif
        if (not pointZero) then
            set node.next.prev          = node.prev
            set node.prev.next          = node.next
        endif
        call thistype.ownerMap.remove(node)
        static if thistype.onRemove.exists then
            call owner.onRemove(node, node.data, owner.clearCount > 0)
        endif
        call node.destroy()
    endmethod

    static method create takes nothing returns thistype
        local thistype this         = thistype.allocate()
        set this.activated          = true
        set this.count              = 0
        set this.clearCount         = 0
        return this
    endmethod

    method push takes $TYPE$ value returns thistype
        local $NAME$Item obj        = thistype.createNode(this)
        set this.count              = this.count + 1
        if this.count == 1 then
            set this.first          = obj
            set obj.next            = 0
            set obj.prev            = 0
        else
            set obj.prev            = this.last
            set obj.next            = this.last.next
            set this.last.next      = obj
        endif
        set this.last               = obj
        set obj.data                = value
        static if thistype.onInsert.exists then
            call this.onInsert(obj, value, this.count)
        endif
        return this
    endmethod

    method unshift takes $TYPE$ value returns thistype
        local $NAME$Item obj        = thistype.createNode(this)
        set this.count              = this.count + 1
        if this.count == 1 then
            set this.last           = obj
            set obj.next            = 0
            set obj.prev            = 0
        else
            set obj.next            = this.first
            set obj.prev            = this.first.prev
            set this.first.prev     = obj
        endif
        set this.first              = obj
        set obj.data                = value
        static if thistype.onInsert.exists then
            call this.onInsert(obj, value, 1)
        endif
        return this
    endmethod

    method pop takes nothing returns thistype
        local $NAME$Item node   = this.last
        if (this.count < 1) then
            return this
        endif
        call thistype.deleteNode(node)
        return this
    endmethod

    method shift takes nothing returns thistype
        local $NAME$Item node   = this.first
        if (this.count < 1) then
            return this
        endif
        call thistype.deleteNode(node)
        return this
    endmethod

    method erase takes $NAME$Item obj returns boolean
        if (integer(thistype.ownerMap[obj]) != integer(this)) or /*
        */ (this.count < 1) then
            return false
        endif
        call thistype.deleteNode(obj)
        return true
    endmethod

    method remove takes $NAME$Item obj returns boolean
        return this.erase(obj)
    endmethod

    method find takes $TYPE$ value returns $NAME$Item
        local $NAME$Item iter   = this.first
        loop
            exitwhen this.terminated(iter) or iter.data == value
            set iter    = iter.next
        endloop
        return iter
    endmethod

    method removeElem takes $TYPE$ value returns thistype
        local $NAME$Item iter   = this.find(value)
        if iter == 0 then
            return this
        endif
        call thistype.deleteNode(iter)
        return this
    endmethod

    method terminated takes $NAME$Item node returns boolean
        return (node == $NAME$Item(0))
    endmethod

    method empty takes nothing returns boolean
        return this.count == 0
    endmethod

    method size takes nothing returns integer
        return this.count
    endmethod

    method front takes nothing returns $TYPE$
        return this.first.data
    endmethod

    method back takes nothing returns $TYPE$
        return this.last.data
    endmethod

    method clear takes nothing returns integer
        local $NAME$Item iter   = this.first
        local $NAME$Item cur    = iter
        local integer count     = IMaxBJ(this.count, 0)
        if this.clearCount > 0 then
            return 0
        endif
        set this.clearCount     = this.clearCount + 1
        loop
            exitwhen (this.count < 1) or (this.terminated(iter))
            set iter            = iter.next
            call thistype.deleteNode(cur)
            set cur             = iter
        endloop
        set this.clearCount     = this.clearCount - 1
        return count
    endmethod

    method destroy takes nothing returns nothing
        if not this.activated then
            return
        endif
        set this.activated  = false
        call this.clear()
        static if thistype.destructor.exists then
            call this.destructor()
        endif

        set this.count      = 0
        set this.clearCount = 0
        call this.deallocate()
    endmethod

    method get takes integer index returns $NAME$Item
        local $NAME$Item iter   = this.first
        if (index < 1) or (index > this.count) then
            return $NAME$Item(0)
        endif
        loop
            exitwhen (index < 2) or this.terminated(iter)
            set iter    = iter.next
            set index   = index - 1
        endloop
        return index
    endmethod

    static method operator [] takes thistype other returns thistype
        local thistype this     = thistype.create()
        local $NAME$Item iter   = other.first
        loop
            exitwhen other.terminated(iter)
            call this.push(iter.data)
            set iter            = iter.next
        endloop
        return this
    endmethod

    private static method init takes nothing returns nothing
        set thistype.ownerMap   = Table.create()
    endmethod
    static if not LIBRARY_Init then
    implement $NAME$Init
    else
    implement Init
    endif
endstruct
//! endtextmacro

//! runtextmacro DEFINE_LIST("", "IntegerList", "integer")

//! textmacro_once DEFINE_STRUCT_LIST takes ACCESS, NAME, TYPE
$ACCESS$ struct $NAME$Item extends array
    // Cannot inherit methods via delegate due to limited array size
    method operator data takes nothing returns $TYPE$
        return IntegerListItem(this).data
    endmethod
    method operator data= takes $TYPE$ value returns nothing
        set IntegerListItem(this).data = value
    endmethod

    method operator next takes nothing returns thistype
        return IntegerListItem(this).next
    endmethod
    method operator next= takes thistype value returns nothing
        set IntegerListItem(this).next = value
    endmethod

    method operator prev takes nothing returns thistype
        return IntegerListItem(this).prev
    endmethod
    method operator prev= takes thistype value returns nothing
        set IntegerListItem(this).prev = value
    endmethod
endstruct

$ACCESS$ struct $NAME$ extends array
    private delegate IntegerList parent

    static method create takes nothing returns thistype
        local thistype this = IntegerList.create()
        set parent = this
        return this
    endmethod

    method front takes nothing returns $TYPE$
        return parent.front()
    endmethod

    method back takes nothing returns $TYPE$
        return parent.back()
    endmethod
endstruct
//! endtextmacro
endlibrary

library ListT requires DLList
endlibrary