module TestAqua

import Aqua
import Baselet
using Test

Aqua.test_all(Baselet)

@testset "Compare Project.toml and test/Project.toml" begin
    Aqua.test_project_extras(Baselet)
end

end  # module
