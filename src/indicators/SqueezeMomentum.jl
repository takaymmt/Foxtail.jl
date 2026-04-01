"""
    SqueezeMomentum(prices::Matrix{Float64}; n::Int=20, bb_mult::Float64=2.0, kc_mult::Float64=1.5) -> Matrix{Float64}

Calculate TTM Squeeze Momentum — a volatility and momentum indicator combining
Bollinger Bands, Keltner Channels, and linear regression momentum.

## Parameters
- `prices`: Price matrix with 3 columns `[High, Low, Close]` (`Float64`).
- `n`: Lookback period for BB, KC, rolling high/low, EMA, and linear regression (default: 20).
  Valid range: `n >= 2`.
- `bb_mult`: Bollinger Band standard deviation multiplier (default: 2.0). Valid range: `> 0`.
- `kc_mult`: Keltner Channel ATR multiplier (default: 1.5). Valid range: `> 0`.

## Returns
Matrix of size `(rows, 2)`:
- Column 1: Histogram — linear regression of momentum values over the last `n` bars.
  Positive values indicate upward momentum; negative values indicate downward momentum.
- Column 2: Squeeze — `1.0` when squeeze is ON (BB inside KC), `0.0` when squeeze is OFF.

## Algorithm
1. Compute Bollinger Bands on Close prices (period `n`, multiplier `bb_mult`).
2. Compute Keltner Channel on HLC (period `n`, multiplier `kc_mult`).
3. Squeeze detection: squeeze is ON when BB upper < KC upper AND BB lower > KC lower.
4. Momentum calculation:
   - Rolling highest high and lowest low over `n` bars.
   - `midpoint = (highest_high + lowest_low) / 2`
   - `val = close - (midpoint + EMA(close, n)) / 2`
   - Apply linear regression over last `n` bars of `val`; the fitted value at the last point
     is the histogram value.

## Interpretation
- Squeeze ON (1.0): low volatility, potential breakout imminent.
- Squeeze OFF (0.0): volatility expansion, breakout in progress.
- Positive histogram: upward momentum.
- Negative histogram: downward momentum.
- Histogram color change (increasing/decreasing) signals momentum shifts.
- Created by: John Carter (TTM Squeeze).

## Example
```julia
# prices: [High Low Close]
prices = rand(50, 3) .+ 100.0
result = SqueezeMomentum(prices; n=20, bb_mult=2.0, kc_mult=1.5)
# result[:,1] = Histogram, result[:,2] = Squeeze
```

## See Also
[`BB`](@ref), [`KeltnerChannel`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function SqueezeMomentum(prices::Matrix{Float64}; n::Int=20, bb_mult::Float64=2.0, kc_mult::Float64=1.5)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if n < 2
        throw(ArgumentError("period n must be >= 2"))
    end

    len = size(prices, 1)
    highs  = @view prices[:, 1]
    lows   = @view prices[:, 2]
    closes = Vector(prices[:, 3])

    # --- Squeeze detection ---
    # Bollinger Bands on Close
    bb = BB(closes; n=n, num_std=bb_mult)
    bb_upper = @view bb[:, 2]
    bb_lower = @view bb[:, 3]

    # Keltner Channel on HLC
    kc = KeltnerChannel(prices; n=n, mult=kc_mult)
    kc_upper = @view kc[:, 2]
    kc_lower = @view kc[:, 3]

    # Squeeze: ON when BB is inside KC
    squeeze = zeros(len)
    @inbounds for i in 1:len
        if bb_upper[i] < kc_upper[i] && bb_lower[i] > kc_lower[i]
            squeeze[i] = 1.0
        else
            squeeze[i] = 0.0
        end
    end

    # --- Momentum calculation ---
    # EMA of Close
    ema_close = EMA(closes; n=n)

    # Rolling highest high / lowest low using MinMaxQueue
    val = zeros(len)
    mmq = MinMaxQueue{Float64}(n + 1)

    @inbounds for i in 1:len
        update!(mmq, highs[i], lows[i], i)
        if i > n
            remove_old!(mmq, i - n)
        end
        rolling_max_h = get_max(mmq)
        rolling_min_l = get_min(mmq)
        midpoint = (rolling_max_h + rolling_min_l) / 2.0
        val[i] = closes[i] - (midpoint + ema_close[i]) / 2.0
    end

    # Apply linear regression over rolling window of n bars
    histogram = zeros(len)
    cb = CircBuff{Float64}(n)

    @inbounds for i in 1:len
        push!(cb, val[i])
        histogram[i] = _linreg_last(cb)
    end

    return hcat(histogram, squeeze)
end

"""
    _linreg_last(cb::CircBuff{Float64}) -> Float64

Compute the linear regression fitted value at the last point of the data in the
circular buffer. Uses OLS with x = [1, 2, ..., n].

Returns the y-value of the regression line evaluated at x = n (the most recent point).
"""
@inline function _linreg_last(cb::CircBuff{Float64})::Float64
    n = length(cb)
    n == 0 && return 0.0
    n == 1 && return cb[1]

    x_bar = (n + 1) / 2.0
    y_sum = 0.0
    @inbounds for i in 1:n
        y_sum += cb[i]
    end
    y_bar = y_sum / n

    num = 0.0
    den = 0.0
    @inbounds for i in 1:n
        dx = Float64(i) - x_bar
        num += dx * (cb[i] - y_bar)
        den += dx * dx
    end

    if den ≈ 0.0
        return y_bar
    end

    slope = num / den
    return y_bar + slope * (Float64(n) - x_bar)
end

@prep_mimo SqueezeMomentum [High, Low, Close] [Histogram, Squeeze] n=20 bb_mult=2.0 kc_mult=1.5
