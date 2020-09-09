module TestBaselet
using Test

@testset "$file" for file in sort([
    file for file in readdir(@__DIR__) if match(r"^test_.*\.jl$", file) !== nothing
])
    # Skip inference test on Julia 1.0.  It may work in 1.1 or 1.2 but
    # they are note tested.
    if VERSION < v"1.3-" && file == "test_inference.jl"
        @info "Skip $file for Julia $VERSION"
        continue
    elseif (
        lowercase(get(ENV, "JULIA_PKGEVAL", "false")) == "true" &&
        file == "test_inference.jl"
    )
        @info "Skip $file on PkgEval."
        continue
    end
    include(file)
end

end  # module
