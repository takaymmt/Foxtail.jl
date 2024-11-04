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
@inline Base.@propagate_inbounds function SMMA(data::Vector{T}, period::Int) where T
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

@prep_SISO SMMA

RMA(ts::TSFrame, period::Int; field::Symbol = :Close) = SMMA(ts, period; field)
export RMA