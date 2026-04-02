"""
    ConnorsRSI(prices::Vector{Float64}; n_rsi::Int=3, n_streak::Int=2, n_pctrank::Int=100) -> Vector{Float64}

Calculate Connors RSI — a composite momentum oscillator combining three normalized components: short-term RSI, streak RSI, and percentile rank of rate of change.

## Parameters
- `prices`: Input price vector (`Float64`), typically closing prices.
- `n_rsi`: RSI period for the price RSI component (default: 3). Valid range: `n_rsi >= 1`.
- `n_streak`: RSI period applied to the streak values (default: 2). Valid range: `n_streak >= 1`.
- `n_pctrank`: Lookback period for percentile rank of 1-period ROC (default: 100). Valid range: `n_pctrank >= 1`.

## Returns
Vector of ConnorsRSI values (0-100 scale). Early values are 0.0 (warmup inherited from
component functions RSI and ROC).

## Formula
```math
CRSI_t = \\frac{RSI(Close, n_{rsi})_t + RSI(Streak, n_{streak})_t + PercentRank(ROC_1, n_{pctrank})_t}{3}
```

Where:
- `Streak` counts consecutive up/down closes (resets to 0 on equal close).
- `PercentRank` measures the percentage of previous `n_pctrank` ROC values strictly less than the current ROC.

## Interpretation
- Oscillates between 0 and 100.
- Overbought: CRSI >= 90 (potential mean-reversion sell signal).
- Oversold: CRSI <= 10 (potential mean-reversion buy signal).
- Designed for short-term mean-reversion strategies on equities and ETFs.
- Created by: Larry Connors.

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 104.0, 103.5, 105.0, 106.0, 104.5, 107.0]
crsi = ConnorsRSI(prices; n_rsi=3, n_streak=2, n_pctrank=5)
```

## See Also
[`RSI`](@ref), [`ROC`](@ref)
"""
@inline Base.@propagate_inbounds function ConnorsRSI(
    prices::Vector{Float64};
    n_rsi::Int=3,
    n_streak::Int=2,
    n_pctrank::Int=100
)
    len = length(prices)
    if n_rsi < 1
        throw(ArgumentError("n_rsi must be positive"))
    end
    if n_streak < 1
        throw(ArgumentError("n_streak must be positive"))
    end
    if n_pctrank < 1
        throw(ArgumentError("n_pctrank must be positive"))
    end
    min_len = max(n_rsi, n_streak) + 2
    len >= min_len || throw(ArgumentError("prices must have at least max(n_rsi, n_streak) + 2 = $min_len elements"))

    # Component 1: RSI of price
    rsi_price = RSI(prices; n=n_rsi)

    # Component 2: Streak RSI
    streaks = _streak(prices)
    rsi_streak = RSI(streaks; n=n_streak)

    # Component 3: Percentile Rank of ROC(1)
    roc1 = ROC(prices; n=1)
    pct_rank = _percentile_rank(roc1, n_pctrank)

    # Composite: average of three components
    return @. (rsi_price + rsi_streak + pct_rank) / 3.0
end

"""
    _streak(prices::Vector{Float64}) -> Vector{Float64}

Calculate consecutive up/down streak counter for price series.

Returns integer-valued Float64 vector:
- Positive values: consecutive closes above previous close.
- Negative values: consecutive closes below previous close.
- Zero: first bar or equal consecutive closes (reset).

Equal consecutive closes reset the streak to 0 per Connors' original specification.
"""
function _streak(prices::Vector{Float64})
    len = length(prices)
    streaks = zeros(Float64, len)
    # streaks[1] = 0.0 (no previous bar)
    @inbounds for i in 2:len
        if prices[i] > prices[i-1]
            streaks[i] = max(streaks[i-1], 0.0) + 1.0
        elseif prices[i] < prices[i-1]
            streaks[i] = min(streaks[i-1], 0.0) - 1.0
        else  # equal: RESET to 0
            streaks[i] = 0.0
        end
    end
    return streaks
end

"""
    _percentile_rank(data::Vector{Float64}, lookback::Int) -> Vector{Float64}

Calculate rolling percentile rank over a lookback window.

For each bar `i >= 2`, counts the number of values in the previous `lookback` bars
that are strictly less than the current value, divided by the window size, times 100.

- Window: `data[max(1, i-lookback) : i-1]` (does NOT include current value).
- Comparison: strictly less than (`<`), not less-than-or-equal.
- First value (i=1): 0.0 (no previous data).
- Output range: [0.0, 100.0].
"""
function _percentile_rank(data::Vector{Float64}, lookback::Int)
    n = length(data)
    result = zeros(Float64, n)
    @inbounds for i in 2:n
        # Compare data[i] against the window BEFORE i (not including i)
        start = max(1, i - lookback)
        window_before = @view data[start:i-1]
        count = sum(x -> x < data[i], window_before)
        result[i] = count / length(window_before) * 100.0
    end
    return result
end

@prep_siso ConnorsRSI n_rsi=3 n_streak=2 n_pctrank=100
