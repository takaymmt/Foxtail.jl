"""
    Bollinger Bands
    BB(prices::Vector{T}, period::Int = 14; num_std::Float64 = 2.0, ma_type::Symbol = :SMA) -> Matrix{T}

A technical analysis tool that creates a band of three lines which are plotted in relation to a security's price.

## Basic Concept
- Consists of a middle band (moving average) and two outer bands
- Outer bands are placed above and below the middle band at a distance determined by standard deviation
- Adapts to market volatility by widening during volatile periods and narrowing during stable periods
- Developed by John Bollinger in the 1980s

## Interpretation / Trading Signals
- Price touching or breaking outer bands may indicate overbought/oversold conditions
- Band width indicates market volatility
- Price movement from one band to another may signal potential trend reversals
- Most effective in ranging markets; less reliable in strong trends
- Can be combined with other indicators for confirmation

## Usage Examples
```julia
# Basic usage with default parameters
prices = [100.0, 101.0, 99.0, 102.0, 98.0]
bb = BB(prices)

# Custom settings with EMA and different standard deviation
bb = BB(prices; n=20, num_std=2.5, ma_type=:EMA)
```

## Core Formula
```math
\\begin{align*}
Middle Band &= MA(price, period) \\\\
Upper Band &= Middle Band + (num\\_std × σ) \\\\
Lower Band &= Middle Band - (num\\_std × σ) \\\\
σ &= \\sqrt{\\frac{\\sum_{i=1}^{n} (x_i - \\mu)^2}{n}}
\\end{align*}
```

Key components:
- MA: Moving Average (SMA, EMA, or SMMA)
- σ: Standard deviation of price over the period
- num_std: Number of standard deviations for the bands

## Parameters and Arguments
- `prices::Vector{T}`: Vector of price data
  - Must be non-empty
  - Typically closing prices

- `period::Int`: (Default: 14)
  - Controls the lookback period for calculations
  - Valid range: > 0
  - Common values: 20 (standard), 10 (short-term), 50 (long-term)
  - Impact: Larger values create smoother bands but increase lag

- `num_std::Float64`: (Default: 2.0)
  - Number of standard deviations for the bands
  - Valid range: > 0
  - Common values: 2.0 (standard), 1.0 (tight), 3.0 (wide)
  - Impact: Larger values create wider bands

- `ma_type::Symbol`: (Default: :SMA)
  - Type of moving average to use
  - Valid values: :SMA, :EMA, :SMMA
  - Impact: Affects responsiveness and smoothness of bands

## Returns
- `Matrix{T}`: A matrix with dimensions (n,3) where n is length of input
  - Column 1: Middle band (MA)
  - Column 2: Upper band
  - Column 3: Lower band
  - Same type as input prices

## Implementation Details
Algorithm overview:
- Uses optimized moving average and standard deviation calculations
- Leverages circular buffer for efficient memory management
- Optimizes standard deviation using: Var(X) = E(X²) - (E(X))²
- Handles floating-point errors for non-negative variance
"""
@inline Base.@propagate_inbounds function BB(prices::Vector{T}; n::Int = 14, num_std::Float64 = 2.0, ma_type::Symbol = :SMA) where T
    period = n
    results = zeros(T, (length(prices),3))
    masd = if ma_type == :SMMA
        SMMA_stats(prices; n=period)
    elseif ma_type == :EMA
        EMA_stats(prices; n=period)
    else
        SMA_stats(prices; n=period)
    end
    @inbounds for i in 1:length(prices)
        results[i,1] = masd[i,1]
        results[i,2] = masd[i,1] + num_std * masd[i,2]
        results[i,3] = masd[i,1] - num_std * masd[i,2]
    end
    return results
end

@prep_simo BB [Center, Upper, Lower] n=14 num_std=2.0 ma_type=SMA