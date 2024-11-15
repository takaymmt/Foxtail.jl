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
@inline Base.@propagate_inbounds function ZLEMA(data::Vector{T}; n::Int=10) where T
    period = n
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    lag = 0
    alpha = 0.0
    emadata = 0.0

    @inbounds results[1] = data[1]
    push!(buf, data[1])

    @inbounds for i in 2:period
        price = data[i]
        push!(buf, price)
        lag = -round(Int, (i-1) / 2)
        alpha = 2 / (1+i)
        emadata = 2 * price - buf[lag]
        results[i] = emadata * alpha + results[i-1] * (1-alpha)
    end

    @inbounds for i in (period+1):length(data)
        price = data[i]
        push!(buf, price)
        emadata = 2 * price - buf[lag]
        results[i] = emadata * alpha + results[i-1] * (1-alpha)
    end
    return results
end

@prep_siso ZLEMA n=10