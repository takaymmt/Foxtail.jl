"""
    OBV
    OBV(ts::TSFrame; field::Vector{Symbol} = [:Close, :Volume]) -> TSFrame

On Balance Volume (OBV) is a momentum indicator that uses volume flow to predict changes in stock price.

## Basic Concept
- Measures buying and selling pressure using volume
- Assumes that volume precedes price movement
- Cumulative indicator that adds volume on up days and subtracts it on down days
- Created by Joe Granville and first introduced in his 1963 book "Granville's New Key to Stock Market Profits"

## Parameters and Arguments
- `ts::TSFrame`: Time series data frame containing price and volume data
- `field::Vector{Symbol}`: (Default: [:Close, :Volume])
  - Specifies the column names for price and volume data
  - Must contain exactly two columns in order: [price, volume]
  - Valid columns must exist in the TSFrame

## Returns
- `TSFrame`: New TSFrame containing:
  - Same index as input TSFrame
  - Single column [:OBV] with calculated OBV values
  - First value initialized with the first period's volume

## Interpretation / Trading Signals
- Rising OBV: Indicates buying pressure, potentially preceding price increases
- Falling OBV: Suggests selling pressure, potentially preceding price decreases
- OBV divergence from price: Possible trend reversal signal
- Best used in conjunction with price action and other indicators
- Most effective in trending markets

## Usage Examples
```julia
Basic usage with default parameters
obv = OBV(tsframe)
Specifying custom price and volume columns
obv = OBV(tsframe, field=[:AdjClose, :Volume])
```

## Core Formula
The OBV is calculated by adding or subtracting each period's volume based on whether the closing price increased or decreased.

```math
OBV_t = \begin{cases}
OBV_{t-1} + Volume_t & \text{if } Close_t > Close_{t-1} \\
OBV_{t-1} - Volume_t & \text{if } Close_t < Close_{t-1} \\
OBV_{t-1} & \text{if } Close_t = Close_{t-1}
\end{cases}
```
"""
@inline Base.@propagate_inbounds function OBV(data::Matrix{Float64})
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [close volume]"))
    end

    n = size(data, 1)
    results = zeros(n)

    # Extract price and volume data
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Initialize first value with first volume
    @inbounds results[1] = volumes[1]

    # Calculate OBV
    @inbounds for i in 2:n
        if closes[i] > closes[i-1]
            results[i] = results[i-1] + volumes[i]
        elseif closes[i] < closes[i-1]
            results[i] = results[i-1] - volumes[i]
        else
            results[i] = results[i-1]
        end
    end

    return results
end

@prep_miso OBV [Close, Volume]

# function OBV(ts::TSFrame; field::Vector{Symbol} = [:Close, :Volume])
# 	data = ts[:, field] |> Matrix
# 	results = OBV(data)
# 	colnames = [:OBV]
# 	return TSFrame(results, index(ts), colnames = colnames)
# end
# export OBV