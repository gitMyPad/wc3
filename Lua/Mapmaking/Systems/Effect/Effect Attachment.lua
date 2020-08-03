do
    local tb    = protected_table({
        TICKS   = 32,
    })
    tb.entry    = {}
    tb.loop     = TimerIterator:create(tb.TICKS, function(self)
        SetEffectX(self.effect, GetUnitX(self.attach))
        SetEffectY(self.effect, GetUnitY(self.attach))
        SetEffectHeight(self.effect, GetUnitFlyHeight(self.attach) + self.height)

        if GetUnitTypeId(self.attach) == 0 then
            DetachEffect(self.effect)
            DestroyEffect(self.effect)
        end
    end)
    function AttachEffect(fx, whichunit, h)
        if not tb.entry[fx] then
            tb.entry[fx]        = {}
            tb.entry[fx].effect = fx
            tb.loop:insert(tb.entry[fx])
        end
        tb.entry[fx].attach = whichunit
        tb.entry[fx].height = h or 0

        SetEffectX(fx, GetUnitX(whichunit))
        SetEffectY(fx, GetUnitY(whichunit))
        SetEffectHeight(fx, GetUnitFlyHeight(whichunit) + (h or 0))
    end
    function DetachEffect(fx)
        if not tb.entry[fx] then return;
        end
        tb.loop:remove(tb.entry[fx])
        tb.entry[fx]    = nil
    end
end