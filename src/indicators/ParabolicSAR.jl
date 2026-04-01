"""
    ParabolicSAR(prices::Matrix{Float64}; af_start::Float64=0.02, af_step::Float64=0.02, af_max::Float64=0.20) -> Matrix{Float64}

Calculate Parabolic SAR (Stop and Reverse) — Wilder's trend-following indicator that provides potential stop-loss levels.

## Parameters
- `prices`: Price matrix with 2 columns `[High, Low]` (`Float64`).
- `af_start`: Initial acceleration factor (default: 0.02). Valid range: `af_start > 0`.
- `af_step`: Acceleration factor increment (default: 0.02). Valid range: `af_step > 0`.
- `af_max`: Maximum acceleration factor (default: 0.20). Valid range: `af_max >= af_start`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: SAR value (the stop-and-reverse price level).
- Column 2: Trend direction (`1.0` = uptrend, `-1.0` = downtrend).

## Formula
```math
SAR_{t} = SAR_{t-1} + AF \\times (EP - SAR_{t-1})
```

Where:
- `EP` (Extreme Point) = highest high during uptrend, lowest low during downtrend.
- `AF` (Acceleration Factor) starts at `af_start`, increases by `af_step` each time a new EP is reached, capped at `af_max`.
- SAR is clamped so it does not exceed the two previous bars' range (lows in uptrend, highs in downtrend).
- A reversal occurs when price crosses the SAR level.

## Interpretation
- Direction = 1.0 (uptrend): SAR is below price — acts as a trailing stop beneath the market.
- Direction = -1.0 (downtrend): SAR is above price — acts as a trailing stop above the market.
- Created by: J. Welles Wilder Jr. (1978).

## Example
```julia
# prices: [High Low]
prices = [105.0 100.0; 106.0 101.0; 104.0 99.0; 107.0 102.0]
result = ParabolicSAR(prices)
# result[:,1] = SAR value, result[:,2] = Direction
```

## See Also
[`Supertrend`](@ref), [`ATR`](@ref)
"""
@inline Base.@propagate_inbounds function ParabolicSAR(prices::Matrix{Float64};
    af_start::Float64=0.02, af_step::Float64=0.02, af_max::Float64=0.20)

    if size(prices, 2) != 2
        throw(ArgumentError("prices matrix must have 2 columns [High, Low]"))
    end

    if af_start <= 0.0
        throw(ArgumentError("af_start must be positive"))
    end

    if af_step <= 0.0
        throw(ArgumentError("af_step must be positive"))
    end

    if af_max < af_start
        throw(ArgumentError("af_max must be >= af_start"))
    end

    len = size(prices, 1)
    result = zeros(len, 2)

    if len == 0
        return result
    end

    highs = @view prices[:, 1]
    lows  = @view prices[:, 2]

    # Initialization (bar 1): assume uptrend
    trend = 1     # 1 = uptrend, -1 = downtrend
    sar   = lows[1]
    ep    = highs[1]
    af    = af_start

    @inbounds result[1, 1] = sar
    @inbounds result[1, 2] = 1.0

    if len == 1
        return result
    end

    @inbounds for i in 2:len
        # Tentative new SAR
        new_sar = sar + af * (ep - sar)

        if trend == 1  # uptrend
            # SAR must not be higher than the two previous lows
            new_sar = min(new_sar, lows[i-1])
            if i >= 3
                new_sar = min(new_sar, lows[i-2])
            end

            if lows[i] <= new_sar
                # Reversal to downtrend
                trend = -1
                new_sar = ep          # SAR becomes the previous EP (highest high)
                ep = lows[i]          # new EP is the current low
                af = af_start
            else
                # Continue uptrend — check for new extreme point
                if highs[i] > ep
                    ep = highs[i]
                    af = min(af + af_step, af_max)
                end
            end
        else  # downtrend
            # SAR must not be lower than the two previous highs
            new_sar = max(new_sar, highs[i-1])
            if i >= 3
                new_sar = max(new_sar, highs[i-2])
            end

            if highs[i] >= new_sar
                # Reversal to uptrend
                trend = 1
                new_sar = ep          # SAR becomes the previous EP (lowest low)
                ep = highs[i]         # new EP is the current high
                af = af_start
            else
                # Continue downtrend — check for new extreme point
                if lows[i] < ep
                    ep = lows[i]
                    af = min(af + af_step, af_max)
                end
            end
        end

        sar = new_sar
        result[i, 1] = sar
        result[i, 2] = Float64(trend)
    end

    return result
end

@prep_mimo ParabolicSAR [High, Low] [Value, Direction] af_start=0.02 af_step=0.02 af_max=0.20
