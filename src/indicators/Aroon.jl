"""
    Aroon(prices::Matrix{Float64}; n::Int=25) -> Matrix{Float64}

Calculate Aroon indicator — measures trend strength by tracking how long since the highest high and lowest low.

## Parameters
- `prices`: Price matrix with 2 columns `[High, Low]` (`Float64`).
- `n`: Lookback period (default: 25). Valid range: `n >= 1`.

## Returns
Matrix of size `(rows, 3)`:
- Column 1: Aroon Up — proximity of the most recent high to the current bar
- Column 2: Aroon Down — proximity of the most recent low to the current bar
- Column 3: Aroon Oscillator — difference between Up and Down

## Formula
```math
\\text{AroonUp}_i   = 100 \\times \\frac{n - (i - \\text{idx of highest high in window})}{n}
\\text{AroonDown}_i = 100 \\times \\frac{n - (i - \\text{idx of lowest low in window})}{n}
\\text{Oscillator}_i = \\text{AroonUp}_i - \\text{AroonDown}_i
```

The window covers bars `[max(1, i-n), i]` (up to `n+1` bars).

## Interpretation
- Aroon Up > 70: strong uptrend (recent new high).
- Aroon Down > 70: strong downtrend (recent new low).
- Aroon Up crosses above Aroon Down: bullish signal.
- Aroon Down crosses above Aroon Up: bearish signal.
- Oscillator near 0: consolidation / no clear trend.
- Range: Up ∈ [0, 100], Down ∈ [0, 100], Oscillator ∈ [-100, 100].
- Created by: Tushar Chande (1995).

## Example
```julia
# prices: [High Low]
prices = [105.0 100.0; 106.0 101.0; 107.0 102.0; 108.0 103.0]
result = Aroon(prices; n=2)
# result[:,1] = AroonUp, result[:,2] = AroonDown, result[:,3] = Oscillator
```

## See Also
[`DMI`](@ref), [`RSI`](@ref), [`Stoch`](@ref)
"""
@inline Base.@propagate_inbounds function Aroon(prices::Matrix{Float64}; n::Int=25)
    if size(prices, 2) != 2
        throw(ArgumentError("prices matrix must have 2 columns [High, Low]"))
    end

    if n < 1
        throw(ArgumentError("period n must be positive"))
    end

    nrows = size(prices, 1)
    if nrows < 1
        throw(ArgumentError("price series must not be empty"))
    end

    result = zeros(Float64, nrows, 3)
    mmq = MinMaxQueue{Float64}(n + 2)

    @inbounds for i in 1:nrows
        update!(mmq, prices[i, 1], prices[i, 2], i)
        remove_old!(mmq, i - n - 1)  # keep indices in [i-n, i] (n+1 bars max)

        max_idx = get_max_idx(mmq)
        min_idx = get_min_idx(mmq)

        aroon_up   = 100.0 * (n - (i - max_idx)) / n
        aroon_down = 100.0 * (n - (i - min_idx)) / n

        result[i, 1] = aroon_up
        result[i, 2] = aroon_down
        result[i, 3] = aroon_up - aroon_down
    end

    return result
end

@prep_mimo Aroon [High, Low] [Up, Down, Oscillator] n=25
