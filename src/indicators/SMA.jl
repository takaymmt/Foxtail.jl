"""
    SMA(data::Vector{T}; n::Int) where T

Calculate Simple Moving Average (SMA) for a given time series data.

Simple Moving Average is calculated as the arithmetic mean of a specified number of
prices over a moving window. This implementation uses a circular buffer for efficient
memory management.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `n::Int`: Length of the moving window for average calculation

# Returns
- `Vector{T}`: Vector containing SMA values for each point in the input data

# Implementation Details
The function maintains a running sum using a circular buffer to optimize performance:
- For full buffer: Updates running sum by removing oldest price and adding new price
- For partial buffer: Accumulates sum and computes average using current buffer length

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
result = SMA(prices; n=4)
```
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
    SMA_stats(prices::Vector{T}; n::Int=14) where T

Calculate Simple Moving Average (SMA) and Standard Deviation for a given time series data.

# Arguments
- `prices::Vector{T}`: Input price vector of any numeric type
- `n::Int=14`: Length of the moving window for calculations

# Returns
- `Matrix{T}`: A matrix of size (length(prices), 2) where:
  - Column 1: SMA values
  - Column 2: Standard deviation values

# Implementation Details
Uses a circular buffer for efficient memory management and maintains running sums for
both prices and squared prices to optimize performance:
- For full buffer (i > n): Updates running sums by removing oldest values and adding new ones
- For partial buffer (i ≤ n): Accumulates sums and computes statistics using current buffer length

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
sma_std = SMA_stats(prices; n=4)
# sma_std[:,1] contains SMA values
# sma_std[:,2] contains standard deviation values
```

# Mathematical Details
Standard deviation is calculated using an online algorithm that maintains running sums:
- Running sum (S₁) = Σxᵢ
- Running sum of squares (S₂) = Σxᵢ²
- Mean (μ) = S₁/n
- Variance (σ²) = S₂/n - μ²
- Standard deviation (σ) = √(max(0, σ²))
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