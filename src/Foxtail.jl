module Foxtail

using TSFrames

export
	CircBuff,
	# functions
	isfull, capacity, value

abstract type FTailStat end

function name(ft::FTailStat)
	return "FTailStat.$(typeof(ft))"
end

@inline Base.first(ft::FTailStat) = first(ft.cb)
@inline Base.length(ft::FTailStat) = length(ft.cb)
@inline Base.push!(ft::FTailStat, x::Real) = push!(ft.cb, x)
@inline isfull(ft::FTailStat) = isfull(ft.cb)
@inline capacity(ft::FTailStat) = capacity(ft.cb)
@inline value(ft::FTailStat) = value(ft.cb)


"""
	CircBuff{T}
		capacity: Maximum number of elements the buffer can hold
		buffer:   Internal storage for buffer elements
		_begin:   Index of the first element in the buffer
		_length:  Current number of elements in the buffer

A circular buffer is a fixed-size, FIFO (First-In-First-Out) data structure that wraps around at its boundaries. It uses a single, fixed-size buffer as if it were connected end-to-end. When the buffer reaches its end, it begins again at its beginning, overwriting older data.
"""
mutable struct CircBuff{T <: Real}
	const capacity::Int
	buffer::Vector{T}
	_begin::Int
	_length::Int

	# Constructor for empty buffer with specified capacity
	function CircBuff{T}(c::Int) where T
		c < 1 && throw(ArgumentError("Capacity of CircBuff must be >= 1"))
		new(c, Vector{T}(undef, c), 1, 0)
	end

	# Constructor from existing vector
	function CircBuff{T}(v::Vector{T}) where T
		c = length(v)
		return new(c, copy(v), 1, c)
	end

	# Constructor with capacity and initial values
	function CircBuff{T}(c::Int, v::Vector{T}) where T
		c < 1 && throw(ArgumentError("Capacity of CircBuff must be >= 1"))
		l = length(v)
		if c == l
			return CircBuff{T}(v)
		elseif c < l
			return CircBuff{T}(v[1:c])
		else
			nv = Vector{T}(undef, c)
			copyto!(nv, v)
			return new(c, nv, 1, l)
		end
	end

	CircBuff{T}(c::Integer) where T = CircBuff{T}(Int(c))
	CircBuff(c::Int) = CircBuff{Float64}(c)
	CircBuff(v::Vector{T}) where T = CircBuff{T}(v)
	CircBuff(c::Int, v::Vector{T}) where T = CircBuff{T}(c, v)
end

function Base.show(io::IO, cb::CircBuff)
	println(io, "Circular Buffer {$(eltype(cb))}")
	println(io, ": max capacity = $(cb.capacity) | current length = $(cb._length) | begin = $(cb._begin)")
	println(IOContext(io, :compact => true, :displaysize => (1, 70)), ": buffer = ", cb.buffer)
end

@inline Base.@propagate_inbounds function _buf_idx(cb::CircBuff, i::Int)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	return mod(cb._begin + i - 2, cb._length) + 1
end

@inline Base.@propagate_inbounds function _buf_idx(cb::CircBuff, I::UnitRange{Int})
	return [_buf_idx(cb, i) for i in I]
end

Base.length(cb::CircBuff) = cb._length
Base.size(cb::CircBuff) = size(cb.buffer)
@inline Base.@propagate_inbounds Base.getindex(cb::CircBuff, i::Int) = cb.buffer[_buf_idx(cb, i)]
@inline Base.@propagate_inbounds Base.getindex(cb::CircBuff, I::UnitRange{Int}) = [cb[i] for i in I]
Base.firstindex(cb::CircBuff) = 1
Base.lastindex(cb::CircBuff) = cb._length
Base.isempty(cb::CircBuff) = cb.length == 0
Base.eltype(cb::CircBuff) = eltype(cb.buffer)

# @inline Base.@propagate_inbounds function Base.setindex!(cb::CircBuff{T}, n::T, i::Int) where T
#     cb.buffer[_buf_idx(cb, i)] = n
# end

Base.@propagate_inbounds function Base.first(cb::CircBuff)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	return cb.buffer[cb._begin]
end

Base.@propagate_inbounds function Base.last(cb::CircBuff)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	return cb.buffer[_buf_idx(cb, cb._length)]
end

function Base.empty!(cb::CircBuff)
	# Reset the buffer.
	cb._length = 0
	return cb
end

@inline function Base.push!(cb::CircBuff{T}, n::T) where T
	# Add an element to the back and overwrite front if full.
	if cb._length == cb.capacity
		cb._begin = (cb._begin == cb.capacity ? 1 : cb._begin + 1)
	else
		cb._length += 1
	end
	@inbounds cb.buffer[_buf_idx(cb, cb._length)] = n
	return cb
end

function Base.push!(cb::CircBuff{T}, v::Vector{T}) where T
	# When receiving a Vector as an argument, replace only the first elements up to the capacity with the elements from the beginning of the input Vector.
	for i in 1:min(cb.capacity, length(v))
		push!(cb, v[i])
	end
end

function Base.fill!(cb::CircBuff{T}, v::Vector{T}) where T
	# Add elements up to the capacity when there is space remaining in the buffer.
	for i in 1:min(cb.capacity - cb._length, length(v))
		push!(cb, v[i])
	end
end

isfull(cb::CircBuff) = cb._length == cb.capacity
capacity(cb::CircBuff) = cb.capacity
value(cb::CircBuff) = view(cb.buffer, _buf_idx(cb, 1:cb._length))


include("macro.jl")
include("ma.jl")

export @prep_SISO

end