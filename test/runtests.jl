using Foxtail
using Test

tests = [
    "CircBuff",
    "CircDeque"
]

@testset "Foxtail.jl" begin
    for t in tests
        fp = joinpath(dirname(@__FILE__), "test_$t.jl")
        println("$fp ...")
        include(fp)
    end
end

nothing