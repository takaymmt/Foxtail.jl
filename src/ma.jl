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
@prep_SISO EMA result alpha

function fit!(ind::iEMA{T}, price::T) where T
	if isfull(ind)
		push!(ind, price)
		ind._result = price * ind._alpha + ind._result * (1 - ind._alpha)
	else
		push!(ind, price)
		ind._alpha = 2 / (1 + length(ind))
		ind._result = price * ind._alpha + ind._result * (1 - ind._alpha)
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

"""
Arnaud Legoux Moving Average (ALMA) Implementation

ALMA is an advanced moving average indicator that reduces signal lag while maintaining
smooth transitions between values. It uses Gaussian-weighted coefficients applied to price data.

Basic Concept:
-------------
ALMA is calculated as a weighted sum of price values, where the weights follow
a Gaussian (bell curve) distribution shape. The weights are positioned and scaled
within the window using the offset and sigma parameters.

Core Formula:
------------
ALMA_t = Σ(w_i * P_(t-i))  for i = 0 to (n-1)

where:
- w_i are the normalized Gaussian weights
- P_(t-i) is the price i periods ago
- n is the window size

Weight Calculation:
-----------------
1. Initial weight for position i:
   w_i = exp(-(i - m)^2 / (2 * s^2))
   where:
   - m = floor(offset * (n-1)) : controls the peak position
   - s = n/sigma : controls the curve width

2. Weights are then normalized by dividing each by their sum:
   final_w_i = w_i / Σ(w_j)  for j = 0 to (n-1)

Parameters:
----------
window (n): Integer, default=9
    - Number of periods to consider
    - Larger values capture longer trends but increase lag
    - Common values: 9 (short-term) to 50 (long-term)

offset: Float64, default=0.85
    - Controls the weight distribution's position (0 to 1)
    - Higher values (→1) emphasize recent prices
    - Lower values (→0) emphasize older prices
    - 0.85 is commonly used for balanced sensitivity

sigma: Float64, default=6.0
    - Controls the Gaussian curve's shape
    - Lower values (e.g., 2) create sharper curves = more responsive but noisier
    - Higher values (e.g., 6) create gentler curves = smoother but more lag
    - 6.0 provides good balance between smoothing and responsiveness

Effect of Parameters:
-------------------
Window Size Effect:
- Larger window → Smoother output, more lag, better for long-term trends
- Smaller window → More responsive, less lag, better for short-term signals

Offset Effect:
- Higher offset → More weight on recent prices, faster response to changes
- Lower offset → More weight on older prices, slower response to changes

Sigma Effect:
- Lower sigma → Sharper weight distribution, more emphasis on prices near peak
- Higher sigma → Broader weight distribution, more evenly distributed weights

Common Parameter Combinations:
---------------------------
Short-term trading:  window=9,  offset=0.85, sigma=6
Medium-term trading: window=21, offset=0.85, sigma=6
Long-term trading:   window=50, offset=0.85, sigma=6
"""

# mutable struct iALMA{T} <: FTailStat
# 	cb::CircBuff
# 	_bufwt::Vector
# 	_offset::Float64
# 	_sigma::Float64

# 	function iALMA{T}(period::Int, offset::Float64=0.85, sigma::Float64=6.0) where {T}
# 		new{T}(CircBuff{T}(period), zeros(T, period), offset, sigma)
# 	end
# end

# # Define internal calculation function
# @inline function _ALMA(prices::Vector, period::Int, offset::Float64=0.85, sigma::Float64=6.0)
# 	ind = iALMA{eltype(prices)}(period, offset, sigma)
# 	return map(x -> fit!(ind, x), prices)
# end

# function fit!(ind::iALMA{T}, price::T) where T
# 	if isfull(ind)
# 		push!(ind, price)
# 		return dot(value(ind), ind._bufwt)

# 	else
# 		push!(ind, price)
#         window = length(ind)

# 		if window == 1
# 			return price
# 		else
# 			m = ind._offset * (window - 1)
# 			# m = floor(ind._offset * (window - 1))
# 			s = window / ind._sigma
# 			@inbounds for i in 0:(window-1)
# 				ind._bufwt[i+1] = exp(-((i - m)^2) / (2 * s^2))
# 			end
# 			weights = view(ind._bufwt, 1:window)
# 			weights ./= sum(weights)

# 			return dot(value(ind), weights)
# 		end
# 	end
# end

@inline function _ALMA(prices::Vector, period::Int, offset::Float64=0.85, sigma::Float64=6.0)
	n = length(prices)
	result = Vector{Float64}(undef, n)
	result[1] = copy(prices[1])

	m = 0.0
	s = 0.0
	weights = zeros(eltype(prices), period)
	@inbounds for window in 2:period
		m = offset * (window - 1)
		s = window / sigma
		@inbounds for j in 0:(window-1)
			weights[j+1] = exp(-((j - m)^2) / (2 * s^2))
		end
		weights ./= sum(weights)
		result[window] = dot(view(prices, 1:window), view(weights,1:window))
	end
	@inbounds for i in (period+1):n
		result[i] = dot(view(prices, (i-period+1):i), weights)
	end
	return result
end

# Define and export public interface function
function ALMA(ts::TSFrame, period::Int; field::Symbol=:Close, offset::Float64=0.85, sigma::Float64=6.0)
	prices = ts[:, field]
	results = _ALMA(prices, period, offset, sigma)
	col_name = Symbol(:ALMA, :_, period)
	return TSFrame(results, index(ts), colnames=[col_name])
end
export ALMA

# # reference implementation of ALMA
# function calculate_alma(data::Vector{Float64}, window::Int=9, offset::Float64=0.85, sigma::Float64=6.0)
#     n = length(data)
#     result = Vector{Float64}(undef, n)
#     m = offset * (window - 1)
#     # m = floor(offset * (window - 1))
#     s = window / sigma
#     weights = [exp(-((i - m)^2) / (2 * s^2)) for i in 0:(window-1)]
#     weights ./= sum(weights)
#     buffer = zeros(Float64, window)
#     result[1:window-1] .= missing
#     @inbounds for i in window:n
#         buffer .= view(data, (i-window+1):i)
#         result[i] = dot(buffer, weights)
#     end
#     return result
# end
# export calculate_alma

@prep_SISO ZLEMA result alpha lag(0::Int)

function fit!(ind::iZLEMA{T}, price::T) where T
	if isfull(ind)
		push!(ind, price)
		EmaData = 2 * price - ind.cb[ind._lag]
		ind._result = EmaData * ind._alpha + ind._result * (1 - ind._alpha)
	else
		push!(ind, price)
		period = length(ind)
		if period == 1
			ind._result = price
		else
			ind._lag = - round(Int, (period-1) / 2)
			ind._alpha = 2 / (1 + period)
			EmaData = 2 * price - ind.cb[ind._lag]
			ind._result = EmaData * ind._alpha + ind._result * (1 - ind._alpha)
		end
	end
	return ind._result
end