"""
    JMA(data::Vector{Float64}; n::Int=7, phase::Float64=0.0) -> Vector{Float64}

Calculate Jurik Moving Average (JMA) — a triple adaptive filter with superior noise reduction and minimal lag.

## Parameters
- `data`: Input price vector (`Float64`).
- `n`: Base smoothing period (default: 7). Valid range: `n > 1`.
  Smaller values (5-15) are more responsive; larger values (20-50) are smoother.
- `phase`: Lag/smoothing trade-off control (default: 0.0). Valid range: `-100.0` to `100.0`.
  Positive values reduce lag but increase noise; negative values increase smoothing.

## Returns
Vector of JMA values. The first value equals the first input price.

## Formula
```math
\\begin{aligned}
\\text{Stage 1 (Adaptive EMA): } & MA_1 = (1-\\alpha) \\cdot P_t + \\alpha \\cdot MA_{1,t-1} \\\\
\\text{Stage 2 (Kalman filter): } & Det_0 = (P_t - MA_1)(1-\\beta) + \\beta \\cdot Det_{0,t-1} \\\\
                                  & MA_2 = MA_1 + PR \\cdot Det_0 \\\\
\\text{Stage 3 (Jurik filter): }  & Det_1 = (MA_2 - JMA_{t-1})(1-\\alpha)^2 + \\alpha^2 \\cdot Det_{1,t-1} \\\\
                                  & JMA_t = JMA_{t-1} + Det_1
\\end{aligned}
```

Key components:
- `alpha = beta^(rVolty^pow1)` — dynamic smoothing factor based on relative volatility
- `beta = 0.45(n-1) / (0.45(n-1) + 2)` — base smoothing factor
- `PR = clamp(phase/100 + 1.5, 0.5, 2.5)` — phase ratio
- `rVolty` — relative volatility measured via Jurik Bands

## Interpretation
- Combines adaptive EMA, Kalman filtering, and Jurik's proprietary adaptive smoothing.
- Smoother than traditional MAs while maintaining responsiveness through dynamic volatility adaptation.
- Rising JMA indicates uptrend; falling JMA indicates downtrend.
- Phase adjustment allows tuning for specific trading timeframes.
- Created by: Mark Jurik.

## Example
```julia
prices = [100.0, 101.5, 99.8, 102.3, 103.5, 104.2, 103.8]
result = JMA(prices; n=7, phase=0.0)
```

## See Also
[`EMA`](@ref), [`KAMA`](@ref), [`ALMA`](@ref)
"""

@inline Base.@propagate_inbounds function JMA(data::Vector{Float64}; n::Int=7, phase::Float64=0.0)
    period = n
    sz = size(data, 1)
    jma = zeros(Float64, sz)

    # Initialize core parameters
    beta = 0.45 * (period - 1) / (0.45 * (period - 1) + 2)

    # Initialize length-dependent factors
    len1 = log(sqrt(period)) / log(2.0) + 2
    len1 = max(0.0, len1)
    pow1 = len1 - 2
    pow1 = max(0.5, pow1)
    kv = beta ^ sqrt(pow1)
    len_1_pow = len1^(1/pow1)

    # Phase ratio calculation with bounds
    phase_ratio = clamp(phase / 100 + 1.5, 0.5, 2.5)

    # Initialize smoothing variables
    ma1 = data[1]
    det0 = 0.0
    det1 = 0.0

    # Volatility tracking variables
    upper_band = data[1]
    lower_band = data[1]
    volty = 0.0
    avg_volty = 0.0
    v_sum = 0.0
    volty_history = zeros(Float64, 65)  # Store last 65 volatility values

    # First point initialization
    jma[1] = data[1]

    @inbounds for i in 2:sz
        # Calculate Jurik Bands
        del1 = data[i] - upper_band
        del2 = data[i] - lower_band

        upper_band = ifelse(del1 > 0, data[i], data[i] - kv * del1)
        lower_band = ifelse(del2 < 0, data[i], data[i] - kv * del2)

        # Calculate volatility
        volty = ifelse(abs(del1) == abs(del2), 0.0, max(abs(del1), abs(del2)))

        # Update volatility history and sum
        idx = mod1(i, 65)
        old_value = volty_history[idx]
        volty_history[idx] = volty

        # Calculate average volatility (Jurik uses 65-period average)
        if i <= 65
            v_sum += volty
            avg_volty = v_sum / i
        else
            v_sum += (volty - old_value)
            avg_volty = v_sum / 65
        end

        # Calculate relative volatility and clamp between 1.0 and len_1_pow
        r_volty = avg_volty > 0 ? volty / avg_volty : 1.0
        r_volty = clamp(r_volty, 1.0, len_1_pow)

        # Calculate dynamic alpha
        pow = r_volty ^ pow1
        alpha = beta ^ pow

        # Stage 1: Preliminary smoothing by adaptive EMA
        ma1 = muladd(1.0 - alpha, data[i], alpha * ma1)

        # Stage 2: Secondary smoothing by Kalman filter
        det0 = muladd(1.0 - beta, data[i] - ma1, beta * det0)
        ma2 = muladd(phase_ratio, det0, ma1)

        # Stage 3: Final Jurik adaptive filter
        det1 = muladd((1.0 - alpha)^2, ma2 - jma[i-1], alpha^2 * det1)
        jma[i] = jma[i-1] + det1

    end

    return jma
end

@prep_siso JMA n=7 (phase=0.0)