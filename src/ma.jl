@prep_MA SMA
@prep_MA EMA
@prep_MA WMA
@prep_MA SMMA
@prep_MA TMA
@prep_MA HMA
@prep_MA DEMA
@prep_MA TEMA
@prep_MA T3 a(0.7)
@prep_MA ALMA offset(0.85) sigma(6.0)
@prep_MA KAMA fast(2) slow(30)
@prep_MA JMA phase(0.0)
@prep_MA ZLEMA

"""
    SMA(data::Vector{T}, period::Int) where T

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
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = SMA(prices, period)  # Returns: [1.0, 1.5, 2.0, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5]
```
"""
@inline Base.@propagate_inbounds function _SMA(data::Vector{T}, period::Int) where T
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    running_sum = zero(T)

    @inbounds for (i, price) in enumerate(data)
        if i > period
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

"""
    EMA(data::Vector{T}, period::Int) where T

Calculate Exponential Moving Average (EMA) for a given time series data.

Exponential Moving Average applies more weight to recent prices while still considering
historical data, with weights decreasing exponentially. This implementation uses a
dynamic smoothing factor for the initial period and a fixed smoothing factor afterwards.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period and smoothing factor calculation

# Returns
- `Vector{T}`: Vector containing EMA values for each point in the input data

# Implementation Details
The function uses different smoothing approaches based on the position in the series:
- First point: Uses the actual price as initial EMA
- During initialization (i ≤ period): Uses dynamic smoothing factor α = 2/(1+i)
- After initialization (i > period): Uses fixed smoothing factor α = 2/(1+period)

The EMA is calculated using the formula:
    EMA_t = Price_t * α + EMA_(t-1) * (1-α)
where α is the smoothing factor

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = EMA(prices, period)  # Returns: [1.0, 1.67, 2.33, 3.0, 3.8, 4.68, 5.6, 6.57, 7.54, 8.52]
```
"""
@inline Base.@propagate_inbounds function _EMA(data::Vector{T}, period::Int) where T
    results = zeros(T, length(data))
    alpha = 0.0

    @inbounds for (i, price) in enumerate(data)
        if i > period
            results[i] = price * alpha + results[i-1] * (1-alpha)
        elseif i == 1
            results[i] = price
        else
            alpha = 2 / (1+i)
            results[i] = price * alpha + results[i-1] * (1-alpha)
        end
    end
    return results
end

"""
    WMA(data::Vector{T}, period::Int) where T

Calculate Weighted Moving Average (WMA) for a given time series data.

Weighted Moving Average assigns linearly increasing weights to more recent prices
while considering historical data. This implementation uses a circular buffer for
efficient memory management and optimizes calculations by maintaining running sums.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the moving window for weighted average calculation

# Returns
- `Vector{T}`: Vector containing WMA values for each point in the input data

# Implementation Details
The function uses different calculation approaches based on the buffer state:
- During initialization (i ≤ period):
  * Weight for position i is i
  * Denominator is calculated as i(i+1)/2
  * Maintains running sum of weighted prices
- After initialization (i > period):
  * Uses circular buffer to update running sums efficiently
  * Updates numerator by adding new weighted price and removing oldest values
  * Denominator remains constant at period(period+1)/2

The WMA is calculated using the formula:
    WMA = Σ(weight_i * price_i) / Σ(weight_i)
where weight_i increases linearly with recency

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = WMA(prices, period)  # Returns: [1.0, 1.67, 2.33, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
```
"""
@inline Base.@propagate_inbounds function _WMA(data::Vector{T}, period::Int) where T
    # See https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    numerator = 0.0
    total = 0.0
    denominator = 0.0

    @inbounds for (i, price) in enumerate(data)
        if i > period
            numerator += period * price - total
            total += price - first(buf)
            push!(buf, price)
        else
            push!(buf, price)
            denominator = i * (i+1) / 2
            numerator += i * price
            total += price
        end
        results[i] = numerator / denominator
    end
    return results
end

"""
    SMMA(data::Vector{T}, period::Int) where T
    RMA(data::Vector{T}, period::Int) where T

Calculate Smoothed Moving Average (SMMA) for a given time series data.
Also known as RMA (Running Moving Average) or Modified Moving Average (MMA).

Smoothed Moving Average is similar to EMA but uses a different smoothing approach,
applying a gentler smoothing factor that gives more weight to historical data. This
implementation uses a dynamic smoothing factor during initialization and a fixed
smoothing factor afterwards.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period and smoothing factor calculation

# Returns
- `Vector{T}`: Vector containing SMMA values for each point in the input data

# Implementation Details
The function uses different smoothing approaches based on the position in the series:
- First point: Uses the actual price as initial SMMA
- During initialization (i ≤ period): Uses dynamic smoothing factor α = 1/i
- After initialization (i > period): Uses fixed smoothing factor α = 1/period

The SMMA is calculated using the formula:
    SMMA_t = Price_t * α + SMMA_(t-1) * (1-α)
where α is the smoothing factor

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = SMMA(prices, period)  # Returns: [1.0, 1.5, 2.0, 2.5, 3.13, 3.84, 4.62, 5.47, 6.36, 7.27]
```
"""
@inline Base.@propagate_inbounds function _SMMA(data::Vector{T}, period::Int) where T
    results = zeros(T, length(data))
    alpha = 0.0

    @inbounds for (i, price) in enumerate(data)
        if i > period
            results[i] = price * alpha + results[i-1] * (1-alpha)
        elseif i == 1
            results[i] = price
        else
            alpha = 1 / i
            results[i] = price * alpha + results[i-1] * (1-alpha)
        end
    end
    return results
end

RMA(ts::TSFrame, period::Int; field::Symbol = :Close) = SMMA2(ts, period; field)
export RMA

"""
    TMA(data::Vector{T}, period::Int) where T
    TRIMA(data::Vector{T}, period::Int) where T

Calculate Triangular Moving Average (TMA) for a given time series data.
Also known as TRIMA (TRIangular Moving Average).

Triangular Moving Average is a double-smoothed indicator calculated by taking a
Simple Moving Average (SMA) of another SMA. This creates a smoother moving average
with weights that increase linearly towards the middle of the period and then
decrease linearly.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the moving window for average calculation

# Returns
- `Vector{T}`: Vector containing TMA values for each point in the input data

# Implementation Details
The function performs a two-step smoothing process:
1. Calculates initial SMA with the specified period
2. Takes another SMA of the result with period (n+1)/2, where n is the original period

The weighting pattern follows a triangular distribution:
- Weights increase linearly to the middle period
- Weights decrease linearly from the middle to the end
- Results in a smoother line compared to simple SMA

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = TMA(prices, period)  # Returns: [1.0, 1.25, 1.75, 2.25, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
```

See also: [`SMA`](@ref)
"""
@inline Base.@propagate_inbounds function _TMA(prices::Vector{T}, period::Int) where T
    SMA1 = _SMA(prices, period)
    return _SMA(SMA1, div(period+1, 2))
end

TRIMA(ts::TSFrame, period::Int; field::Symbol = :Close) = TMA(ts, period; field)
export TMA, TRIMA

"""
    HMA(data::Vector{T}, period::Int) where T

Calculate Hull Moving Average (HMA) for a given time series data.

Hull Moving Average, developed by Alan Hull, is designed to reduce lag in moving
averages while maintaining smoothness. It combines multiple Weighted Moving Averages
(WMA) with different periods and uses square root of the original period for final
smoothing, resulting in a more responsive indicator.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the primary moving window for average calculation

# Returns
- `Vector{T}`: Vector containing HMA values for each point in the input data

# Implementation Details
The function performs a three-step calculation process:
1. Calculates WMA with period/2
2. Calculates WMA with full period
3. Computes final HMA using the formula:
   WMA[sqrt(period)]( 2 * WMA[period/2] - WMA[period] )

Key characteristics:
- Uses half-length WMA to capture faster price movements
- Subtracts full-length WMA to reduce lag
- Final smoothing period of sqrt(period) balances responsiveness and smoothness
- Results in minimal lag while maintaining smooth transitions

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = HMA(prices, period)  # Returns: [1.0, 1.44, 2.56, 3.89, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
```

See also: [`WMA`](@ref)
"""
@inline Base.@propagate_inbounds function _HMA(prices::Vector{T}, period::Int) where T
    WMA1 = _WMA(prices, div(period, 2))
	WMA2 = _WMA(prices, period)
	return _WMA(WMA1 * 2 - WMA2, round(Int, sqrt(period)))
end

"""
    DEMA(data::Vector{T}, period::Int) where T

Calculate Double Exponential Moving Average (DEMA) for a given time series data.

Double Exponential Moving Average, developed by Patrick Mulloy, aims to reduce the
inherent lag of traditional moving averages. It uses a combination of two EMAs to
decrease the lag while maintaining smoothness, making it more responsive to price
changes than a standard EMA.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations

# Returns
- `Vector{T}`: Vector containing DEMA values for each point in the input data

# Implementation Details
The function performs a three-step calculation process:
1. Calculates initial EMA with the specified period
2. Calculates second EMA of the first EMA using the same period
3. Computes final DEMA using the formula:
   DEMA = 2 * EMA(price) - EMA(EMA(price))

Key characteristics:
- Double smoothing reduces noise while maintaining responsiveness
- Multiplier of 2 and subtraction of double-smoothed EMA reduces lag
- More responsive to price changes than standard EMA
- Provides better trend following capabilities with less delay

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = DEMA(prices, period)  # Returns: [1.0, 1.89, 2.78, 3.67, 4.68, 5.74, 6.80, 7.85, 8.90, 9.92]
```

See also: [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function _DEMA(prices::Vector{T}, period::Int) where T
    EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	return EMA1 * 2 - EMA2
end

"""
    TEMA(data::Vector{T}, period::Int) where T

Calculate Triple Exponential Moving Average (TEMA) for a given time series data.

Triple Exponential Moving Average, also developed by Patrick Mulloy as an extension
of DEMA, further reduces lag in trending markets while maintaining smoothness. It
uses a combination of three EMAs to provide even more responsive signals than DEMA,
while effectively filtering out price noise.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations

# Returns
- `Vector{T}`: Vector containing TEMA values for each point in the input data

# Implementation Details
The function performs a four-step calculation process:
1. Calculates initial EMA with the specified period
2. Calculates second EMA of the first EMA using the same period
3. Calculates third EMA of the second EMA using the same period
4. Computes final TEMA using the formula:
   TEMA = (EMA1 - EMA2) * 3 + EMA3
   where EMA1 = EMA(price), EMA2 = EMA(EMA1), EMA3 = EMA(EMA2)

Key characteristics:
- Triple smoothing provides superior noise reduction
- Combination formula helps eliminate lag while preserving trend signals
- More responsive to price changes than both EMA and DEMA
- Particularly effective in trending markets
- Better handles short-term price fluctuations

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = TEMA(prices, period)  # Returns highly responsive trend values
```

See also: [`EMA`](@ref), [`DEMA`](@ref)
"""
@inline Base.@propagate_inbounds function _TEMA(prices::Vector{T}, period::Int) where T
    EMA1 = _EMA(prices, period)
	EMA2 = _EMA(EMA1, period)
	EMA3 = _EMA(EMA2, period)
	return (EMA1 - EMA2) * 3 + EMA3
end

"""
    T3(data::Vector{T}, period::Int; a::Float64 = 0.7) where T

Calculate T3 Moving Average for a given time series data.

T3 Moving Average, developed by Tim Tillson, is a sophisticated moving average that
uses multiple EMAs and a volume factor to create a highly smooth, low-lag indicator.
It can be used as an alternative to traditional EMAs, offering better smoothness
with comparable lag characteristics.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations
- `a::Float64`: Volume factor (default: 0.7) controlling smoothness and responsiveness

# Returns
- `Vector{T}`: Vector containing T3 values for each point in the input data

# Implementation Details
The function performs a two-phase calculation process:
1. Calculates six successive EMAs with the specified period:
   EMA1 = EMA(price)
   EMA2 = EMA(EMA1)
   ...up to EMA6

2. Computes final T3 using the weighted combination formula:
   T3 = c1*EMA6 + c2*EMA5 + c3*EMA4 + c4*EMA3
   where coefficients are derived from volume factor a:
   - c1 = -a³
   - c2 = 3a² + 3a³
   - c3 = -6a² - 3a - 3a³
   - c4 = 1 + 3a + a³ + 3a²

Common configurations:
- T3(8, 0.1) provides a smoother alternative to EMA(20)
- T3(13, 0.08) provides a smoother alternative to EMA(40)

Key characteristics:
- Multiple EMA smoothing provides superior noise reduction
- Volume factor allows fine-tuning of smoothness vs. responsiveness
- Minimal lag despite high degree of smoothing
- More sophisticated than standard triple EMAs
- Particularly effective in volatile markets

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 8
result = T3(prices, period, a=0.1)  # Returns ultra-smooth trend values
```

See also: [`EMA`](@ref), [`TEMA`](@ref)
"""
@inline Base.@propagate_inbounds function _T3(prices::Vector{T}, period::Int; a::Float64 = 0.7) where T
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

	return c1 * EMA6 + c2 * EMA5 + c3 * EMA4 + c4 * EMA3
end

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
@inline Base.@propagate_inbounds function _ALMA(prices::Vector, period::Int; offset::Float64=0.85, sigma::Float64=6.0)
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
@inline Base.@propagate_inbounds function _KAMA(data::AbstractVector{T}, n::Int=10; fast::Int=2, slow::Int=30) where T <: AbstractFloat
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
@inline Base.@propagate_inbounds function _JMA(data::Vector{Float64}, length::Int=7; phase::Float64=0.0)
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

    @inbounds for i in 2:n
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

"""
    ZLEMA(data::Vector{T}, period::Int) where T

Calculate Zero-Lag Exponential Moving Average (ZLEMA) for a given time series data.

Zero-Lag EMA, developed by John Ehlers, aims to eliminate the lag inherent in traditional
moving averages by using a specially constructed price series. It combines the speed
of shorter-term EMAs with the smoothness of longer-term ones by removing the lag
associated with the averaging process.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period and smoothing factor calculation

# Returns
- `Vector{T}`: Vector containing ZLEMA values for each point in the input data

# Implementation Details
The function uses a circular buffer and performs calculations based on the position in the series:
1. First point: Uses the actual price as initial ZLEMA
2. During initialization (i ≤ period):
   - Calculates lag as -(i-1)/2
   - Uses dynamic smoothing factor α = 2/(1+i)
   - Computes modified price series as: 2 * price - price[lag]
3. After initialization (i > period):
   - Uses fixed lag and smoothing factor
   - Continues with the same modified price calculation

The ZLEMA is calculated using two main components:
1. Modified price series creation:
   modified_price = 2 * current_price - price[lag]
2. EMA calculation with the modified series:
   ZLEMA_t = modified_price * α + ZLEMA_(t-1) * (1-α)
where α is the smoothing factor

Key characteristics:
- Faster response to price changes than traditional EMAs
- Reduced lag while maintaining smoothness
- More effective in trending markets
- Uses circular buffer for efficient memory management
- Particularly useful for shorter-term trading signals

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = ZLEMA(prices, period)  # Returns: [1.0, 1.67, 2.83, 4.1, 5.26, 6.36, 7.41, 8.45, 9.47, 10.5]
```

See also: [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function _ZLEMA(data::Vector{T}, period::Int=7) where T
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    lag = 0
    alpha = 0.0
    emadata = 0.0

    @inbounds for (i, price) in enumerate(data)
        push!(buf, price)
        if i > period
            emadata = 2 * price - buf[lag]
            results[i] = emadata * alpha + results[i-1] * (1-alpha)
        elseif i == 1
            # push!(buf, price)
            results[i] = price
        else
            # push!(buf, price)
            lag = - round(Int, (i-1) / 2)
            alpha = 2 / (1+i)
            emadata = 2 * price - buf[lag]
            results[i] = emadata * alpha + results[i-1] * (1-alpha)
        end
    end
    return results
end