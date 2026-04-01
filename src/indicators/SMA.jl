"""
    SMA(data::Vector{T}; n::Int=14) where T -> Vector{T}

Calculate Simple Moving Average (SMA) — the arithmetic mean of prices over a moving window.

## Parameters
- `data`: Input price vector of any numeric type.
- `n`: Length of the moving window (default: 14). Valid range: `n >= 1`.

## Returns
Vector of SMA values. During the initialization period (first `n` elements),
the average is computed over the available data points so far.

## Formula
```math
SMA_t = \\frac{1}{n} \\sum_{i=0}^{n-1} P_{t-i}
```

## Interpretation
- The most basic trend-following indicator; smooths out short-term price fluctuations.
- Price above SMA suggests an uptrend; price below suggests a downtrend.
- Commonly used periods: 10, 20, 50, 100, 200.
- Crossovers between short-period and long-period SMAs generate trading signals.

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = SMA(prices; n=4)
```

## See Also
[`EMA`](@ref), [`WMA`](@ref), [`TMA`](@ref)
"""
@inline Base.@propagate_inbounds function SMA(data::Vector{T}; n::Int=14) where T
    period = n
    buf = CircBuff{T}(period)
    results = zeros(T, length(data))
    running_sum = zero(T)

    # Initialize first period elements
    @inbounds for i in 1:min(period, length(data))
        price = data[i]
        push!(buf, price)
        running_sum += price
        results[i] = running_sum / i
    end

    # Process remaining elements
    @inbounds for i in (period+1):length(data)
        price = data[i]
        running_sum = running_sum - first(buf) + price
        results[i] = running_sum / period
        push!(buf, price)
    end
    return results
end

@prep_siso SMA n=14

"""
    SMA_stats(prices::Vector{T}; n::Int=14) where T -> Matrix{T}

Calculate Simple Moving Average (SMA) and Standard Deviation simultaneously for a given time series.

## Parameters
- `prices`: Input price vector of any numeric type.
- `n`: Length of the moving window (default: 14). Valid range: `n >= 1`.

## Returns
Matrix of size `(length(prices), 2)`:
- Column 1: SMA values
- Column 2: Standard deviation values

## Formula
```math
\\mu_t = \\frac{1}{n}\\sum_{i=0}^{n-1} P_{t-i}, \\quad
\\sigma_t = \\sqrt{\\frac{\\sum_{i=0}^{n-1} P_{t-i}^2}{n} - \\mu_t^2}
```

## Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
sma_std = SMA_stats(prices; n=4)
# sma_std[:,1] contains SMA values
# sma_std[:,2] contains standard deviation values
```

## See Also
[`SMA`](@ref), [`EMA_stats`](@ref), [`BB`](@ref)
"""
@inline Base.@propagate_inbounds function SMA_stats(prices::Vector{T}; n::Int=14) where T
    period = n
    buf = CircBuff{T}(period)
    results = zeros(T, (length(prices), 2))  # Column 1: SMA, Column 2: STD
    running_sum = zero(T)
    running_sum_x2 = zero(T)

    @inbounds for (i, price) in enumerate(prices)
        if i > period
            out = first(buf)
            running_sum = running_sum - out + price
            running_sum_x2 = running_sum_x2 - out^2 + price^2
            mean = running_sum / period
            variance = running_sum_x2 / period - mean^2
            results[i,1] = mean
            results[i,2] = sqrt(max(zero(T), variance))
            push!(buf, price)
        else
            push!(buf, price)
            running_sum += price
            running_sum_x2 += price^2
            mean = running_sum / i
            variance = running_sum_x2 / i - mean^2
            results[i,1] = mean
            results[i,2] = sqrt(max(zero(T), variance))
        end
    end
    return results
end

# export SMA_stats