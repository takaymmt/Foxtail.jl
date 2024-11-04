"""
    TEMA(data::Vector{T}, period::Int) where T

Calculate Triple Exponential Moving Average (TEMA) for a given time series data.

Triple Exponential Moving Average, also developed by Patrick Mulloy as an extension
of DEMA, further reduces lag in trending markets while maintaining smoothness. It
uses a combination of three EMAs to provide even more responsive signals than DEMA,
while effectively filtering out price noise.

# Arguments
- `data::Vector{T}`: Input price vector of any numeric type
- `period::Int`: Length of the initialization period for EMA calculations

# Returns
- `Vector{T}`: Vector containing TEMA values for each point in the input data

# Implementation Details
The function performs a four-step calculation process:
1. Calculates initial EMA with the specified period
2. Calculates second EMA of the first EMA using the same period
3. Calculates third EMA of the second EMA using the same period
4. Computes final TEMA using the formula:
   TEMA = (EMA1 - EMA2) * 3 + EMA3
   where EMA1 = EMA(price), EMA2 = EMA(EMA1), EMA3 = EMA(EMA2)

Key characteristics:
- Triple smoothing provides superior noise reduction
- Combination formula helps eliminate lag while preserving trend signals
- More responsive to price changes than both EMA and DEMA
- Particularly effective in trending markets
- Better handles short-term price fluctuations

# Example
```julia
prices = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
period = 4
result = TEMA(prices, period)  # Returns highly responsive trend values
```

See also: [`EMA`](@ref), [`DEMA`](@ref)
"""
@inline Base.@propagate_inbounds function TEMA(prices::Vector{T}, period::Int) where T
    EMA1 = EMA(prices, period)
	EMA2 = EMA(EMA1, period)
	EMA3 = EMA(EMA2, period)
	return (EMA1 - EMA2) * 3 + EMA3
end

@prep_SISO TEMA