"""
    TEMA(prices::Vector{T}; n::Int=10) where T

Calculate Triple Exponential Moving Average (TEMA) for a given price series.

# Arguments
- `prices::Vector{T}`: Input price vector
- `n::Int=10`: Period length for EMA calculations (default: 10)

# Returns
- `Vector{T}`: TEMA values calculated for each point in the input series

# Details
TEMA is calculated using three EMAs and a combination formula to reduce lag while maintaining smoothness:

TEMA = (EMA1 - EMA2) * 3 + EMA3

where:
- EMA1 = EMA(price)
- EMA2 = EMA(EMA1)
- EMA3 = EMA(EMA2)

# Characteristics
- Provides superior noise reduction through triple smoothing
- More responsive to price changes than EMA and DEMA
- Effectively reduces lag in trending markets
- Better handles short-term price fluctuations

See also: [`EMA`](@ref), [`DEMA`](@ref)
"""
@inline Base.@propagate_inbounds function TEMA(prices::Vector{T}; n::Int=10) where T
    EMA1 = EMA(prices; n=n)
	EMA2 = EMA(EMA1; n=n)
	EMA3 = EMA(EMA2; n=n)
	return (EMA1 - EMA2) * 3 + EMA3
end

@prep_siso TEMA n=10