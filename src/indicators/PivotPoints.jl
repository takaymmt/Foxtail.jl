"""
    PivotPoints(prices::Matrix{Float64}; method::Symbol=:Classic) -> Matrix{Float64}

Calculate Pivot Points — support and resistance levels from high, low, close, and open prices.

## Parameters
- `prices`: Price matrix with 4 columns `[High, Low, Close, Open]` (`Float64`).
- `method`: Calculation method (default: `:Classic`).
  Options: `:Classic`, `:Fibonacci`, `:Woodie`, `:Camarilla`, `:DeMark`.

## Returns
Matrix of size `(rows, 7)`:
- Column 1: Pivot (P)
- Column 2: R1 (Resistance 1)
- Column 3: R2 (Resistance 2)
- Column 4: R3 (Resistance 3)
- Column 5: S1 (Support 1)
- Column 6: S2 (Support 2)
- Column 7: S3 (Support 3)

## Methods
- **Classic**: Standard floor trader pivots. `P = (H + L + C) / 3`.
- **Fibonacci**: Fibonacci retracement levels from pivot. Same P as Classic.
- **Woodie**: Weights current Open. `P = (H + L + 2*O) / 4`.
- **Camarilla**: Levels centered on Close. Same P as Classic.
- **DeMark**: Conditional formula based on Open vs Close. R2/R3/S2/S3 are NaN.

## Interpretation
- S3 < S2 < S1 < Pivot < R1 < R2 < R3 (for Classic, Fibonacci, Camarilla with normal data).
- Price above Pivot: bullish bias. Price below Pivot: bearish bias.
- R1/S1: first resistance/support. R2/S2: second level. R3/S3: third level.
- Each bar is computed independently from its own HLCO values (no lookback needed).

## Example
```julia
# prices: [High Low Close Open]
prices = [110.0 100.0 105.0 102.0; 112.0 101.0 108.0 106.0]
result = PivotPoints(prices; method=:Classic)
# result[:,1] = Pivot, result[:,2] = R1, ..., result[:,7] = S3
```

## See Also
[`BB`](@ref), [`KeltnerChannel`](@ref), [`DonchianChannel`](@ref)
"""
@inline Base.@propagate_inbounds function PivotPoints(prices::Matrix{Float64}; method::Symbol=:Classic)
    if size(prices, 2) != 4
        throw(ArgumentError("prices matrix must have 4 columns [High, Low, Close, Open]"))
    end

    nrows = size(prices, 1)

    highs  = @view prices[:, 1]
    lows   = @view prices[:, 2]
    closes = @view prices[:, 3]
    opens  = @view prices[:, 4]

    result = method == :DeMark ? fill(NaN, nrows, 7) : zeros(nrows, 7)

    if method == :Classic
        _pivot_classic!(result, highs, lows, closes)
    elseif method == :Fibonacci
        _pivot_fibonacci!(result, highs, lows, closes)
    elseif method == :Woodie
        _pivot_woodie!(result, highs, lows, opens)
    elseif method == :Camarilla
        _pivot_camarilla!(result, highs, lows, closes)
    elseif method == :DeMark
        _pivot_demark!(result, highs, lows, closes, opens)
    else
        throw(ArgumentError("Unknown method: $method. Valid: :Classic, :Fibonacci, :Woodie, :Camarilla, :DeMark"))
    end

    return result
end

@inline Base.@propagate_inbounds function _pivot_classic!(
    result::Matrix{Float64},
    highs::AbstractVector{Float64},
    lows::AbstractVector{Float64},
    closes::AbstractVector{Float64}
)
    @inbounds for i in eachindex(highs)
        H = highs[i]
        L = lows[i]
        C = closes[i]
        P = (H + L + C) / 3.0
        R = H - L

        result[i, 1] = P           # Pivot
        result[i, 2] = 2.0 * P - L # R1
        result[i, 3] = P + R       # R2
        result[i, 4] = H + 2.0 * (P - L)  # R3
        result[i, 5] = 2.0 * P - H # S1
        result[i, 6] = P - R       # S2
        result[i, 7] = L - 2.0 * (H - P)  # S3
    end
end

@inline Base.@propagate_inbounds function _pivot_fibonacci!(
    result::Matrix{Float64},
    highs::AbstractVector{Float64},
    lows::AbstractVector{Float64},
    closes::AbstractVector{Float64}
)
    @inbounds for i in eachindex(highs)
        H = highs[i]
        L = lows[i]
        C = closes[i]
        P = (H + L + C) / 3.0
        R = H - L

        result[i, 1] = P                   # Pivot
        result[i, 2] = P + 0.382 * R       # R1
        result[i, 3] = P + 0.618 * R       # R2
        result[i, 4] = P + 1.000 * R       # R3
        result[i, 5] = P - 0.382 * R       # S1
        result[i, 6] = P - 0.618 * R       # S2
        result[i, 7] = P - 1.000 * R       # S3
    end
end

@inline Base.@propagate_inbounds function _pivot_woodie!(
    result::Matrix{Float64},
    highs::AbstractVector{Float64},
    lows::AbstractVector{Float64},
    opens::AbstractVector{Float64}
)
    @inbounds for i in eachindex(highs)
        H = highs[i]
        L = lows[i]
        O = opens[i]
        P = (H + L + 2.0 * O) / 4.0
        R = H - L

        result[i, 1] = P           # Pivot
        result[i, 2] = 2.0 * P - L # R1
        result[i, 3] = P + R       # R2
        result[i, 4] = H + 2.0 * (P - L)  # R3
        result[i, 5] = 2.0 * P - H # S1
        result[i, 6] = P - R       # S2
        result[i, 7] = L - 2.0 * (H - P)  # S3
    end
end

@inline Base.@propagate_inbounds function _pivot_camarilla!(
    result::Matrix{Float64},
    highs::AbstractVector{Float64},
    lows::AbstractVector{Float64},
    closes::AbstractVector{Float64}
)
    @inbounds for i in eachindex(highs)
        H = highs[i]
        L = lows[i]
        C = closes[i]
        P = (H + L + C) / 3.0
        R = H - L

        result[i, 1] = P                       # Pivot
        result[i, 2] = C + 1.1 * R / 12.0      # R1
        result[i, 3] = C + 1.1 * R / 6.0       # R2
        result[i, 4] = C + 1.1 * R / 4.0       # R3
        result[i, 5] = C - 1.1 * R / 12.0      # S1
        result[i, 6] = C - 1.1 * R / 6.0       # S2
        result[i, 7] = C - 1.1 * R / 4.0       # S3
    end
end

@inline Base.@propagate_inbounds function _pivot_demark!(
    result::Matrix{Float64},
    highs::AbstractVector{Float64},
    lows::AbstractVector{Float64},
    closes::AbstractVector{Float64},
    opens::AbstractVector{Float64}
)
    @inbounds for i in eachindex(highs)
        H = highs[i]
        L = lows[i]
        C = closes[i]
        O = opens[i]

        # Conditional X calculation
        X = if C < O
            H + 2.0 * L + C
        elseif C > O
            2.0 * H + L + C
        else  # C == O
            H + L + 2.0 * C
        end

        result[i, 1] = X / 4.0         # Pivot
        result[i, 2] = X / 2.0 - L     # R1
        # R2, R3 remain NaN (initialized)
        result[i, 5] = X / 2.0 - H     # S1
        # S2, S3 remain NaN (initialized)
    end
end

@prep_mimo PivotPoints [High, Low, Close, Open] [Pivot, R1, R2, R3, S1, S2, S3] method=Classic
