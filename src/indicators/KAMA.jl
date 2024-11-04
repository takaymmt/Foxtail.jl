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
@inline Base.@propagate_inbounds function KAMA(data::AbstractVector{T}, n::Int=10; fast::Int=2, slow::Int=30) where T <: AbstractFloat
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

@prep_SISO KAMA (fast=2, slow=30)