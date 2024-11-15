"""
    JMA(ts::TSFrame, period::Int=10; field::Symbol=:Close, phase::Float64=0.0)

Calculate Jurik Moving Average (JMA) for time series data based on Jurik's original algorithm.

JMA implements a triple adaptive filter that features:
- Superior noise reduction with dynamic volatility adaptation
- Precise trend following using Kalman filter principles
- Phase-adjusted smoothing for lag control
- Jurik's unique adaptive filtering mechanism

The calculation process consists of three main stages:

1. Parameter Initialization:
   - β = 0.45(period-1)/(0.45(period-1)+2)
   - len1 = log(√period)/log(2) + 2
   - pow1 = max(0.5, len1 - 2)
   - phase_ratio = clamp(phase/100 + 1.5, 0.5, 2.5)

2. Volatility Calculation:
   a) Jurik Bands Computation:
      - Calculate distances: del1 = price - upper_band, del2 = price - lower_band
      - Update bands with volatility factor kv = β^√pow1
      - Determine volatility as max(|del1|, |del2|)
   b) Relative Volatility:
      - Track 10-period moving sum of volatility
      - Calculate ratio = current_volatility/average_volatility
      - Apply bounds: ratio ∈ [1.0, len1^(1/pow1)]

3. Triple Smoothing Process:
   a) Adaptive EMA (Stage 1):
      - Calculate dynamic α = β^(r_volty^pow1)
      - MA1 = (1-α)price + α×MA1_prev
   b) Kalman Filter (Stage 2):
      - Det0 = (price-MA1)(1-β) + β×Det0_prev
      - MA2 = MA1 + phase_ratio×Det0
   c) Jurik Adaptive Filter (Stage 3):
      - Det1 = (MA2-JMA_prev)(1-α)² + α²×Det1_prev
      - JMA = JMA_prev + Det1

Parameters:
- ts: Input time series data
- period: Moving average length (default: 10)
- field: Price field to use (default: :Close)
- phase: Phase adjustment between -100 and 100 (default: 0.0)
  - Positive values decrease lag but may reduce smoothing
  - Negative values increase smoothing but may increase lag

Returns:
    TSFrame with JMA values

Implementation Notes:
- Uses Jurik's original three-stage filtering process
- Incorporates dynamic volatility adaptation
- Implements complete Jurik Bands calculation
- Features phase-adjusted Kalman filtering

References:
Based on Mark Jurik's original algorithm description and research.
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
    volty_history = zeros(Float64, 10)  # Store last 10 volatility values
    volty_idx = 1

    # First point initialization
    jma[1] = data[1]

    @inbounds for i in 2:sz
        # Calculate Jurik Bands
        del1 = data[i] - upper_band
        del2 = data[i] - lower_band

        # Update bands
        kv = beta ^ sqrt(pow1)
        if del1 > 0
            upper_band = data[i]
        else
            upper_band = data[i] - kv * del1
        end

        if del2 < 0
            lower_band = data[i]
        else
            lower_band = data[i] - kv * del2
        end

        # Calculate volatility
        volty = if abs(del1) == abs(del2)
            0.0
        else
            max(abs(del1), abs(del2))
        end

        # Update volatility history and sum
        v_sum = v_sum - volty_history[volty_idx] / 10 + volty / 10
        volty_history[volty_idx] = volty
        volty_idx = volty_idx == 10 ? 1 : volty_idx + 1

        # Calculate average volatility (simplified from original 65-period average)
        avg_volty = i < 30 ? volty : v_sum

        # Calculate relative volatility with bounds
        r_volty = if avg_volty > 0
            volty / avg_volty
        else
            1.0
        end
        r_volty = clamp(r_volty, 1.0, len1^(1/pow1))

        # Calculate dynamic alpha
        pow = r_volty ^ pow1
        alpha = beta ^ pow

        # Stage 1: Preliminary smoothing by adaptive EMA
        ma1 = (1.0 - alpha) * data[i] + alpha * ma1

        # Stage 2: Secondary smoothing by Kalman filter
        det0 = (data[i] - ma1) * (1.0 - beta) + beta * det0
        ma2 = ma1 + phase_ratio * det0

        # Stage 3: Final Jurik adaptive filter
        det1 = (ma2 - jma[i-1]) * (1.0 - alpha)^2 + alpha^2 * det1
        jma[i] = jma[i-1] + det1
    end

    return jma
end

@prep_siso JMA n=7 (phase=0.0)