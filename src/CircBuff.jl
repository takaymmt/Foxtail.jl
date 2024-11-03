"""
	CircBuff{T}
		capacity: Maximum number of elements the buffer can hold
		buffer:   Internal storage for buffer elements
		_begin:   Index of the first element in the buffer
		_length:  Current number of elements in the buffer

A circular buffer is a fixed-size, FIFO (First-In-First-Out) data structure that wraps around at its boundaries. It uses a single, fixed-size buffer as if it were connected end-to-end. When the buffer reaches its end, it begins again at its beginning, overwriting older data.
"""
mutable struct CircBuff{T}
	const capacity::Int
	buffer::Vector{T}
	_begin::Int
	_length::Int

	function CircBuff{T}(c::Int) where T
		c < 1 && throw(ArgumentError("Capacity of CircBuff must be >= 1"))
		new(c, Vector{T}(undef, c), 1, 0)
	end

	function CircBuff{T}(v::AbstractVector{T}) where T
		c = length(v)
		return new(c, copy(v), 1, c)
	end

	function CircBuff{T}(I::AbstractRange{T}) where T
		c = length(I)
		v = collect(I)
		return new(c, v, 1, c)
	end

	function CircBuff{T1}(v::AbstractVector{T2}) where {T1, T2}
		len = length(v)
		nv = convert(Vector{T1}, v)
		return new(len, nv, 1, len)
	end

	function CircBuff{T1}(I::AbstractRange{T2}) where {T1, T2}
		len = length(I)
		buf = Vector{T1}(undef,len)
		@inbounds for (i,n) in enumerate(I)
			buf[i] = convert(T1, n)
		end
		return new(len, buf, 1, len)
	end

	function CircBuff{T}(c::Int, v::AbstractVector{T}) where T
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
end

CircBuff{T}(c::Integer) where T = CircBuff{T}(Int(c))
CircBuff(c::Int) = CircBuff{Float64}(c)
CircBuff(v::AbstractVector{T}) where T = CircBuff{T}(v)
CircBuff(c::Int, v::AbstractVector{T}) where T = CircBuff{T}(c, v)
CircBuff(I::AbstractRange{T}) where T = CircBuff{T}(collect(I))
CircBuff(c::Int, I::AbstractRange{T}) where T = CircBuff{T}(c, collect(I))
CircBuff{T1}(c::Int, v::AbstractVector{T2}) where {T1, T2} = CircBuff{T1}(c, convert(Vector{T1}, v))

function CircBuff{T1}(c::Int, I::AbstractRange{T2}) where {T1, T2}
	buf = Vector{T1}(undef,length(I))
	@inbounds for (i,n) in enumerate(I)
		buf[i] = convert(T1, n)
	end
	CircBuff{T1}(c, buf)
end

function Base.show(io::IO, cb::CircBuff)
	println(io, "Circular Buffer {$(typeof(cb))}")
	println(io, ": max capacity = $(cb.capacity) | current length = $(cb._length) | begin = $(cb._begin)")
	println(IOContext(io, :compact => true, :displaysize => (1, 70)), ": buffer = ", cb.buffer)
end

function Base.show(io::IO, ::MIME"text/plain", cb::CircBuff)
	show(io, cb)
end

@inline Base.@propagate_inbounds function _buf_idx(cb::CircBuff, i::Int)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	j = mod(i-1, cb._length) + 1
	return mod(cb._begin + j - 2, cb.capacity) + 1
end

@inline Base.@propagate_inbounds function _buf_idx(cb::CircBuff, I::UnitRange{Int})
	return [_buf_idx(cb, i) for i in I]
end

Base.length(cb::CircBuff) = cb._length
Base.size(cb::CircBuff) = size(cb.buffer)
@inline Base.@propagate_inbounds Base.getindex(cb::CircBuff, i::Int) = cb.buffer[_buf_idx(cb, i)]
@inline Base.@propagate_inbounds Base.getindex(cb::CircBuff, V::AbstractVector{Int}) = [cb[v] for v in V]
@inline Base.@propagate_inbounds Base.getindex(cb::CircBuff, I::UnitRange{Int}) = [cb[i] for i in I]
Base.firstindex(cb::CircBuff) = 1
Base.lastindex(cb::CircBuff) = cb._length
Base.isempty(cb::CircBuff) = cb._length == 0
Base.eltype(cb::CircBuff) = eltype(cb.buffer)
Base.eltype(::Type{CircBuff{T}}) where T = T

@inline Base.@propagate_inbounds function Base.setindex!(cb::CircBuff{T}, n::T, i::Int) where T
    cb.buffer[_buf_idx(cb, i)] = n
end

@inline Base.@propagate_inbounds function Base.setindex!(cb::CircBuff{T1}, n::T2, i::Int) where {T1, T2}
    cb.buffer[_buf_idx(cb, i)] = convert(T1, n)
end

Base.@propagate_inbounds function Base.first(cb::CircBuff)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	return cb.buffer[cb._begin]
end

Base.@propagate_inbounds function Base.last(cb::CircBuff)
	@boundscheck (cb._length == 0) && throw(BoundsError(cb, 1))
	return cb.buffer[_buf_idx(cb, cb._length)]
end

function Base.empty!(cb::CircBuff)
	cb._length = 0
	return cb
end

@inline function Base.push!(cb::CircBuff{T}, n::T) where T
	if cb._length == cb.capacity
		cb._begin = (cb._begin == cb.capacity ? 1 : cb._begin + 1)
	else
		cb._length += 1
	end
	@inbounds cb.buffer[_buf_idx(cb, cb._length)] = n
	return cb
end

@inline function Base.push!(cb::CircBuff{T1}, n::T2) where {T1,T2}
	push!(cb, convert(T1, n))
end

Base.push!(cb::CircBuff, av::AbstractVector) = append!(cb, av)
Base.push!(cb::CircBuff, ar::AbstractRange) = append!(cb, ar)

@inline function Base.pushfirst!(cb::CircBuff{T}, n::T) where T
	cb._begin = cb._begin == 1 ? cb.capacity : cb._begin - 1
	if cb._length < cb.capacity
		cb._length += 1
	end
	@inbounds cb.buffer[cb._begin] = n
	return cb
end

function Base.pushfirst!(cb::CircBuff{T1}, n::T2) where {T1,T2}
	pushfirst!(cb, convert(T1, n))
end

@inline function Base.pop!(cb::CircBuff{T}) where T
	@boundscheck (cb._length == 0) && throw(ArgumentError("array must be non-empty"))
	n = cb.buffer[_buf_idx(cb, cb._length)]
	cb._length -= 1
	return n
end

@inline function Base.popfirst!(cb::CircBuff{T}) where T
	@boundscheck (cb._length == 0) && throw(ArgumentError("array must be non-empty"))
	n = cb.buffer[_buf_idx(cb, 1)]
	cb._length -= 1
	cb._begin += 1
	return n
end

isfull(cb::CircBuff) = cb._length == cb.capacity
capacity(cb::CircBuff) = cb.capacity
value(cb::CircBuff) = view(cb.buffer, _buf_idx(cb, 1:cb._length))

"""
    append!(::CircBuff{T}, ::AbstractVector{T})
    append!(::CircBuff,    ::AbstractRange)

Push at most last `capacity` items.
"""
@inline function Base.append!(cb::CircBuff, av::AbstractVector)
    n = length(av)
	spc = cb.capacity - cb._length
	if n > spc
		for i in max(1, n-capacity(cb)+1):n
			push!(cb, av[i])
		end
	else
		for elm in av
			push!(cb, elm)
		end
	end
    return cb
end

@inline function Base.append!(cb::CircBuff, I::AbstractRange)
    n = length(I)
    spc = cb.capacity - cb._length
    if n > spc
        lst = last(I, capacity(cb))
        for i in lst
            push!(cb, i)
        end
    else
        for i in I
            push!(cb, i)
        end
    end
end

"""
    fill!(::CircBuff{T}, ::T)

Fills all empty spaces in buffer, preserving existing elements
"""
function Base.fill!(cb::CircBuff{T}, elm::T) where T
	for i in 1:cb.capacity - cb._length
		push!(cb, elm)
	end
	return cb
end

function Base.fill!(cb::CircBuff{T1}, elm::T2) where {T1,T2}
	nlm = convert(T1, elm)
	for i in 1:cb.capacity - cb._length
		push!(cb, nlm)
	end
	return cb
end

"""
    merge_in!(::CircBuff{T}, ::AbstractVector)
    merge_in!(::CircBuff{T}, ::AbstractRange)

Appends vector to empty spaces until capacity is full, preserving existing elements
"""
function merge_in!(cb::CircBuff, av::AbstractVector)
	for i in 1:min(cb.capacity - cb._length, length(av))
		push!(cb, av[i])
	end
	return cb
end

function merge_in!(cb::CircBuff, I::AbstractRange)
    n = length(I)
    spc = cb.capacity - cb._length
    if n > spc
        for i in first(I, spc)
            push!(cb, i)
        end
    else
        for i in I
            push!(cb, i)
        end
    end
end