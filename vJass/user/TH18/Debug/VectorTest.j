scope VectorTest initializer Init

private function Init takes nothing returns nothing
    local Vector v  = Vector.create(1.0, 3.0)
    local Vector v2 = Vector.create(4.0, 1.0)
    local Vector v3 = 0
    set v3          = v.add(v2)
    //  To lock an object into existence, call .lock(true)
    call v.lock(true)
endfunction

endscope