using Dates

"""
    AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1) -> Vector{Float64}

Calculate Anchored Volume Weighted Average Price (Anchored VWAP) -- a VWAP that begins cumulation from a user-specified anchor bar.

## Parameters
- `data`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]` (`Float64`).
- `anchor`: 1-based row index from which cumulative calculation begins (default: 1). Valid range: `1 <= anchor <= size(data, 1)`.

## Returns
Vector of Anchored VWAP values. Rows before `anchor` are `NaN`; from `anchor` onward each value is the cumulative volume-weighted average of the Typical Price starting at the anchor bar.

## Formula
```math
TP_t = \\frac{H_t + L_t + C_t}{3}, \\quad
AVWAP_t = \\frac{\\sum_{i=\\text{anchor}}^{t} TP_i \\cdot V_i}{\\sum_{i=\\text{anchor}}^{t} V_i}
```

## Interpretation
- Anchored VWAP measures the true average price paid since a specific event (e.g., earnings, breakout, IPO).
- Price above Anchored VWAP from the anchor date suggests net buyers are profitable; below suggests net sellers are profitable.
- Useful for identifying support/resistance from significant market events.
- When `anchor=1`, the result is identical to `VWAP(data)`.

## Example
```julia
# data: [High Low Close Volume]
data = [105.0 100.0 103.0 1000.0; 106.0 101.0 104.0 1200.0; 104.0 99.0 100.0 800.0]
result = AnchoredVWAP(data; anchor=2)  # VWAP starting from row 2
```

## See Also
[`VWAP`](@ref), [`OBV`](@ref), [`ADL`](@ref)
"""
@inline Base.@propagate_inbounds function AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1)
    if size(data, 1) == 0
        throw(ArgumentError("data matrix must not be empty"))
    end
    if size(data, 2) != 4
        throw(ArgumentError("data matrix must have 4 columns [High Low Close Volume]"))
    end
    if anchor < 1 || anchor > size(data, 1)
        throw(ArgumentError("anchor must be between 1 and the number of rows (got $anchor for $(size(data, 1)) rows)"))
    end

    n = size(data, 1)
    results = fill(NaN, n)

    highs   = @view data[:, 1]
    lows    = @view data[:, 2]
    closes  = @view data[:, 3]
    volumes = @view data[:, 4]

    cum_tpv = 0.0
    cum_v   = 0.0

    @inbounds for i in anchor:n
        tp = (highs[i] + lows[i] + closes[i]) / 3.0
        cum_tpv += tp * volumes[i]
        cum_v   += volumes[i]
        results[i] = cum_v == 0.0 ? 0.0 : cum_tpv / cum_v
    end

    return results
end

"""
    _anchored_vwap_resolve(ts::TSFrame, anchor::Union{Int, Dates.TimeType}) -> Int

Resolve an anchor argument to a 1-based row index. If `anchor` is a `TimeType` (Date, DateTime, etc.),
find the corresponding row in the TSFrame index. Throws `ArgumentError` if the date is not found or the
integer index is out of range.
"""
function _anchored_vwap_resolve(ts::TSFrame, anchor::Union{Int, Dates.TimeType})::Int
    if anchor isa Dates.TimeType
        idx = findfirst(==(anchor), index(ts))
        if idx === nothing
            throw(ArgumentError("anchor date not found in TSFrame index"))
        end
        return idx
    else
        n = nrow(ts)
        if anchor < 1 || anchor > n
            throw(ArgumentError("anchor must be between 1 and the number of rows (got $anchor for $n rows)"))
        end
        return anchor
    end
end

"""
    AnchoredVWAP(ts::TSFrame; anchor, fields::Vector{Symbol}=[:High, :Low, :Close, :Volume]) -> TSFrame

Calculate Anchored VWAP on a TSFrame. The `anchor` parameter is **required** and specifies where
cumulative calculation begins.

## Parameters
- `ts`: Input TSFrame with OHLCV-like columns.
- `anchor::Int`: Row index (1-based) at which to anchor the VWAP calculation.
- `anchor::TimeType`: Date/DateTime value; resolved to the matching row index in the TSFrame.
- `fields`: Column names to use as `[High, Low, Close, Volume]` (default: `[:High, :Low, :Close, :Volume]`).

## Returns
TSFrame with a single column `:AnchoredVWAP`.
"""
function AnchoredVWAP(ts::TSFrame; anchor, fields::Vector{Symbol}=[:High, :Low, :Close, :Volume])
    anchor_idx = _anchored_vwap_resolve(ts, anchor)
    prices = ts[:, fields] |> Matrix
    results = AnchoredVWAP(prices; anchor=anchor_idx)
    return TSFrame(results, index(ts), colnames=[:AnchoredVWAP])
end

export AnchoredVWAP
