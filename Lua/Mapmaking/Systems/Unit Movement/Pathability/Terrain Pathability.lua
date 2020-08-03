--[[
TerrainPathability
//******************************************************************************
//* BY: Rising_Dusk
//* 
//* This script can be used to detect the type of pathing at a specific point.
//* It is valuable to do it this way because the IsTerrainPathable is very
//* counterintuitive and returns in odd ways and aren't always as you would
//* expect. This library, however, facilitates detecting those things reliably
//* and easily.
//* 
//******************************************************************************
//* 
//*    > function IsTerrainDeepWater    takes real x, real y returns boolean
//*    > function IsTerrainShallowWater takes real x, real y returns boolean
//*    > function IsTerrainLand         takes real x, real y returns boolean
//*    > function IsTerrainPlatform     takes real x, real y returns boolean
//*    > function IsTerrainWalkable     takes real x, real y returns boolean
//* 
//* These functions return true if the given point is of the type specified
//* in the function's name and false if it is not. For the IsTerrainWalkable
//* function, the MAX_RANGE constant below is the maximum deviation range from
//* the supplied coordinates that will still return true.
//* 
//* The IsTerrainPlatform works for any preplaced walkable destructable. It will
//* return true over bridges, destructable ramps, elevators, and invisible
//* platforms. Walkable destructables created at runtime do not create the same
//* pathing hole as preplaced ones do, so this will return false for them. All
//* other functions except IsTerrainWalkable return false for platforms, because
//* the platform itself erases their pathing when the map is saved.
//* 
//* After calling IsTerrainWalkable(x, y), the following two global variables
//* gain meaning. They return the X and Y coordinates of the nearest walkable
//* point to the specified coordinates. These will only deviate from the
//* IsTerrainWalkable function arguments if the function returned false.
//* 
//* 
]]
do
    local tb                = protected_table()
    tb.MAX_RANGE            = 10.
    tb.DUMMY_ITEM_ID        = FourCC('wolg')
    TerrainPathability      = setmetatable({}, tb)

    function IsTerrainDeepWater(x, y)
        return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
               and IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
    end
    function IsTerrainShallowWater(x, y)
        return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
           and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)
           and IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
    end
    function IsTerrainLand(x, y)
        return IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
    end
    function IsTerrainPlatform(x, y)
        return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY) 
           and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) 
           and not IsTerrainPathable(x, y, PATHING_TYPE_BUILDABILITY)
    end

    function tb._HideItem()
        if IsItemVisible(GetEnumItem()) then
            tb._Hid[tb._HidMax] = GetEnumItem()
            SetItemVisible(tb._Hid[tb._HidMax], false)
            tb._HidMax = tb._HidMax + 1
        end
    end
    function IsTerrainWalkable(x, y)
        --Hide any items in the area to avoid conflicts with our item
        MoveRectTo(tb._Find, x, y)
        EnumItemsInRect(tb._Find, nil, tb._HideItem)
        --Try to move the test item and get its coords
        SetItemPosition(tb._Item, x, y) --Unhides the item
        local X = GetItemX(tb._Item)
        local Y = GetItemY(tb._Item)
        SetItemVisible(tb._Item, false)--Hide it again
        --Unhide any items hidden at the start
        while tb._HidMax > 0 do
            tb._HidMax = tb._HidMax - 1
            SetItemVisible(Hid[tb._HidMax], true)
            Hid[tb._HidMax] = null
        end
        --Return walkability
        return ((X-x)*(X-x)+(Y-y)*(Y-y) <= tb.MAX_RANGE*tb.MAX_RANGE 
           and not IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY)), X, Y
    end

    Initializer("SYSTEM", function()
        tb._Find    = Rect(0., 0., 128., 128.)
        tb._Item    = CreateItem(tb.DUMMY_ITEM_ID, 0, 0)
        tb._Hid     = {}
        tb._HidMax  = 0
        SetItemVisible(tb._Item, false)
    end)
end