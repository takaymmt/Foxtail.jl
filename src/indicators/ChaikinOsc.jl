"""
    ChaikinOsc(prices::Matrix{Float64}; fast::Int=3, slow::Int=10) -> Vector{Float64}

Calculate Chaikin Oscillator — a momentum indicator derived from the difference of two EMAs of the ADL.

## Parameters
- `prices`: Price/volume matrix with 4 columns `[High, Low, Close, Volume]` (`Float64`).
- `fast`: Period for the fast EMA of ADL (default: 3). Valid range: `fast >= 1`.
- `slow`: Period for the slow EMA of ADL (default: 10). Valid range: `slow > fast`.

## Returns
Vector of Chaikin Oscillator values (`fast EMA(ADL) - slow EMA(ADL)`).

## Formula
```math
ChaikinOsc_t = EMA_{\\text{fast}}(ADL)_t - EMA_{\\text{slow}}(ADL)_t
```

## Interpretation
- Positive values indicate that the fast EMA of ADL is above the slow EMA (buying momentum).
- Negative values indicate selling momentum.
- Crossover above zero: bullish signal (accumulation accelerating).
- Crossover below zero: bearish signal (distribution accelerating).
- Divergence between the oscillator and price can signal reversals.
- Created by: Marc Chaikin.

## Example
```julia
# prices: [High Low Close Volume]
prices = [105.0 100.0 103.0 1000.0; 106.0 101.0 105.0 1200.0; 104.0 99.0 100.0 900.0]
result = ChaikinOsc(prices; fast=3, slow=10)
```

## See Also
[`ADL`](@ref), [`OBV`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function ChaikinOsc(prices::Matrix{Float64}; fast::Int = 3, slow::Int = 10)
    adl = ADL(prices)
    ema_fast = EMA(adl; n=fast)
    ema_slow = EMA(adl; n=slow)
    return ema_fast - ema_slow
end

@prep_miso ChaikinOsc [High, Low, Close, Volume] fast=3 slow=10
