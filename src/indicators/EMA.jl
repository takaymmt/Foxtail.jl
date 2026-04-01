"""
    EMA(data::Vector{T}; n::Int=10) where T -> Vector{T}

Calculate Exponential Moving Average (EMA) — a weighted moving average that gives more weight to recent prices.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Smoothing period (default: 10). Valid range: `n >= 1`.

## Returns
Vector of EMA values. The first value equals the first input price.

## Formula
```math
EMA_t = P_t \\times \\alpha + EMA_{t-1} \\times (1 - \\alpha), \\quad \\alpha = \\frac{2}{n + 1}
```

During initialization (`i <= n`), a dynamic smoothing factor `alpha = 2/(1+i)` is used.

## Interpretation
- More responsive to recent price changes than SMA due to exponential weighting.
- Price crossing above/below EMA can signal trend changes.
- Common periods: 9, 12, 26 (MACD components), 50, 200 (long-term trend).
- Multiple EMA crossovers (e.g., 12/26) form the basis of MACD.

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = EMA(prices; n=4)
```

## See Also
[`SMA`](@ref), [`DEMA`](@ref), [`TEMA`](@ref), [`ZLEMA`](@ref)
"""
@inline Base.@propagate_inbounds function EMA(data::Vector{T}; n::Int=10) where T
    period = n
    results = zeros(T, length(data))
    alpha = 0.0

    # First value initialization
    @inbounds results[1] = data[1]

    # Calculate alpha for period > 1
    @inbounds for i in 2:period
        alpha = 2 / (1 + i)
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end

    # Fixed alpha for remaining values
    alpha = 2 / (1 + period)
    @inbounds for i in (period+1):length(data)
        results[i] = data[i] * alpha + results[i-1] * (1 - alpha)
    end
    return results
end

@prep_siso EMA n=10

"""
    EMA_stats(data::Vector{T}; n::Int=10) where T -> Matrix{T}

Calculate Exponential Moving Average (EMA) and its standard deviation simultaneously.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Smoothing period (default: 10). Valid range: `n >= 1`.

## Returns
Matrix of size `(length(data), 2)`:
- Column 1: EMA values
- Column 2: Standard deviation values (exponentially weighted)

## Formula
```math
\\mu_t = \\alpha \\cdot P_t + (1 - \\alpha) \\cdot \\mu_{t-1}, \\quad
\\sigma^2_t = (1 - \\alpha)(\\sigma^2_{t-1} + \\alpha (P_t - \\mu_{t-1})^2)
```

Based on the recursive method from "Incremental calculation of weighted mean and variance"
(Tony Finch, 2009).

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
ema_std = EMA_stats(prices; n=4)
# ema_std[:,1] contains EMA values
# ema_std[:,2] contains standard deviation values
```

## See Also
[`EMA`](@ref), [`SMA_stats`](@ref), [`BB`](@ref)
"""
@inline Base.@propagate_inbounds function EMA_stats(data::Vector{T}; n::Int=10) where T
    period = n
    results = zeros(T, length(data), 2)
    alpha = 0.0

    # Initialize with first value
    @inbounds results[1, 1] = data[1]  # mean
    @inbounds results[1, 2] = zero(T)  # std

    # Previous values for recursive calculation
    prev_mean = data[1]
    prev_variance = zero(T)

    @inbounds for i in 2:length(data)
        # Set appropriate alpha based on position
        if i > period
            alpha = 2 / (1 + period)
        else
            alpha = 2 / (1 + i)
        end

        # Calculate difference from previous mean
        diff = data[i] - prev_mean

        # Update mean
        incr = alpha * diff
        new_mean = prev_mean + incr

        # Update variance using the recursive formula
        new_variance = (1 - alpha) * (prev_variance + diff * incr)

        # Store results
        results[i, 1] = new_mean
        results[i, 2] = sqrt(max(zero(T), new_variance))

        # Update previous values for next iteration
        prev_mean = new_mean
        prev_variance = new_variance
    end

    return results
end

# export EMA_stats