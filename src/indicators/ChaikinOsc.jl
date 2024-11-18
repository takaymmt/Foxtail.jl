"""
    ChaikinOsc(prices::Matrix{Float64}; fast::Int = 3, slow::Int = 10)

Calculate the Chaikin Oscillator, a momentum indicator derived from the Accumulation/Distribution Line (ADL).

# Arguments
- `prices::Matrix{Float64}`: Price matrix with columns [High, Low, Close, Volume]
- `fast::Int = 3`: Period for the fast EMA calculation
- `slow::Int = 10`: Period for the slow EMA calculation

# Returns
- Vector{Float64}: Chaikin Oscillator values

# Details
The Chaikin Oscillator is calculated by subtracting a slower EMA from a faster EMA of the ADL.
Formula: ChaikinOsc = EMA(fast) of ADL - EMA(slow) of ADL

# Example
```julia
chaikin = ChaikinOsc(prices)
chaikin = ChaikinOsc(prices; fast=5, slow=15)
```

See also: [`ADL`](@ref), [`EMA`](@ref)
"""
@inline Base.@propagate_inbounds function ChaikinOsc(prices::Matrix{Float64}; fast::Int = 3, slow::Int = 10)
    adl = ADL(prices)
    ema_fast = EMA(adl; n=fast)
    ema_slow = EMA(adl; n=slow)
    return ema_fast - ema_slow
end

@prep_miso ChaikinOsc [High, Low, Close, Volume] fast=3 slow=10
