"""
    ATR (Average True Range)
    ATR(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:EMA) -> TSFrame

A technical indicator that measures market volatility by calculating the average range of price movement over a specified period.

## Basic Concept
- Measures market volatility using the true range of price movement
- True Range is the greatest of:
  1. High - Low
  2. |High - Previous Close|
  3. |Low - Previous Close|
- Smooths true range values using moving averages
- Created by J. Welles Wilder Jr. (1978)

## Interpretation / Trading Signals
- Higher values: Increased volatility
- Lower values: Decreased volatility
- Common uses:
  - Stop-loss placement
  - Position sizing
  - Breakout confirmation
- Best for volatility assessment, not price direction

## Usage Examples
```julia
# Basic usage
result = ATR(price_data)

# Custom settings
result = ATR(price_data, 20, ma_type=:SMA)
result = ATR(price_data, field=[:high, :low, :close])
```

## Core Formula
```math
TR_t = max(high_t - low_t, |high_t - close_{t-1}|, |low_t - close_{t-1}|)
ATR_t = MA(TR, period)
```

## Parameters and Arguments
- `ts::TSFrame`: Time series data with high, low, and close prices
- `period::Int`: (Default: 14)
  - Lookback period for moving average
  - Valid range: > 0
- `field::Vector{Symbol}`: (Default: [:High, :Low, :Close])
  - Column names for price data
- `ma_type::Symbol`: (Default: :EMA)
  - Moving average type: :SMA, :EMA, or :SMMA/:RMA

## Returns
- `TSFrame`: Single column :ATR containing the indicator values

## Implementation Details
1. Calculate True Range for each period
2. Apply specified moving average
3. Return results in TSFrame format
"""
@inline Base.@propagate_inbounds function ATR(prices::Matrix{Float64}; n::Int=14, ma_type::Symbol=:EMA)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [high low close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    true_ranges = TR(prices)

    if ma_type == :SMA
        return SMA(true_ranges; n=period)
    elseif ma_type == :EMA
        return EMA(true_ranges; n=period)
    elseif ma_type == :SMMA || ma_type == :RMA
        return SMMA(true_ranges; n=period)
    else
        throw(ArgumentError("ma_type must be either :SMA or :EMA"))
    end
end

@inline Base.@propagate_inbounds function TR(prices::Matrix{Float64})
    n = size(prices, 1)
    result = zeros(n)

    result[1] = prices[1, 1] - prices[1, 2]

    @inbounds for i in 2:n
        high = prices[i, 1]
        low = prices[i, 2]
        prev_close = prices[i-1, 3]

        range1 = high - low
        range2 = abs(high - prev_close)
        range3 = abs(low - prev_close)

        result[i] = max(range1, range2, range3)
    end

    return result
end

@prep_miso ATR [High, Low, Close] n=14 ma_type=EMA

# function ATR(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:EMA)
#     prices = ts[:,field] |> Matrix
#     results = ATR(prices, period; ma_type=ma_type)
#     col_name = :ATR
#     return TSFrame(results, index(ts), colnames=[col_name])
# end
# export ATR