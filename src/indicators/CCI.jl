"""
    CCI(prices::Matrix{Float64}; n::Int=20) -> Vector{Float64}

Calculate Commodity Channel Index (CCI) — a momentum oscillator measuring deviation from the statistical mean.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period for the moving average and mean absolute deviation (default: 20). Valid range: `n >= 1`.

## Returns
Vector of CCI values with the same length as the number of input rows.

## Formula
```math
TP_t = \\frac{H_t + L_t + C_t}{3}, \\quad
SMA_n = \\frac{1}{n}\\sum_{i=t-n+1}^{t} TP_i, \\quad
MAD_n = \\frac{1}{n}\\sum_{i=t-n+1}^{t} |TP_i - SMA_n|
```
```math
CCI_t = \\frac{TP_t - SMA_n}{0.015 \\times MAD_n}
```

For `i < n`, a partial window of available bars is used. When `MAD = 0`, `CCI = 0.0`.

## Interpretation
- CCI > +100 indicates overbought conditions (strong uptrend).
- CCI < -100 indicates oversold conditions (strong downtrend).
- Zero-line crossovers signal momentum shifts.
- Divergence between CCI and price can signal reversals.
- The 0.015 constant ensures approximately 70-80% of CCI values fall between -100 and +100.
- Created by: Donald Lambert (1980, "Commodity Channel Index: Tools for Trading Cyclical Trends").

## Example
```julia
# prices matrix: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 104.0 99.0 100.0]
result = CCI(prices; n=2)
```

## See Also
[`RSI`](@ref), [`ROC`](@ref)
"""
@inline Base.@propagate_inbounds function CCI(prices::Matrix{Float64}; n::Int=20)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High Low Close]"))
    end

    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    nrows = size(prices, 1)
    results = zeros(nrows)

    highs  = @view prices[:, 1]
    lows   = @view prices[:, 2]
    closes = @view prices[:, 3]

    cb = CircBuff{Float64}(n)

    @inbounds for i in 1:nrows
        tp = (highs[i] + lows[i] + closes[i]) / 3.0
        push!(cb, tp)

        # Compute SMA of TP over current window
        buf = value(cb)
        wlen = length(cb)
        sma_tp = 0.0
        for j in 1:wlen
            sma_tp += buf[j]
        end
        sma_tp /= wlen

        # Compute Mean Absolute Deviation
        mad = 0.0
        for j in 1:wlen
            mad += abs(buf[j] - sma_tp)
        end
        mad /= wlen

        # CCI calculation
        if mad == 0.0
            results[i] = 0.0
        else
            results[i] = (tp - sma_tp) / (0.015 * mad)
        end
    end

    return results
end

@prep_miso CCI [High, Low, Close] n=20
