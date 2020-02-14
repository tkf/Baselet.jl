module Utils

using Base.Meta: isexpr
using ..Specialized

function spec_lhs_rhs(ex)
    if isexpr(ex, :where)
        lhs, rhs = spec_lhs_rhs(ex.args[1])
        return Expr(:where, lhs, ex.args[2:end]...), rhs
    elseif isexpr(ex, :call)
        f = ex.args[1]
        @assert f isa Symbol
        spec = Expr(:call, :($Specialized.$f), ex.args[2:end]...)
        @debug "@def -> spec_lhs_rhs" ex spec
        rhs = strip_typeassert(spec)
        if isexpr(get(rhs.args, 2, nothing), :parameters)
            rhs.args[2].args .= map(rhs.args[2].args) do x
                if isexpr(x, :kw)
                    Expr(:kw, x.args[1], x.args[1])
                else
                    x
                end
            end
        end
        return (spec, rhs)
    else
        error("Cannot handle expression: ", ex)
    end
end

function strip_typeassert(ex)
    if isexpr(ex, :(::))
        length(ex.args) == 2 ||
            error("argument name is required for `@def`. Got:\n", ex)
        return ex.args[1]
    elseif ex isa Expr
        return Expr(ex.head, map(strip_typeassert, ex.args)...)
    else
        return ex
    end
end

"""
    @def f(...) = ...
    @def function f(...) ... end

Expand function definition for function `f` to:

```julia
@inline \$f(...) = Specialized.\$f(...)
@inline Specialized.\$f(...) = ...
```
"""
macro def(ex)
    @assert ex.head in [:function, :(=)]
    @assert length(ex.args) == 2
    lhs, rhs = spec_lhs_rhs(ex.args[1])
    block = Expr(:block, __source__, rhs)
    quote
        @inline $(ex.args[1]) = $block
        @inline $lhs = $(ex.args[2])
    end |> esc
end

end  # module
using .Utils: @def
