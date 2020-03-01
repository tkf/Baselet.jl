module TestWithBase

using Base.Iterators: flatten
using Baselet
using Test

args_and_kwargs(args...; kwargs...) = args, (; kwargs...)

==ᶜ(x, y) = collect(x) == collect(y)

# Dummy implementations
accumulate(op, xs::Tuple; kw...) = Tuple(Base.accumulate(op, collect(xs); kw...))
cumsum(xs::Tuple) = Tuple(Base.cumsum(collect(xs)))
cumprod(xs::Tuple) = Tuple(Base.cumprod(collect(xs)))

raw_testdata_pure = """
getindex((100, 200, 300, 400), 2:3) ==
zip((11, 22, 33)) ==ᶜ
zip((11, 22, 33), (111, 222, 333)) ==ᶜ
accumulate(+, (11, 22, 33)) ===
accumulate(+, (11, 22, 33); init=100) ===
cumsum((11, 22, 33)) ===
cumprod((11, 22, 33)) ===
enumerate((11, 22, 33)) ==ᶜ
flatten(((11, 22), (33, 44, 55))) ==ᶜ
any((false, false, false)) ===
any((false, true, false)) ===
any((false, true, false, missing)) ===
any((false, false, false, missing)) ===
any(==(0), (10, 11, 12)) ===
any(==(10), (10, 11, 12)) ===
any(==(0), (10, 11, 12, missing)) ===
any(==(10), (10, 11, 12, missing)) ===
all((true, true, true)) ===
all((true, false, true)) ===
all((true, true, true, missing)) ===
all((true, false, true, missing)) ===
all(==(0), (10, 10, 10)) ===
all(==(10), (10, 10, 10)) ===
all(==(0), (10, 10, 10, missing)) ===
all(==(10), (10, 10, 10, missing)) ===
findfirst(()) ==
findfirst((false, true)) ==
findfirst((false, false)) ==
findfirst(==(10), ()) ==
findfirst(==(10), (11, 10, 10)) ==
findfirst(==(10), (11, 11, 11)) ==
findlast(()) ==
findlast((false, true)) ==
findlast((false, false)) ==
findlast(==(10), ()) ==
findlast(==(10), (11, 10, 10)) ==
findlast(==(10), (11, 11, 11)) ==
findall(()) ==ᶜ
findall((false, true)) ==ᶜ
findall((false, false)) ==ᶜ
findall(==(10), ()) ==ᶜ
findall(==(10), (11, 10, 10)) ==ᶜ
findall(==(10), (11, 11, 11)) ==ᶜ
findmax((1, 2, 3, 2, 3, 1)) ===
findmax((1, NaN, 2, 3, NaN, 2)) ===
findmin((1, 2, 3, 2, 3, 1)) ===
findmin((1, NaN, 2, 3, NaN, 2)) ===
argmax((1, 2, 3, 2, 3, 1)) ===
argmax((1, NaN, 2, 3, NaN, 2)) ===
argmin((1, 2, 3, 2, 3, 1)) ===
argmin((1, NaN, 2, 3, NaN, 2)) ===
maximum((1, 2, 3, 2, 3, 1)) ===
maximum((1, NaN, 2, 3, NaN, 2)) ===
minimum((1, 2, 3, 2, 3, 1)) ===
minimum((1, NaN, 2, 3, NaN, 2)) ===
extrema((1, 2, 3, 2, 3, 1)) ===
extrema((1, NaN, 2, 3, NaN, 2)) ===
in(1, (1, 2, 3)) ===
in(0, (1, 2, 3)) ===
in(0, (1, 2, 3, missing)) ===
in(1, (1, 2, 3, missing)) ===
in(missing, (missing,)) ===
in(NaN, (NaN,)) ===
in(0.0, (-0.0,)) ===
unique((11, 12, 13)) ==ᶜ
unique((11, 11, 11)) ==ᶜ
unique(abs, (11, -12, 13, 12)) ==ᶜ
unique(abs, (11, -11, 11)) ==ᶜ
union((11, 12, 13)) ==ᶜ
union((11, 12, 13), (12, 13)) ==ᶜ
union((11, 12, 13), (12, 13, 14), (15, 13, 12)) ==ᶜ
intersect((11, 12, 13)) ==ᶜ
intersect((11, 12, 13), (12, 13)) ==ᶜ
intersect((11, 12, 13), (12, 13, 14), (15, 13, 12)) ==ᶜ
setdiff((11, 12, 13), ()) ==ᶜ
setdiff((), (11, 12, 13)) ==ᶜ
setdiff((11, 12, 13), (12, 13)) ==ᶜ
setdiff((11, 12, 13), (12, 13, 14), (15, 13, 12)) ==ᶜ
"""

# An array of `(label, (f, args, kwargs, comparison))`
testdata_pure = map(split(raw_testdata_pure, "\n", keepempty = false)) do x
    f, rest = split(x, "(", limit = 2)
    input, comparison = rsplit(rest, ")", limit = 2)
    comparison = strip(comparison)
    ex = Meta.parse("DUMMY($input)")
    ex.args[1] = args_and_kwargs
    @eval ($x, ($(Symbol(f)), $ex..., $(Symbol(comparison))))
end

@testset "$label" for (label, (f, args, kwargs, ==′)) in testdata_pure
    Baselet_f = getproperty(Baselet, nameof(f))
    Specialized_f = getproperty(Baselet.Specialized, nameof(f))
    @test Baselet_f(args...; kwargs...) ==′ f(args...; kwargs...)
    @test Specialized_f(args...; kwargs...) ==′ f(args...; kwargs...)
    @test typeof(Baselet_f(args...; kwargs...)) == typeof(Specialized_f(args...; kwargs...))
end

function test_all_implementations(test)
    @testset for m in [Base, Baselet, Baselet.Specialized]
        test(m)
    end
end

@testset "foreach(x -> push!(xs, x), 1:5)" begin
    test_all_implementations() do m
        xs = Int[]
        m.foreach(1:5) do x
            push!(xs, x)
        end
        @test xs == 1:5
    end
end

@testset "foreach(x -> push!(xs, x), (1, 2, 3))" begin
    test_all_implementations() do m
        xs = Int[]
        m.foreach((1, 2, 3)) do x
            push!(xs, x)
        end
        @test xs == 1:3
    end
end

@testset "foreach((a, b) -> push!(xs, a + b), 1:5, 6:10)" begin
    test_all_implementations() do m
        xs = Int[]
        m.foreach(1:5, 6:10) do a, b
            push!(xs, a + b)
        end
        @test xs == 7:2:15
    end
end

@testset "foreach((a, b) -> push!(xs, a + b), (1, 2, 3), (6, 7, 8))" begin
    test_all_implementations() do m
        xs = Int[]
        m.foreach((1, 2, 3), (6, 7, 8)) do a, b
            push!(xs, a + b)
        end
        @test xs == 7:2:11
    end
end

end  # module
