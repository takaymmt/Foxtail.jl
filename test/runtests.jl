using Foxtail
using Test, CSV, TSFrames

tests = [
    "CircBuff",
    "CircDeque",
    "Indicators"
]

@testset "Foxtail.jl" begin
    for t in tests
        fp = joinpath(dirname(@__FILE__), "test_$t.jl")
        println("$fp ...")
        include(fp)
    end
end

nothing