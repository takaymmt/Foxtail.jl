"""
    KAMA(data::AbstractVector{T}; n::Int=10, fast::Int=2, slow::Int=30) where T <: AbstractFloat

Calculate Kaufman's Adaptive Moving Average (KAMA) for a price series.

# Arguments
- `data`: Input price series
- `n`: Lookback period for efficiency ratio calculation (default: 10)
- `fast`: Fast EMA period for most efficient market (default: 2)
- `slow`: Slow EMA period for least efficient market (default: 30)

# Returns
- Vector containing KAMA values

# Algorithm
1. Calculate Efficiency Ratio (ER)
   ```
   Direction = |Price(t) - Price(t-n)|
   Volatility = Σ|Price(i) - Price(i-1)| for i = t-n+1 to t
   ER = Direction / Volatility
   ```

2. Calculate Smoothing Constant (SC)
   ```
   Fast_SC = 2/(fast + 1)
   Slow_SC = 2/(slow + 1)
   SC = [ER × (Fast_SC - Slow_SC) + Slow_SC]²
   ```

3. Calculate KAMA
   ```
   KAMA(t) = KAMA(t-1) + SC × (Price(t) - KAMA(t-1))
   ```

# Notes
- First n-1 values are set to input prices
- More responsive during trending markets (high ER)
- More stable during sideways markets (low ER)
- Minimum input length must be greater than n

# References
Kaufman, P.J. (1995). "Smarter Trading". McGraw-Hill. ISBN 0-07-034017-0.
"""
@inline Base.@propagate_inbounds function KAMA(data::AbstractVector{T}; n::Int=10, fast::Int=2, slow::Int=30) where T <: AbstractFloat
    period = n
    len = length(data)
    kama = Vector{T}(undef, len)
    kama[1] = data[1]

    fast_sc = T(2) / (fast + T(1))
    slow_sc = T(2) / (slow + T(1))
    sc_diff = fast_sc - slow_sc

    @inbounds begin
        volatility = zero(T)

        for i in 2:period
            volatility += abs(data[i] - data[i-1])
            direction = abs(data[i] - data[1])
            er = volatility > zero(T) ? direction / volatility : zero(T)
            sc = (er * sc_diff + slow_sc)^2
            kama[i] = kama[i-1] + sc * (data[i] - kama[i-1])
        end

        last_change = zero(T)
        for i in period+1:len
            volatility += abs(data[i] - data[i-1]) - last_change
            direction = abs(data[i] - data[i-period+1])
            er = direction / volatility
            sc = (er * sc_diff + slow_sc)^2
            kama[i] = kama[i-1] + sc * (data[i] - kama[i-1])
            last_change = abs(data[i-period+1] - data[i-period])
        end
    end

    return kama
end

@prep_siso KAMA n=10 (fast=2, slow=30)