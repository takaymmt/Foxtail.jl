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


#--- Indicators ---#
"""
	@prep_SISO(indicator, fields...)

A macro that generates both a calculation struct and interface functions for Single Input,
Single Output (SISO) technical indicators.

# Arguments
- `indicator`: Symbol representing the indicator name (e.g., SMA, EMA, WMA)
- `fields...`: Variable number of field names for storing calculation results

# Generated Components
1. A mutable struct with type parameter T that inherits from FTailStat
	- Named with prefix 'i' (e.g., iSMA for SMA) to avoid naming conflicts
2. An internal calculation function
3. An exported interface function

# Example
	@prep_SISO SMA result
	# Generates:
	# - mutable struct iSMA{T}     # Note the 'i' prefix
	# - _SMA(prices::Vector, period::Int)
	# - SMA(ts::TSFrame, period::Int; field::Symbol=:Close)

# Naming Convention
- Struct: Prefixed with 'i' (e.g., iSMA, iEMA) to distinguish from function names
- Internal function: Prefixed with '_' (e.g., _SMA)
- Public function: Original indicator name (e.g., SMA)
"""
macro prep_SISO(indicator, fields...)
	# Generate names for struct and functions
	struct_name = Symbol(:i, indicator) # Add 'i' prefix for struct name
	func_name = QuoteNode(indicator)
	internal_func_name = Symbol(:_, indicator)

	# Prepare field definitions and their initializations
	field_expressions = [:($(Symbol(:_, field))::Float64) for field in fields]
	init_expressions = [:(zero(Float64)) for _ in fields]

	return quote
		# Define mutable struct for calculations
		# Using 'i' prefix to avoid naming conflicts with function
		mutable struct $(esc(struct_name)){T} <: FTailStat
			cb::CircBuff  # Circular buffer for storing data
			$(field_expressions...)  # Additional fields for calculations
			function $(esc(struct_name)){T}(period::Int) where {T}
				new{T}(CircBuff{T}(period), $(init_expressions...))
			end
		end

		# Define internal calculation function
		@inline function $(esc(internal_func_name))(prices::Vector, period::Int)
			ind = $(esc(struct_name)){eltype(prices)}(period)
			return map(x -> fit!(ind, x), prices)
		end

		# Define and export public interface function
		export $(esc(indicator))
		function $(esc(indicator))(ts::TSFrame, period::Int; field::Symbol = :Close)
			prices = ts[:, field]  # Extract price data
			results = $(esc(internal_func_name))(prices, period)  # Calculate indicator
			col_name = Symbol($func_name, :_, period)  # Generate column name (e.g., :SMA_20)
			return TSFrame(results, index(ts), colnames = [col_name])
		end
	end
end

# Simple Moving Average
@prep_SISO SMA result

function fit!(ind::iSMA{T}, price::T) where T
	if isfull(ind)
		ind._result -= (first(ind) - price) / capacity(ind)
		push!(ind, price)
	else
		push!(ind, price)
		data = value(ind)
		ind._result = sum(data) / length(data)
	end
	return ind._result
end

# Exponential Moving Average
@prep_SISO EMA result

function fit!(ind::iEMA{T}, price::T) where T
	if isfull(ind)
		alpha = 2 / (1 + capacity(ind))
		ind._result = price * alpha + ind._result * (1 - alpha)
		push!(ind, price)
	else
		push!(ind, price)
		alpha = 2 / (1 + length(ind))
		ind._result = price * alpha + ind._result * (1 - alpha)
	end
	return ind._result
end

# Weighted Moving Average
@prep_SISO WMA numerator total denominator

function fit!(ind::iWMA{T}, price::T) where T
	# See https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
	if isfull(ind)
		losing = first(ind)
		push!(ind, price)
		n = length(ind)

		ind._numerator = ind._numerator + n * price - ind._total
		ind._total = ind._total + price - losing
	else
		push!(ind, price)
		n = length(ind)
		ind._denominator = n * (n + 1) / 2

		ind._numerator += n * price
		ind._total += price
	end

	return ind._numerator / ind._denominator
end

# Smoothed Moving Average / Running Moving Average
@prep_SISO SMMA result

function fit!(ind::iSMMA{T}, price::T) where T
	if isfull(ind)
		alpha = 1 / capacity(ind)
		ind._result = price * alpha + ind._result * (1 - alpha)
		push!(ind, price)
	else
		push!(ind, price)
		alpha = 1 / length(ind)
		ind._result = price * alpha + ind._result * (1 - alpha)
	end
	return ind._result
end
RMA(ts::TSFrame, period::Int; field::Symbol = :Close) = SMMA(ts, period; field)
export RMA

# Triangular Moving Average
function TMA(ts::TSFrame, period::Int; field::Symbol = :Close)
    prices = ts[:, field]
    SMA1 = _SMA(prices, period)
    results = _SMA(SMA1, div(period+1, 2))
    col_name = Symbol(:TMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
TRIMA(ts::TSFrame, period::Int; field::Symbol = :Close) = TMA(ts, period; field)
export TMA, TRIMA

# Hull Moving Average
function HMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	WMA1 = _WMA(prices, div(period, 2))
	WMA2 = _WMA(prices, period)
	results = _WMA(WMA1 * 2 - WMA2, round(Int, sqrt(period)))
	col_name = Symbol(:HMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export HMA

# Double Exponential Moving Average
function DEMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	results = EMA1 * 2 - EMA2
	col_name = Symbol(:DEMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export DEMA

# Triple Exponential Moving Average
function TEMA(ts::TSFrame, period::Int; field::Symbol = :Close)
	prices = ts[:, field]
	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	EMA3 = _EMA(EMA2, period)
	results = (EMA1 - EMA2) * 3 + EMA3
	col_name = Symbol(:TEMA, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export TEMA

# T3 Moving Average
# T3(8, 0.1) is an alternative of EMA(20), a bit smoother
# T3(13, 0.08) is an smoother alternative of EMA(40)
function T3(ts::TSFrame, period::Int; field::Symbol = :Close, a::Float64 = 0.7)
	prices = ts[:, field]

	EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	EMA3 = _EMA(EMA2, period)
	EMA4 = _EMA(EMA3, period)
	EMA5 = _EMA(EMA4, period)
	EMA6 = _EMA(EMA5, period)

	c1 = -a^3
	c2 = 3a^2 + 3a^3
	c3 = -6a^2 - 3a - 3a^3
	c4 = 1 + 3a + a^3 + 3a^2

	results = c1 * EMA6 + c2 * EMA5 + c3 * EMA4 + c4 * EMA3

	col_name = Symbol(:T3, :_, period)
	return TSFrame(results, index(ts), colnames = [col_name])
end
export T3

# Arnaud Legoux Moving Average
# formula: https://blog.xcaldata.com/unlocking-trading-insights-with-arnaud-legoux-moving-average-alma/
# pine script: https://www.tuned.com/blog/learning/strategy-creation/what-is-the-arnaud-legoux-moving-average-and-how-to-use-it-on-tuned/
# code: https://www.prorealcode.com/prorealtime-indicators/alma-arnaud-legoux-moving-average/

"""
using .Foxtail, TSFrames, DataFrames, Dates

ts = TSFrame(DataFrame(Index=Date(2024,1,1):Date(2024,1,20), Close=collect(1.0:20.0)))

d = Date(1981,1,1):Date(2024,12,31)
ts = TSFrame(DataFrame(Index=d, Close=rand(length(d))*250))

"""

end