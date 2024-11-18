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

"""
    Jurik Moving Average (JMA)
    JMA(ts::TSFrame; n::Int=10, field::Symbol=:Close, phase::Float64=0.0) -> TSFrame
    JMA(data::Vector{Float64}; n::Int=7, phase::Float64=0.0) -> Vector{Float64}

A triple adaptive moving average that provides superior noise reduction while maintaining signal responsiveness through dynamic volatility adaptation.

## Basic Concept
- Implements a triple-stage adaptive filtering process
- Combines Exponential Moving Average, Kalman filtering, and unique Jurik adaptive smoothing
- Features dynamic volatility-based adaptation for optimal smoothing
- Includes phase adjustment capability to control lag/smoothing trade-off
- Uses specialized price bands (Jurik Bands) for volatility measurement

## Interpretation / Trading Signals
- Primary use is for trend identification and noise reduction
- Smoother than traditional moving averages while maintaining responsiveness
- Rising JMA indicates uptrend, falling JMA indicates downtrend
- Crossovers between price and JMA can signal trend changes
- Phase adjustment allows optimization for specific trading strategies:
  - Positive phase: More responsive but noisier (better for shorter timeframes)
  - Negative phase: Smoother but laggier (better for longer timeframes)

## Usage Examples
```julia
# Basic usage with default parameters
prices = [100.0, 101.5, 99.8, 102.3, 103.5]
jma = JMA(prices)

# With custom period and phase adjustment
using TSFrames
ts = TSFrame(...)
jma = JMA(ts; n=14, phase=50.0)

# For more aggressive smoothing
jma_smooth = JMA(ts; n=20, phase=-50.0)
```

## Core Formula
The JMA calculation involves three main stages:

```math
\\begin{aligned}
\\text{Stage 1: } & MA_1 = (1-\\alpha)P + \\alpha MA_1[t-1] \\\\
\\text{Stage 2: } & Det_0 = (P-MA_1)(1-\\beta) + \\beta Det_0[t-1] \\\\
                 & MA_2 = MA_1 + PR \\cdot Det_0 \\\\
\\text{Stage 3: } & Det_1 = (MA_2-JMA[t-1])(1-\\alpha)^2 + \\alpha^2 Det_1[t-1] \\\\
                 & JMA = JMA[t-1] + Det_1
\\end{aligned}
```

Key components:
- α = β^(rVolty^pow1) : Dynamic smoothing factor
- β = 0.45(period-1)/(0.45(period-1)+2) : Base smoothing factor
- PR = Phase/100 + 1.5 : Phase ratio (bounded [0.5, 2.5])
- rVolty : Relative volatility based on Jurik Bands

## Parameters and Arguments
- `ts::TSFrame`: Input time series data
  - Must contain the specified price field
  - No missing values allowed

- `data::Vector{Float64}`: Alternative input as float vector
  - Must contain finite values
  - Length must be > 1

- `period::Int`: (Default: 10)
  - Controls the base smoothing period
  - Valid range: > 1
  - Smaller values (5-15): More responsive, suitable for short-term trading
  - Larger values (20-50): Smoother, better for longer-term trends
  - Impact: Affects base smoothing factor β

- `field::Symbol`: (Default: :Close)
  - Specifies which price field to use from TSFrame
  - Common values: :Close, :Open, :High, :Low
  - Must exist in input TSFrame

- `phase::Float64`: (Default: 0.0)
  - Controls the lag/smoothing trade-off
  - Valid range: [-100.0, 100.0]
  - Positive values: Reduce lag but increase noise
  - Negative values: Increase smoothing but add lag
  - Impact: Modifies the Kalman filter phase ratio

## Returns
- `Vector{Float64}`: When input is Vector{Float64}
  - Same length as input
  - Contains the JMA values
  - First value equals first input value

- `TSFrame`: When input is TSFrame
  - Contains original data plus new JMA column
  - JMA column named according to parameters

## Implementation Details
Algorithm overview:
1. Parameter initialization
   - Calculate base smoothing factors
   - Initialize volatility tracking
2. Jurik Bands calculation for volatility measurement
3. Dynamic factor computation based on relative volatility
4. Triple smoothing process application

References:
- Original algorithm by Mark Jurik
  - http://jurikres.com/catalog1/ms_ama.htm
- https://c.mql5.com/forextsd/forum/164/jurik_1.pdf
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
        # idx = mod1(i, 10)
        # v_sum += (volty - volty_history[idx]) / 10
        # volty_history[idx] = volty

        idx = mod1(i, 65)
        old_value = volty_history[idx]
        volty_history[idx] = volty

        # Calculate average volatility (simplified from original 65-period average)
        # avg_volty = i < 30 ? volty : v_sum

        if i <= 65
            v_sum += volty
            avg_volty = v_sum / i
        else
            v_sum += (volty - old_value)
            avg_volty = v_sum / 65
        end

        # Calculate relative volatility with bounds
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