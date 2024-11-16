"""
    ATR (Average True Range)
    ATR(ts::TSFrame, period::Int=14; field::Vector{Symbol}=[:High, :Low, :Close], ma_type::Symbol=:EMA) -> TSFrame

Average True Range (ATR) is a technical analysis indicator that measures market volatility by decomposing the entire range of an asset price for a specific period.

## Basic Concept
- ATR measures market volatility by calculating the average of the true range over a specified period
- True Range is the greatest of:
  1. Current high minus current low
  2. Absolute value of current high minus previous close
  3. Absolute value of current low minus previous close
- Uses moving averages to smooth the true range values
- Developed by J. Welles Wilder Jr. and introduced in his 1978 book "New Concepts in Technical Trading Systems"

## Interpretation / Trading Signals
- Higher ATR values indicate higher volatility
- Lower ATR values suggest lower volatility
- Often used to:
  - Set stop-loss levels
  - Identify potential breakout points
  - Adjust position sizes based on volatility
- Works best when:
  - Evaluating trend strength
  - Setting price targets
  - Identifying potential market reversals
- Less effective in:
  - Determining price direction
  - Predicting price levels

## Usage Examples
```julia
# Basic usage with default parameters
result = ATR(price_data)

# Custom period and moving average type
result = ATR(price_data, 20, ma_type=:SMA)

# Specifying different column names
result = ATR(price_data, field=[:high, :low, :close])
```

## Core Formula
```math
TR_t = max(high_t - low_t, |high_t - close_{t-1}|, |low_t - close_{t-1}|)
```
```math
ATR_t = MA(TR, period)
```

Key components:
- TR_t: True Range at time t
- high_t: Current period's high price
- low_t: Current period's low price
- close_{t-1}: Previous period's closing price
- MA: Moving Average (can be SMA, EMA, or SMMA/RMA)

## Parameters and Arguments
- `ts::TSFrame`:
  - Time series data frame containing price data
  - Must include high, low, and close prices
  - Data should be arranged chronologically

- `period::Int`: (Default: 14)
  - Number of periods for the moving average calculation
  - Valid range: > 0
  - Typical ranges:
    - Short-term (7-10): More sensitive to volatility changes
    - Standard (14): Balanced sensitivity
    - Long-term (20-30): Smoother, less sensitive
  - Impact: Larger values produce smoother results but increase lag

- `field::Vector{Symbol}`: (Default: [:High, :Low, :Close])
  - Column names in the TSFrame for price data
  - Must contain three columns in order: high, low, close
  - Case sensitive

- `ma_type::Symbol`: (Default: :EMA)
  - Type of moving average to use
  - Options:
    - :SMA: Simple Moving Average
    - :EMA: Exponential Moving Average
    - :SMMA or :RMA: Smoothed Moving Average
  - Impact: Different smoothing characteristics and lag

## Returns
- `TSFrame`:
  - Single column named :ATR
  - Same index as input TSFrame
  - Contains ATR values for each period
  - First `period-1` rows may contain initialization values
  - NaN values possible during the initialization period

## Implementation Details
Algorithm overview:
1. Calculate True Range for each period
2. Apply specified moving average to True Range values
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