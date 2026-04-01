"""
    Ichimoku(prices::Matrix{Float64}; tenkan::Int=9, kijun::Int=26, senkou_b::Int=52, displacement::Int=26) -> Matrix{Float64}

Calculate Ichimoku Cloud (Ichimoku Kinko Hyo) — a comprehensive trend-following indicator system.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `tenkan`: Lookback period for Tenkan-sen / Conversion Line (default: 9). Valid range: `tenkan >= 1`.
- `kijun`: Lookback period for Kijun-sen / Base Line (default: 26). Valid range: `kijun >= 1`.
- `senkou_b`: Lookback period for Senkou Span B / Leading Span B (default: 52). Valid range: `senkou_b >= 1`.
- `displacement`: Number of periods to project Senkou Spans forward and Chikou Span backward (default: 26). Valid range: `displacement >= 1`.

## Returns
Matrix of size `(N + displacement, 5)`:
- Column 1: Tenkan-sen (Conversion Line) — midpoint of highest high and lowest low over `tenkan` periods
- Column 2: Kijun-sen (Base Line) — midpoint of highest high and lowest low over `kijun` periods
- Column 3: Senkou Span A (Leading Span A) — average of Tenkan and Kijun, projected `displacement` periods forward
- Column 4: Senkou Span B (Leading Span B) — midpoint of highest high and lowest low over `senkou_b` periods, projected `displacement` periods forward
- Column 5: Chikou Span (Lagging Span) — Close shifted `displacement` periods into the past

## Formula
```math
\\text{Tenkan} = \\frac{HH_{tenkan} + LL_{tenkan}}{2}, \\quad
\\text{Kijun} = \\frac{HH_{kijun} + LL_{kijun}}{2}
```
```math
\\text{Senkou A}_{t+d} = \\frac{\\text{Tenkan}_t + \\text{Kijun}_t}{2}, \\quad
\\text{Senkou B}_{t+d} = \\frac{HH_{senkou\\_b} + LL_{senkou\\_b}}{2}
```
```math
\\text{Chikou}_{t-d} = C_t
```

Where `HH_n` = highest high, `LL_n` = lowest low over `n` periods, `d` = displacement, `C` = Close.

## Interpretation
- Price above the cloud: bullish trend.
- Price below the cloud: bearish trend.
- Tenkan crossing above Kijun: bullish signal (TK Cross).
- Senkou A above Senkou B: bullish cloud (green).
- Chikou above past price: confirms bullish trend.
- Created by: Goichi Hosoda (1960s).

## Example
```julia
# prices: [High Low Close]
prices = [105.0 100.0 103.0; 106.0 101.0 104.0; 107.0 102.0 105.0]
result = Ichimoku(prices; tenkan=2, kijun=2, senkou_b=2, displacement=2)
# result has size (5, 5): 3 input rows + 2 displacement rows
```

## See Also
[`Stoch`](@ref), [`DMI`](@ref), [`Supertrend`](@ref)
"""
@inline Base.@propagate_inbounds function Ichimoku(prices::Matrix{Float64};
    tenkan::Int=9, kijun::Int=26, senkou_b::Int=52, displacement::Int=26)

    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if tenkan < 1 || kijun < 1 || senkou_b < 1
        throw(ArgumentError("periods must be positive"))
    end

    if displacement < 1
        throw(ArgumentError("displacement must be positive"))
    end

    N = size(prices, 1)
    nout = N + displacement
    result = fill(NaN, nout, 5)

    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # MinMaxQueue capacity must be at least as large as the largest window + 1
    max_window = max(tenkan, kijun, senkou_b)
    mmq_t = MinMaxQueue{Float64}(max_window + 1)
    mmq_k = MinMaxQueue{Float64}(max_window + 1)
    mmq_s = MinMaxQueue{Float64}(max_window + 1)

    @inbounds for i in 1:N
        h = highs[i]
        l = lows[i]

        update!(mmq_t, h, l, i)
        update!(mmq_k, h, l, i)
        update!(mmq_s, h, l, i)

        # Remove elements outside each window
        remove_old!(mmq_t, i - tenkan)
        remove_old!(mmq_k, i - kijun)
        remove_old!(mmq_s, i - senkou_b)

        # Tenkan-sen
        tenkan_val = (get_max(mmq_t) + get_min(mmq_t)) / 2.0
        result[i, 1] = tenkan_val

        # Kijun-sen
        kijun_val = (get_max(mmq_k) + get_min(mmq_k)) / 2.0
        result[i, 2] = kijun_val

        # Senkou Span A: projected `displacement` periods forward
        result[i + displacement, 3] = (tenkan_val + kijun_val) / 2.0

        # Senkou Span B: projected `displacement` periods forward
        result[i + displacement, 4] = (get_max(mmq_s) + get_min(mmq_s)) / 2.0
    end

    # Chikou Span: Close[i] stored at position [i - displacement]
    @inbounds for i in (displacement + 1):N
        result[i - displacement, 5] = closes[i]
    end

    return result
end

"""
    Ichimoku(ts::TSFrame; tenkan::Int=9, kijun::Int=26, senkou_b::Int=52, displacement::Int=26, fields::Vector{Symbol}=[:High, :Low, :Close]) -> TSFrame

Calculate Ichimoku Cloud on a TSFrame. The output TSFrame has `nrow(ts) + displacement` rows,
with future dates inferred from the median time step of the input index.

## Returns
TSFrame with columns:
- `Ichimoku_Tenkan`: Tenkan-sen (Conversion Line)
- `Ichimoku_Kijun`: Kijun-sen (Base Line)
- `Ichimoku_SenkouA`: Senkou Span A (Leading Span A)
- `Ichimoku_SenkouB`: Senkou Span B (Leading Span B)
- `Ichimoku_Chikou`: Chikou Span (Lagging Span)
"""
function Ichimoku(ts::TSFrame;
    tenkan::Int=9, kijun::Int=26, senkou_b::Int=52, displacement::Int=26,
    fields::Vector{Symbol}=[:High, :Low, :Close])

    prices = ts[:, fields] |> Matrix
    result = Ichimoku(prices; tenkan=tenkan, kijun=kijun, senkou_b=senkou_b, displacement=displacement)

    # Build extended index with future dates
    idx = index(ts)
    if length(idx) >= 2
        # Use median step (robust to gaps)
        steps = [idx[i] - idx[i-1] for i in 2:length(idx)]
        sorted_steps = sort(steps)
        med_step = sorted_steps[div(length(sorted_steps) + 1, 2)]
        future_idx = [idx[end] + med_step * k for k in 1:displacement]
        full_idx = vcat(idx, future_idx)
    else
        # Fallback: single-element index, use unit step (Day(1) for Date, etc.)
        unit_step = oneunit(idx[end] - idx[end])
        future_idx = [idx[end] + unit_step * k for k in 1:displacement]
        full_idx = vcat(idx, future_idx)
    end

    colnames = [:Ichimoku_Tenkan, :Ichimoku_Kijun, :Ichimoku_SenkouA, :Ichimoku_SenkouB, :Ichimoku_Chikou]
    return TSFrame(result, full_idx, colnames=colnames)
end

export Ichimoku
