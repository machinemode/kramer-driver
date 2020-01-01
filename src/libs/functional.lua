local fun = require("fun")

function fun.unique(gen)
    return fun.iter(fun.reduce(
        function(acc, value)
            if fun.index(value, acc) == nil then
                table.insert(acc, value)
            end
            return acc
        end,
        {},
        gen
    ))
end

function fun.first(gen)
    return fun.nth(1, gen)
end

---Constrain an empty table to be an array by initializing a 0 index to 0
---@param items table Array to copy (shallow) into a conventional array (keys become indexed values)
---@return table array Copy with it's first element initialized to nil
function fun.as_array(items)
    local copy = fun.totable(
        fun.map(function(item) return item end, items or {})
    )

    if copy[1] == nil then
        copy[0] = 0
    end

    return copy
end

function fun.withShallowCopy(func, items)
    return fun.map(function(item) return func(item) end, items)
end

return fun
