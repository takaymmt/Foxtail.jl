using Foxtail
using Test, CSV, TSFrames

tests = [
    "CircBuff",
    "CircDeque",
    "MinMaxQueue",
    "Indicators_SISO",
    "Indicators_MISO",
    "Indicators_SIMO",
    "Indicators_MIMO",
    "Indicators_AAPL",
]

@testset "Foxtail.jl" begin
    for t in tests
        fp = joinpath(dirname(@__FILE__), "test_$t.jl")
        println("$fp ...")
        include(fp)
    end
end

nothing