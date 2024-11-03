mutable struct CircDeque{T}
    const capacity::Int
    buffer::Vector{T}
    _length::Int
    _begin::Int
    _end::Int

    CircDeque{T}(c::Int) where T = new(c, Vector{T}(undef, c), 0, 1, c)
    CircDeque{T}(c::Integer) where T = new(Int(c), Vector{T}(undef, Int(c)), 0, 1, Int(c))
end

function Base.show(io::IO, cd::CircDeque)
	println(io, "Circular Deque {$(typeof(cd))}")
	println(io, ": max capacity = $(cd.capacity) | current length = $(cd._length) | begin = $(cd._begin) | end = $(cd._end)")
	println(IOContext(io, :compact => true, :displaysize => (1, 70)), ": buffer = ", cd.buffer)
end

function Base.show(io::IO, ::MIME"text/plain", cd::CircDeque)
	show(io, cd)
end

@inline function _unsafe_getindex(cd::CircDeque, i::Integer)
    j = cd._begin + i - 1
    if j > cd.capacity
        j -= cd.capacity
    end
    @inbounds ret = cd.buffer[j]
    return ret
end

@inline function Base.getindex(cd::CircDeque, i::Integer)
    @boundscheck 1 <= i <= cd._length || throw(BoundsError())
    return _unsafe_getindex(cd, i)
end

Base.length(cd::CircDeque) = cd._length
Base.eltype(cd::CircDeque) = eltype(cd.buffer)
Base.eltype(::Type{CircDeque{T}}) where {T} = T

capacity(cd::CircDeque) = cd.capacity
value(cd::CircDeque) = view(cd.buffer, [mod(i-1,cd.capacity)+1 for i in cd._begin:(cd._begin+cd._length-1)])

function Base.empty!(cd::CircDeque)
    cd._length = 0
    cd._begin = 1
    cd._end = cd.capacity
    return cd
end

Base.isempty(cd::CircDeque) = cd._length == 0

@inline function Base.first(cd::CircDeque)
    @boundscheck cd._length < 1 && throw(BoundsError())
    return @inbounds cd.buffer[cd._begin]
end

@inline function Base.last(cd::CircDeque)
    @boundscheck cd._length < 1 && throw(BoundsError())
    return @inbounds cd.buffer[cd._end]
end

@inline function Base.push!(cd::CircDeque, v)
    @boundscheck cd._length < cd.capacity || throw(BoundsError()) # prevent overflow
    cd._length += 1
    tmp = cd._end + 1
    cd._end = ifelse(tmp > cd.capacity, 1, tmp)
    @inbounds cd.buffer[cd._end] = v
    return cd
end

@inline Base.@propagate_inbounds function Base.pop!(cd::CircDeque)
    v = last(cd)
    Base._unsetindex!(cd.buffer, cd._end)
    cd._length -= 1
    tmp = cd._end - 1
    cd._end = ifelse(tmp < 1, cd.capacity, tmp)
    return v
end

@inline function Base.pushfirst!(cd::CircDeque, v)
    @boundscheck cd._length < cd.capacity || throw(BoundsError())
    cd._length += 1
    tmp = cd._begin - 1
    cd._begin = ifelse(tmp < 1, cd.capacity, tmp)
    @inbounds cd.buffer[cd._begin] = v
    return cd
end

@inline Base.@propagate_inbounds function Base.popfirst!(cd::CircDeque)
    v = first(cd)
    Base._unsetindex!(cd.buffer, cd._begin)
    cd._length -= 1
    tmp = cd._begin + 1
    cd._begin = ifelse(tmp > cd.capacity, 1, tmp)
    v
end