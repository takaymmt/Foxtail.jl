module Foxtail

using TSFrames, LinearAlgebra

export
	CircBuff, CircDeque,
	# functions
	isfull, capacity, value, merge_in!

include("CircBuff.jl")
include("CircDeque.jl")
include("macro.jl")
include("ma.jl")

readdir(joinpath(@__DIR__, "indicators"), join=true) |>
	f -> filter(x -> endswith(x, ".jl"), f) .|> include

end