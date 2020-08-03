do
    local function foo()
        if VersionCheck.patch ~= "1.31" then return;
        end

        local timer     = CreateTimer()
        local PERIOD    = 30.00
        Initializer("SYSTEM", function()
            TimerStart(timer, PERIOD, true, function()
                collectgarbage()
                collectgarbage()
            end)
        end)
    end
    foo()
end