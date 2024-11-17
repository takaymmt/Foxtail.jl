module Foxtail

using TSFrames, LinearAlgebra

export
	CircBuff, CircDeque, MinMaxQueue,
	# functions
	isfull, capacity, value, merge_in!,
	update!, remove_old!, get_max, get_min

include("tools/CircBuff.jl")
include("tools/CircDeque.jl")
include("tools/MinMaxQueue.jl")
include("macro.jl")

readdir(joinpath(@__DIR__, "indicators"), join=true) |>
	f -> filter(x -> endswith(x, ".jl"), f) .|> include

end