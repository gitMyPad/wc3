do
    local native    = {
        setHeight   = BlzSetSpecialEffectHeight,
        setAlpha    = BlzSetSpecialEffectAlpha,
        dest        = DestroyEffect
    }
    local broken    = (BlzStartUnitAbilityCooldown and true) or false
    --local broken    = VersionCheck.patch ~= '1.31'
    local attr      = {height = {}, alpha = {}, vis = {}}
    local dest_flag = {}

    local function const_factory(func)
        return function(...)
            local fx        = func(...)
            attr.height[fx] = 0.
            attr.alpha[fx]  = 255.
            attr.vis[fx]    = 0
            return fx
        end
    end

    function DestroyEffect(fx)
        if dest_flag[fx] then return;
        end

        native.dest(fx)
        attr.height[fx] = nil
        attr.alpha[fx]  = nil
        attr.vis[fx]    = nil
        dest_flag[fx]   = nil
    end

    local _dest     = DestroyEffect
    local function on_destroy_effect()
        local t         = GetExpiredTimer()
        local fx        = GetTimerData(t)
        dest_flag[fx]   = nil
        _dest(fx)
        DestroyTimer(t)
    end
    function DestroyEffect(fx, dur)
        if (not dur) or (dur <= 0) then
            _dest(fx)
            return
        end
        if dest_flag[fx] then return;
        end

        dest_flag[fx]   = true
        local t         = CreateTimer()
        SetTimerData(t, fx)
        TimerStart(t, dur, false, on_destroy_effect)
    end

    AddSpecialEffect            = const_factory(AddSpecialEffect)
    AddSpecialEffectLoc         = const_factory(AddSpecialEffectLoc)
    AddSpecialEffectTarget      = const_factory(AddSpecialEffectTarget)
    AddSpellEffect              = const_factory(AddSpellEffect)
    AddSpellEffectById          = const_factory(AddSpellEffectById)
    AddSpellEffectLoc           = const_factory(AddSpellEffectLoc)
    AddSpellEffectByIdLoc       = const_factory(AddSpellEffectByIdLoc)
    AddSpellEffectTarget        = const_factory(AddSpellEffectTarget)
    AddSpellEffectTargetById    = const_factory(AddSpellEffectTargetById)

    function BlzSetSpecialEffectHeight(fx, height)
        attr.height[fx] = height
        if broken then
            height  = height + GetPointZ(BlzGetLocalSpecialEffectX(fx), BlzGetLocalSpecialEffectY(fx))
        end
        native.setHeight(fx, height)
    end
    function BlzSetSpecialEffectAlpha(fx, alpha)
        attr.alpha[fx]  = alpha
        if attr.vis[fx] >= 0 then
            native.setAlpha(fx, alpha)
        else
            native.setAlpha(fx, 0)
        end
    end

    if not BlzGetSpecialEffectHeight then
        --  A function masquerading as a native
        function BlzGetSpecialEffectHeight(fx)
            return attr.height[fx] or 0
        end
    end
    if not BlzGetSpecialEffectAlpha then
        --  A function masquerading as a native
        function BlzGetSpecialEffectAlpha(fx)
            return attr.alpha[fx] or 255
        end
    end

    function ShowEffect(fx, vis)
        if vis then
            attr.vis[fx] = attr.vis[fx] + 1
        else
            attr.vis[fx] = attr.vis[fx] - 1
        end
        BlzSetSpecialEffectAlpha(fx, attr.alpha[fx])
    end
    function IsEffectVisible(fx)
        return attr.vis[fx] >= 0
    end

    SetEffectX      = BlzSetSpecialEffectX
    SetEffectY      = BlzSetSpecialEffectY
    SetEffectZ      = BlzSetSpecialEffectZ
    SetEffectHeight = BlzSetSpecialEffectHeight
    SetEffectAlpha  = BlzSetSpecialEffectAlpha
    SetEffectColor  = BlzSetSpecialEffectColor
    SetEffectPColor = BlzSetSpecialEffectColorByPlayer

    GetEffectX      = BlzGetLocalSpecialEffectX
    GetEffectY      = BlzGetLocalSpecialEffectY
    GetEffectZ      = BlzGetLocalSpecialEffectZ
    GetEffectHeight = BlzGetSpecialEffectHeight
    GetEffectAlpha  = BlzGetSpecialEffectAlpha
end