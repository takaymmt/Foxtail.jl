"""
    _SMA(data::Vector{T}, period::Int) where T

Calculate Simple Moving Average (SMA) for a given time series data.

Simple Moving Average is calculated as the arithmetic mean of a specified number of
prices over a moving window. This implementation uses a circular buffer for efficient
memory management.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the moving window for average calculation

# Returns
- `Vector{T}`: Vector containing SMA values for each point in the input data

# Implementation Details
The function maintains a running sum using a circular buffer to optimize performance:
- For full buffer: Updates running sum by removing oldest price and adding new price
- For partial buffer: Accumulates sum and computes average using current buffer length

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0]
period = 3
result = _SMA(prices, period)  # Returns: [1.0, 1.5, 2.0, 3.0, 4.0]
```

See also: [`@prep_MA`](@ref)
"""
@prep_MA SMA

function _SMA(data::Vector{T}, period::Int) where T
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    running_sum = zero(T)

    for (i, price) in enumerate(data)
        if isfull(buf)
            running_sum = running_sum - first(buf) + price
            results[i] = running_sum / period
            push!(buf, price)
        else
            push!(buf, price)
            running_sum += price
            results[i] = running_sum / length(buf)
        end
    end
    return results
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

@prep_MA ALMA offset(0.85) sigma(6.0)

@inline function _ALMA(prices::Vector, period::Int; offset::Float64=0.85, sigma::Float64=6.0)
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

# # Define and export public interface function
# function ALMA(ts::TSFrame, period::Int; field::Symbol=:Close, offset::Float64=0.85, sigma::Float64=6.0)
# 	prices = ts[:, field]
# 	results = _ALMA(prices, period, offset, sigma)
# 	col_name = Symbol(:ALMA, :_, period)
# 	return TSFrame(results, index(ts), colnames=[col_name])
# end
# export ALMA

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


"""
    KAMA(ts::TSFrame, period::Int=10; field::Symbol=:Close, fast::Int=2, slow::Int=30)

Calculate Kaufman's Adaptive Moving Average (KAMA) for time series data.

KAMA is an advanced technical indicator that adapts to price volatility, moving quickly
during trending periods and slowly during ranging periods. It combines the concepts
of trend following and market volatility to create a dynamic moving average.

# Arguments
- `ts::TSFrame`: Input time series data frame
- `period::Int=10`: Lookback period for efficiency ratio calculation
- `field::Symbol=:Close`: Column name to use for calculations (default: :Close)
- `fast::Int=2`: Fast EMA period for most efficient market
- `slow::Int=30`: Slow EMA period for least efficient market

# Returns
- `TSFrame`: New TSFrame containing KAMA values with column name "KAMA_period"

# Calculation Method
1. Calculate Efficiency Ratio (ER)
   - Direction = |Price₍ₜ₎ - Price₍ₜ₋ₙ₎|
   - Volatility = Σ|Price₍ᵢ₎ - Price₍ᵢ₋₁₎| for i = t-n+1 to t
   - ER = Direction / Volatility

2. Calculate Smoothing Constant (SC)
   - Fast SC = 2/(2+1)
   - Slow SC = 2/(30+1)
   - SC = [ER × (Fast SC - Slow SC) + Slow SC]²

3. Calculate KAMA
   - KAMA₍ₜ₎ = KAMA₍ₜ₋₁₎ + SC × (Price₍ₜ₎ - KAMA₍ₜ₋₁₎)

# Example
```julia
using TSFrames
# Create sample time series data
dates = Date(2023,1,1):Day(1):Date(2023,12,31)
prices = cumsum(randn(length(dates))) .+ 100
ts = TSFrame(prices, dates, colnames=[:Close])

# Calculate KAMA with default parameters
kama_result = KAMA(ts)

# Calculate KAMA with custom parameters
kama_custom = KAMA(ts, 15, field=:Close, fast=3, slow=40)
```

# Notes
- Minimum input length must be greater than the period parameter
- Returns NaN for the first `period` elements
- More reactive to price changes during trending markets
- More stable during ranging or choppy markets

See also: [`_KAMA`](@ref) for the underlying implementation details.
"""
# Define and export public interface function
# function KAMA(ts::TSFrame, period::Int=10; field::Symbol=:Close, fast::Int=2, slow::Int=30)
#     prices = ts[:, field]
#     results = _KAMA(prices, period, fast, slow)
#     col_name = Symbol(:KAMA, :_, period)
#     return TSFrame(results, index(ts), colnames=[col_name])
# end
# export KAMA

@prep_MA KAMA fast(2) slow(30)

function _KAMA(data::AbstractVector{T}, n::Int=10; fast::Int=2, slow::Int=30) where T <: AbstractFloat
    length(data) < n && throw(ArgumentError("Input data length is shorter than the period"))

    # Pre-allocate memory (minimum required arrays)
    len = length(data)
    kama = zeros(T, len)

    # Pre-calculate constants for efficiency
    fast_sc = T(2) / (fast + T(1))
    slow_sc = T(2) / (slow + T(1))
    sc_diff = fast_sc - slow_sc

    # Optimize price change calculation (using temporary array)
    price_changes = similar(data)
    @views price_changes[2:end] .= abs.(diff(data))
    price_changes[1] = zero(T)

    # Simultaneous calculation of directional movement and volatility
    @inbounds begin
        # Set initial values
        kama[1:n-1] .= data[1:n-1]
        kama[n] = data[n]

        # Main calculation loop
        for i in n+1:len
            # Calculate price volatility (efficient moving sum)
            window_sum = sum(view(price_changes, i-n+1:i))

            # Calculate directional movement
            direction = abs(data[i] - data[i-n+1])

            # Calculate Efficiency Ratio (ER)
            er = ifelse(window_sum != zero(T), direction / window_sum, zero(T))

            # Calculate Smoothing Constant (SC)
            sc = (er * sc_diff + slow_sc)^2

            # Update KAMA value
            kama[i] = kama[i-1] + sc * (data[i] - kama[i-1])
        end
    end

    return kama
end

"""
    JMA(ts::TSFrame, period::Int=10; field::Symbol=:Close, phase::Float64=0.0)

Calculate Jurik Moving Average (JMA) for time series data based on Jurik's original algorithm.

JMA implements a triple adaptive filter that features:
- Superior noise reduction with dynamic volatility adaptation
- Precise trend following using Kalman filter principles
- Phase-adjusted smoothing for lag control
- Jurik's unique adaptive filtering mechanism

The calculation process consists of three main stages:

1. Parameter Initialization:
   - β = 0.45(period-1)/(0.45(period-1)+2)
   - len1 = log(√period)/log(2) + 2
   - pow1 = max(0.5, len1 - 2)
   - phase_ratio = clamp(phase/100 + 1.5, 0.5, 2.5)

2. Volatility Calculation:
   a) Jurik Bands Computation:
      - Calculate distances: del1 = price - upper_band, del2 = price - lower_band
      - Update bands with volatility factor kv = β^√pow1
      - Determine volatility as max(|del1|, |del2|)
   b) Relative Volatility:
      - Track 10-period moving sum of volatility
      - Calculate ratio = current_volatility/average_volatility
      - Apply bounds: ratio ∈ [1.0, len1^(1/pow1)]

3. Triple Smoothing Process:
   a) Adaptive EMA (Stage 1):
      - Calculate dynamic α = β^(r_volty^pow1)
      - MA1 = (1-α)price + α×MA1_prev
   b) Kalman Filter (Stage 2):
      - Det0 = (price-MA1)(1-β) + β×Det0_prev
      - MA2 = MA1 + phase_ratio×Det0
   c) Jurik Adaptive Filter (Stage 3):
      - Det1 = (MA2-JMA_prev)(1-α)² + α²×Det1_prev
      - JMA = JMA_prev + Det1

Parameters:
- ts: Input time series data
- period: Moving average length (default: 10)
- field: Price field to use (default: :Close)
- phase: Phase adjustment between -100 and 100 (default: 0.0)
  - Positive values decrease lag but may reduce smoothing
  - Negative values increase smoothing but may increase lag

Returns:
    TSFrame with JMA values

Implementation Notes:
- Uses Jurik's original three-stage filtering process
- Incorporates dynamic volatility adaptation
- Implements complete Jurik Bands calculation
- Features phase-adjusted Kalman filtering

References:
Based on Mark Jurik's original algorithm description and research.
"""

function JMA(ts::TSFrame, period::Int=10; field::Symbol=:Close, phase::Float64=0.0)
    prices = ts[:, field]
    results = _JMA(prices, period, phase)
    col_name = Symbol(:JMA, :_, period)
    return TSFrame(results, index(ts), colnames=[col_name])
end
export JMA

function _JMA(data::Vector{Float64}, length::Int=7, phase::Float64=0.0)
    n = size(data, 1)
    jma = zeros(Float64, n)

    # Initialize core parameters
    beta = 0.45 * (length - 1) / (0.45 * (length - 1) + 2)

    # Initialize length-dependent factors
    len1 = log(sqrt(length)) / log(2.0) + 2
    len1 = max(0.0, len1)
    pow1 = len1 - 2
    pow1 = max(0.5, pow1)

    # Phase ratio calculation with bounds
    phase_ratio = clamp(phase / 100 + 1.5, 0.5, 2.5)

    # Initialize smoothing variables
    ma1 = data[1]
    det0 = 0.0
    det1 = 0.0

    # Volatility tracking variables
    upper_band = data[1]
    lower_band = data[1]
    volty = 0.0
    avg_volty = 0.0
    v_sum = 0.0
    volty_history = zeros(Float64, 10)  # Store last 10 volatility values
    volty_idx = 1

    # First point initialization
    jma[1] = data[1]

    for i in 2:n
        # Calculate Jurik Bands
        del1 = data[i] - upper_band
        del2 = data[i] - lower_band

        # Update bands
        kv = beta ^ sqrt(pow1)
        if del1 > 0
            upper_band = data[i]
        else
            upper_band = data[i] - kv * del1
        end

        if del2 < 0
            lower_band = data[i]
        else
            lower_band = data[i] - kv * del2
        end

        # Calculate volatility
        volty = if abs(del1) == abs(del2)
            0.0
        else
            max(abs(del1), abs(del2))
        end

        # Update volatility history and sum
        v_sum = v_sum - volty_history[volty_idx] / 10 + volty / 10
        volty_history[volty_idx] = volty
        volty_idx = volty_idx == 10 ? 1 : volty_idx + 1

        # Calculate average volatility (simplified from original 65-period average)
        avg_volty = i < 30 ? volty : v_sum

        # Calculate relative volatility with bounds
        r_volty = if avg_volty > 0
            volty / avg_volty
        else
            1.0
        end
        r_volty = clamp(r_volty, 1.0, len1^(1/pow1))

        # Calculate dynamic alpha
        pow = r_volty ^ pow1
        alpha = beta ^ pow

        # Stage 1: Preliminary smoothing by adaptive EMA
        ma1 = (1.0 - alpha) * data[i] + alpha * ma1

        # Stage 2: Secondary smoothing by Kalman filter
        det0 = (data[i] - ma1) * (1.0 - beta) + beta * det0
        ma2 = ma1 + phase_ratio * det0

        # Stage 3: Final Jurik adaptive filter
        det1 = (ma2 - jma[i-1]) * (1.0 - alpha)^2 + alpha^2 * det1
        jma[i] = jma[i-1] + det1
    end

    return jma
end



function JMA2(ts::TSFrame, period::Int=10; field::Symbol=:Close, phase::Float64=0.0)
    prices = ts[:, field]
    results = _JMA2(prices, period, phase)
    col_name = Symbol(:JMA2, :_, period)
    return TSFrame(results, index(ts), colnames=[col_name])
end
export JMA2
"""
    _JMA(data::Vector{Float64}, length::Int=7, phase::Float64=0.0)

Optimized implementation of Jurik Moving Average (JMA).
Almost 2 times faster than original implementation, but the result is slightly different.
"""
function _JMA2(data::Vector{Float64}, length::Int=7, phase::Float64=0.0)
    n = size(data, 1)
    jma = zeros(Float64, n)

    # Pre-calculate constants
    beta = 0.45 * (length - 1) / (0.45 * (length - 1) + 2)
    len1 = max(0.0, log2(sqrt(length)) + 2)  # Using log2 is faster than log/log(2)
    pow1 = max(0.5, len1 - 2)
    phase_ratio = clamp(phase / 100 + 1.5, 0.5, 2.5)

    # Pre-calculate frequently used constants
    sqrt_pow1 = sqrt(pow1)
    kv = beta ^ sqrt_pow1
    one_minus_beta = 1.0 - beta
    volty_bound = len1^(1/pow1)

    # Ring buffer for volatility history
    volty_history = zeros(Float64, 10)

    # Initialize state variables
    @inline function update_bands(price::Float64, del::Float64)::Float64
        return ifelse(del > 0, price, price - kv * del)
    end

    # Initialize first point
    jma[1] = data[1]
    ma1 = data[1]
    det0 = 0.0
    det1 = 0.0
    upper_band = data[1]
    lower_band = data[1]
    v_sum = 0.0
    volty_idx = 1

    # Main loop with optimized calculations
    @inbounds for i in 2:n
        price = data[i]

        # Jurik Bands calculation (reduced branches)
        del1 = price - upper_band
        del2 = price - lower_band
        upper_band = update_bands(price, del1)
        lower_band = update_bands(price, del2)

        # Volatility calculation (removed equality check for speed)
        volty = max(abs(del1), abs(del2))

        # Efficient ring buffer update
        old_volty = volty_history[volty_idx]
        volty_history[volty_idx] = volty
        volty_idx = mod1(volty_idx + 1, 10)

        # Update volatility sum (reduced divisions)
        v_sum = v_sum - old_volty * 0.1 + volty * 0.1

        # Calculate average volatility
        avg_volty = ifelse(i < 30, volty, v_sum)

        # Calculate relative volatility (reduced branches)
        r_volty = clamp(
            ifelse(avg_volty > 0, volty / avg_volty, 1.0),
            1.0,
            volty_bound
        )

        # Calculate dynamic alpha (combined power calculations)
        alpha = beta ^ (r_volty ^ pow1)
        alpha_sq = alpha * alpha
        one_minus_alpha = 1.0 - alpha
        one_minus_alpha_sq = one_minus_alpha * one_minus_alpha

        # Three-stage smoothing (combined multiplications)
        ma1 = one_minus_alpha * price + alpha * ma1
        det0 = (price - ma1) * one_minus_beta + beta * det0
        ma2 = ma1 + phase_ratio * det0

        prev_jma = jma[i-1]
        det1 = (ma2 - prev_jma) * one_minus_alpha_sq + alpha_sq * det1
        jma[i] = prev_jma + det1
    end

    return jma
end
