--[[

------------------------------
--  EventListener Add-ons   --
--      v.1.0.3.0           --
------------------------------
--          MyPad           --
------------------------------

 ----------------------------------------------------------------------
|                   |--         Add-on API           --|
|----------------------------------------------------------------------
|
|        EventListener:get_stack_size()
|            - Returns the number of functions present in the
|              EventListener object.
|
|        EventListener:getf(index)
|            - <index> is an integer.
|            - Returns a function from a given index.
|            - Proper index values are from 1 to
|              EventListener:get_stack_size()
|
|        EventListener:is_function_in(func)
|            - Returns false if the function is not present
|              in the EventListener object, and true otherwise.
|
|        EventListener:swap(func1, func2)
|            - <func1> and <func2> are functions.
|            - Swaps the order of two functions iff both
|              functions are present in the EventListener
|              object.
|
 ----------------------------------------------------------------------
]]
if EventListener then
do
    -- Here, DoNothing is actually doing something for the codebase
    -- by being the default value in place of nil for function getters.
    local DoNothing = DoNothing

    ---Gets the size of the list of functions.
    ---@return integer
    EventListener.get_stack_size    = EventListener.__len

    ---Gets the function at the requested index.
    ---Due to the possibility of the list being disjointed,
    ---this may have a worst case of a O(n) time complexity.
    ---@return integer
    function EventListener:getf(index)
        if (self._funcList[index] == nil) then
            local iBuffer = 1
            while (index + iBuffer <= #self._funcList) do
                if (self._funcList[index + iBuffer] ~= nil) then
                    return self._funcList[index + iBuffer]
                end
                iBuffer = iBuffer + 1
            end
            return DoNothing
        end
        return self._funcList[index]
    end

    ---Checks if the function is already registered to this
    ---Event Listener.
    ---@return boolean
    function EventListener:is_function_in(func)
        return self._funcMap[func] ~= nil
    end

    ---Swaps the position of two functions within the list.
    ---Returns true if successful, false otherwise.
    ---@return boolean 
    function EventListener:swap(func1, func2)
        if ((self._funcMap[func1] == nil) or
            (self._funcMap[func2] == nil)) then
            return false
        end
        local tempI        = self._funcMap[func1]
        local tempI2       = self._funcMap[func2]
        local tempA, tempC = self._funcAbleCounter[tempI], self._funcCallCounter[tempI]

        self._funcMap[func1]            = tempI2
        self._funcList[tempI]           = func2
        self._funcAbleCounter[tempI]    = self._funcAbleCounter[tempI2]
        self._funcCallCounter[tempI]    = self._funcCallCounter[tempI2]

        self._funcMap[func2]            = tempI
        self._funcList[tempI2]          = func1
        self._funcAbleCounter[tempI2]   = tempA
        self._funcCallCounter[tempI2]   = tempC

        if (self._curFunc == func1) then
            self._curIndex  = tempI2
        elseif (self._curFunc == func2) then
            self._curIndex  = tempI
        end
        return true
    end
end

elseif OnGlobalInit then
do
    OnGameStart(
    function()
        print("Event Listener Add-ons >> You do not have EventListener installed.")
    end)
end

else
do
    TimerStart(CreateTimer(), 0.00, false,
    function()
        print("Event Listener Add-ons >> Please install Global Initialization first so that " ..
            "the error message can properly be propagated.")
        print("Link to Global initialization: https://www.hiveworkshop.com/threads/global-initialization.317099/")
    end)
end

end
