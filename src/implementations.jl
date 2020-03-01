# Vendoring `Base.afoldl`
afoldl(op,a) = a
afoldl(op,a,b) = op(a,b)
afoldl(op,a,b,c...) = afoldl(op, op(a,b), c...)
function afoldl(op,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,qs...)
    y = op(op(op(op(op(op(op(op(op(op(op(op(op(op(op(a,b),c),d),e),f),g),h),i),j),k),l),m),n),o),p)
    for x in qs; y = op(y,x); end
    y
end

@inline getindex(x, inds...) = Base.getindex(x, inds...)
@def getindex(xs::Tuple, ind::UnitRange) = ntuple(i -> xs[ind[i]], length(ind))

@inline filter(f, xs) = Base.filter(f, xs)
@def filter(f::F, xs::Tuple) where {F} =
    afoldl((ys, x) -> f(x) ? (ys..., x) : ys, (), xs...)

zip(x, xs...) = Base.zip(x, xs...)

# Not using `zip(tuples::NTuple{N,Any}...)` to avoid having unbound
# type parameter.
@def function zip(x::NTuple{N,Any}, xs::NTuple{N,Any}...) where {N}
    tuples = (x, xs...)
    return ntuple(i -> map(t -> t[i], tuples), N)
end

@inline flatten(itr) = Iterators.flatten(itr)

@def flatten(xs::Tuple) = _flatten(xs...)
@inline _flatten() = ()
@inline _flatten(x::Tuple, xs::Tuple...) = (x..., _flatten(xs...)...)

@inline enumerate(itr) = Base.enumerate(itr)

@def enumerate(xs::Tuple) = Specialized.zip(ntuple(identity, length(xs)), xs)

struct _InitialValue end

struct BottomRF{T}
    rf::T
end

@inline (op::BottomRF)(::_InitialValue, x) = Base.reduce_first(op.rf, x)
@inline (op::BottomRF)(acc, x) = op.rf(acc, x)

@inline accumulate(args...; kw...) = Base.accumulate(args...; kw...)

@def function accumulate(op::F, xs::Tuple; init = _InitialValue()) where {F}
    rf = BottomRF(op)
    ys, = afoldl(((), init), xs...) do (ys, acc), x
        acc = rf(acc, x)
        (ys..., acc), acc
    end
    return ys
end

@inline cumsum(args...; kw...) = Base.cumsum(args...; kw...)
@def cumsum(xs::Tuple) = Specialized.accumulate(Base.add_sum, xs)

@inline cumprod(args...; kw...) = Base.cumprod(args...; kw...)
@def cumprod(xs::Tuple) = Specialized.accumulate(Base.mul_prod, xs)

@inline foreach(f, xs, rest...) = Base.foreach(f, xs, rest...)

# Not using `@def` so that `Specialized.foreach` is always defined via `foldl`.
@inline foreach(f, xs::Tuple, rest::Tuple...) = Specialized.foreach(f, xs, rest...)
@inline Specialized.foreach(f, xs) = afoldl((_, x) -> (f(x); nothing), nothing, xs...)
@inline Specialized.foreach(f, xs, rest...) =
    afoldl((_, args) -> (f(args...); nothing), nothing, zip(xs, rest...)...)
# https://github.com/JuliaLang/julia/pull/31901

@inline any(f, itr) = Base.any(f, itr)
@inline any(itr) = Base.any(itr)

@def any(xs::Tuple) = _any(identity, xs...)
@def any(f::F, xs::Tuple) where {F} = _any(f, xs...)
@inline _any(f) = false
@inline function _any(f::F, x, xs...) where {F}
    y = f(x)
    y === true && return true
    return y | _any(f, xs...)
end

@inline all(f, itr) = Base.all(f, itr)
@inline all(itr) = Base.all(itr)

@def all(xs::Tuple) = _all(identity, xs...)
@def all(f::F, xs::Tuple) where {F} = _all(f, xs...)
@inline _all(f) = true
@inline function _all(f::F, x, xs...) where {F}
    y = f(x)
    y === false && return false
    return y & _all(f, xs...)
end

@inline findfirst(xs) = Base.findfirst(xs)
@inline findfirst(f, xs) = Base.findfirst(f, xs)
@def findfirst(xs::Tuple{Vararg{Bool}}) = _findfirst(identity, 1, xs...)
@def findfirst(f::F, xs::Tuple) where {F} = _findfirst(f, 1, xs...)
@inline _findfirst(f, n) = nothing
@inline _findfirst(f::F, n, x, xs...) where {F} = f(x) ? n : _findfirst(f, n + 1, xs...)

@inline findlast(xs) = Base.findlast(xs)
@inline findlast(f, xs) = Base.findlast(f, xs)
@def findlast(xs::Tuple{Vararg{Bool}}) = _findlast(identity, 1, xs...)
@def findlast(f::F, xs::Tuple) where {F} = _findlast(f, 1, xs...)
@inline _findlast(f, n) = nothing
@inline function _findlast(f::F, n, x, xs...) where {F}
    i = _findlast(f, n + 1, xs...)
    i === nothing || return i
    return f(x) ? n : nothing
end

@inline findall(xs) = Base.findall(xs)
@inline findall(f, xs) = Base.findall(f, xs)
@def findall(xs::Tuple{Vararg{Bool}}) = _findall(identity, 1, xs...)
@def findall(f::F, xs::Tuple) where {F} = _findall(f, 1, xs...)
@inline _findall(f, n) = ()
@inline _findall(f, n, x, xs...) = ((f(x) ? (n,) : ())..., _findall(f, n + 1, xs...)...)

@inline findmax(args...; kw...) = Base.findmax(args...; kw...)
@def findmax(xs::Tuple{}) = throw(ArgumentError("collection must be non-empty"))
@def findmax(xs::Tuple) = _findmax(zip(xs, ntuple(identity, length(xs)))...)
@inline _findmax(ans) = ans
@inline function _findmax((x, i), (y, j), rest...)
    x != x && return (x, i)
    return _findmax(y != y || isless(x, y) ? (y, j) : (x, i), rest...)
end

@inline findmin(args...; kw...) = Base.findmin(args...; kw...)
@def findmin(xs::Tuple{}) = throw(ArgumentError("collection must be non-empty"))
@def findmin(xs::Tuple) = _findmin(zip(xs, ntuple(identity, length(xs)))...)
@inline _findmin(ans) = ans
@inline function _findmin((x, i), (y, j), rest...)
    x != x && return (x, i)
    return _findmin(y != y || isless(y, x) ? (y, j) : (x, i), rest...)
end

@inline argmax(args...; kw...) = Base.argmax(args...; kw...)
@def argmax(xs::Tuple) = Specialized.findmax(xs)[2]

@inline argmin(args...; kw...) = Base.argmin(args...; kw...)
@def argmin(xs::Tuple) = Specialized.findmin(xs)[2]

@inline maximum(args...; kw...) = Base.maximum(args...; kw...)
@def maximum(xs::Tuple) = Specialized.findmax(xs)[1]

@inline minimum(args...; kw...) = Base.minimum(args...; kw...)
@def minimum(xs::Tuple) = Specialized.findmin(xs)[1]

@inline extrema(args...; kw...) = Base.extrema(args...; kw...)
@def extrema(xs::Tuple{}) = throw(ArgumentError("collection must be non-empty"))
@def extrema(xs::Tuple) = Specialized.extrema(identity, xs)
@def extrema(f, xs::Tuple{}) = throw(ArgumentError("collection must be non-empty"))
@def function extrema(f::F, xs::Tuple) where {F}
    x = xs[1]
    x != x && return (x, x)
    return _extrema(f, (x, x), Base.tail(xs)...)
end
@inline _extrema(f, ans) = ans
@inline function _extrema(f::F, (l, g), x, xs...) where {F}
    x != x && return (x, x)
    return _extrema(f, (isless(x, l) ? x : l, isless(g, x) ? x : g), xs...)
end

@inline in(x, xs) = Base.in(x, xs)
@inline in(x) = Base.Fix2(in, x)
@inline Specialized.in(x) = Base.Fix2(Specialized.in, x)
@def in(x, xs::Tuple) = _any(==(x), xs...)

@inline unique(f, itr) = Base.unique(f, itr)
@inline unique(itr) = Base.unique(itr)
@def unique(xs::Tuple{}) = ()
@def unique(xs::Tuple) =
    afoldl((), xs...) do xs′, x
        x in xs′ ? xs′ : (xs′..., x)
    end
@def unique(f, xs::Tuple{}) = ()
@def function unique(f::F, xs::Tuple) where {F}
    ys = map(f, xs)
    xs′, = afoldl(((), ()), zip(xs, ys)...) do (xs, ys), (x, y)
        y in ys ? (xs, ys) : ((ys..., y), (xs..., x))
    end
    return xs′
end

@inline union(args...) = Base.union(args...)

@def union(a::Tuple) = Specialized.unique(a)
@def union(a::Tuple, b::Tuple) = unique((a..., b...))
@def union(a::Tuple, bs::Tuple...) = afoldl(union, a, bs...)

@inline intersect(s, itrs...) = Base.intersect(s, itrs...)
@def intersect(a::Tuple) = a
@def intersect(a::Tuple{}, b::Tuple{}) = ()
@def intersect(a::Tuple, b::Tuple{}) = ()
@def intersect(a::Tuple{}, b::Tuple) = ()
@def intersect(a::Tuple, b::Tuple) = unique(filter(x -> x in b, a))

@def intersect(a::Tuple, b::Tuple, cs::Tuple...) =
    foldl(Specialized.intersect, cs, init = Specialized.intersect(a, b))

@inline setdiff(args...) = Base.setdiff(args...)
@def setdiff(a::Tuple, b::Tuple{}) = a
@def setdiff(a::Tuple, b::Tuple) = setdiff(_exclude(a, b[1]), Base.tail(b))
@inline _exclude(a, b) = Base.foldl((ys, x) -> x == b ? ys : (ys..., x), a; init = ())

@def setdiff(a::Tuple, b::Tuple, cs::Tuple...) =
    Base.foldl(Specialized.setdiff, cs, init = Specialized.setdiff(a, b))

@def symdiff(a::Tuple, b::Tuple) =
    foldl(b; init = a) do a, x
        i = findfirst(==(x), a)
        i == nothing ? (a..., x) : _deleteat(a, i)
    end
@def symdiff(a::Tuple, b::Tuple, cs::Tuple...) =
    foldl(Specialized.symdiff, cs, init = Specialized.symdiff(a, b))

_deleteat(a, i::Int) =
    foldl(a; init = ((), 1)) do (ys, j), x
        ((i == j ? ys : (ys..., x)), j + 1)
    end

@inline issubset(a, b) = Base.issubset(a, b)
@def issubset(a::Tuple, b::Tuple) = Specialized.all(x -> x in b, a)

if VERSION >= v"1.5"
    @inline isdisjoint(a, b) = Base.isdisjoint(a, b)
else
    @inline isdisjoint(a, b) = isempty(intersect(a, b))
end
@def isdisjoint(a::Tuple, b::Tuple) = !Specialized.any(x -> x in b, a)

sort(v; kw...) = Base.sort(v; kw...)

@def sort(
    v::Tuple;
    lt = isless,
    by = identity,
    rev::Union{Bool,Nothing} = nothing,
    order = Base.Forward,
) = _sort(Base.ord(lt, by, rev, order), v)

@inline _sort(order, ::Tuple{}) = ()
@inline _sort(order, x::Tuple{Any}) = x
@inline _sort(order, (x, y)::Tuple{Any,Any}) = Base.lt(order, y, x) ? (y, x) : (x, y)
@inline function _sort(order, v)
    left, right = _halve(v)
    return _mergesorted(order, _sort(order, left), _sort(order, right))
end

@inline _mergesorted(order, ::Tuple{}, ::Tuple{}) = ()
@inline _mergesorted(order, ::Tuple{}, right) = right
@inline _mergesorted(order, left, ::Tuple{}) = left
@inline function _mergesorted(order, left, right)
    a = left[1]
    b = right[1]
    if Base.lt(order, b, a)
        return (b, _mergesorted(order, left, Base.tail(right))...)
    else
        return (a, _mergesorted(order, Base.tail(left), right)...)
    end
end

@inline function _halve(v::NTuple{N,Any}) where {N}
    m = N ÷ 2
    return (getindex(v, 1:m), getindex(v, m+1:N))
end

# Compilation takes too long (> 10 sec) for `length(v::Tuple) > 13`.
const Any14{N} =
    Tuple{Any,Any,Any,Any,Any,Any,Any,Any,Any,Any,Any,Any,Any,Any,Vararg{Any,N}}
@nospecialize
sort(v::Any14; kw...) = Tuple(Base.sort!(collect(v); kw...))
@specialize
