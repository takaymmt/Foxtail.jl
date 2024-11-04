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
@inline Base.@propagate_inbounds function SMA(data::Vector{T}, period::Int) where T
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

@prep_SISO SMA