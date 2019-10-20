local Operators = {
    add    = function(left, right) return left + right end,
    sub    = function(left, right) return left - right end,
    mul    = function(left, right) return left * right end,
    div    = function(left, right) return left / right end,
    idiv   = function(left, right) return left // right end,
    mod    = function(left, right) return left % right end,
    pow    = function(left, right) return left ^ right end,
    concat = function(left, right) return left .. right end,
    band   = function(left, right) return left & right end,
    bor    = function(left, right) return left | right end,
    bxor   = function(left, right) return left ~ right end,
    bnot   = function(left, right) return left ~ right end,
    shl    = function(left, right) return left << right end,
    shr    = function(left, right) return left >> right end,
    eq     = function(left, right) return left == right end,
    lt     = function(left, right) return left < right end,
    le     = function(left, right) return left <= right end,
    onTable = function(left, right, fn)
        if type(left) == "table" then
            if type(right) == "table" then
                return fn(left.current, right.current)
            else
                return fn(left.current, right)
            end
        else
            if type(right) == "table" then
                return fn(left, right.current)
            else
                return fn(left, right)
            end
        end
    end
}

return Operators