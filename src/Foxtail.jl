module Foxtail

using TSFrames, LinearAlgebra

export
	CircBuff, CircDeque,
	# functions
	isfull, capacity, value, merge_in!

include("tools/CircBuff.jl")
include("tools/CircDeque.jl")
include("tools/MonotoneQueue.jl")
include("macro.jl")

readdir(joinpath(@__DIR__, "indicators"), join=true) |>
	f -> filter(x -> endswith(x, ".jl"), f) .|> include

end