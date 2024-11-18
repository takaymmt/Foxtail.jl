"""
    ZLEMA(data::Vector{T}; n::Int=10) where T

Calculate Zero-Lag Exponential Moving Average (ZLEMA) for a given time series.

# Arguments
- `data::Vector{T}`: Input price series
- `n::Int=10`: Period length for ZLEMA calculation

# Returns
- `Vector{T}`: ZLEMA values for the input series

# Details
ZLEMA reduces lag in traditional moving averages by using a modified price series:
1. Modified price = 2 * current_price - price[lag]
2. ZLEMA = α * modified_price + (1-α) * previous_ZLEMA

Where:
- lag = -(period-1)/2
- α = 2/(1+period)

# Example
```julia
prices = [100.0, 101.0, 102.0, 103.0, 104.0]
zlema = ZLEMA(prices, n=3)
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