module Foxtail

using TSFrames, LinearAlgebra

export
	CircBuff,
	# functions
	isfull, capacity, value, merge_in!

abstract type AbstractCircularBuffer{T} end

include("CircBuff.jl")
include("macro.jl")
include("ma.jl")

readdir(joinpath(@__DIR__, "indicators"), join=true) |>
	f -> filter(x -> endswith(x, ".jl"), f) .|> include

end