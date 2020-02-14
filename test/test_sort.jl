module TestSort

using Baselet.Specialized: sort
using Random: shuffle
using Test

@testset for n in 1:10
    one_to_n = ntuple(identity, n)
    @test sort(one_to_n) == one_to_n
    @test sort(one_to_n; by = first) == one_to_n
    @test sort(one_to_n; by = _ -> 1) == one_to_n  # stable sort
    @test sort(Tuple(shuffle(1:n))) == one_to_n
    @test sort(one_to_n; by = inv) == reverse(one_to_n)
    @test sort(Tuple(shuffle(1:n)); by = inv) == reverse(one_to_n)
end

end  # module
