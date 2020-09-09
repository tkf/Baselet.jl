module TestInference

using Baselet
using Test

valof(::Val{x}) where {x} = x

macro test_inferred(ex)
    quote
        f() = $(esc(ex))
        Test.@test Test.@inferred(f()) isa Any
    end
end

@testset "getindex" begin
    @test_inferred Baselet.getindex((Val(1), Val(2), Val(3), Val(4)), 2:3)
end

@testset "zip" begin
    @test_inferred Baselet.zip((Val(1), Val(2), Val(3), Val(4)))
    @test_inferred Baselet.zip(
        (Val(1), Val(2), Val(3), Val(4)),
        (Val(5), Val(6), Val(7), Val(8)),
    )
end

@testset "flatten" begin
    @test_inferred Baselet.flatten(((Val(1), Val(2)), (Val(3), Val(4), Val(5))))
end

@testset "enumerate" begin
    if VERSION >= v"1.6-"
        @info "Skip inference test for `enumerate` on Julia $VERSION"
    else
        @test_inferred Val(Baselet.enumerate((Val(1), Val(2), Val(3), Val(4))))
    end
end

@testset "any" begin
    @test_inferred Val(Baselet.any(valof, (Val(false), Val(false), Val(false))))
    @test_inferred Val(Baselet.any(valof, (Val(false), Val(false), Val(true))))
end

@testset "all" begin
    @test_inferred Val(Baselet.all(valof, (Val(true), Val(true), Val(true))))
    @test_inferred Val(Baselet.all(valof, (Val(true), Val(true), Val(false))))
end

@testset "sort" begin
    @test_inferred Baselet.sort((Val(3), Val(1), Val(2), Val(0)), by = valof)
end

end  # module
