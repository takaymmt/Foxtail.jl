"""
    ADL(prices::Matrix{T}) where T <: AbstractFloat

Calculate the Accumulation/Distribution Line (ADL) technical indicator.

The ADL is a volume-based indicator that measures the cumulative flow of money into and out of a security.
It uses price and volume data to determine whether a security is being accumulated (bought) or distributed (sold).

# Arguments
- `prices::Matrix{T}`: A matrix of price data where:
  - Column 1: High prices
  - Column 2: Low prices
  - Column 3: Close prices
  - Column 4: Volume data

# Returns
- `Vector{T}`: The ADL values for each period

# Formula
1. Money Flow Multiplier (MFM) = ((Close - Low) - (High - Close)) / (High - Low)
   Simplified as: (2 * Close - Low - High) / (High - Low)
2. Money Flow Volume (MFV) = MFM * Volume
3. ADL = Previous ADL + Current MFV

# Notes
- Returns 0.0 for periods where (High - Low) = 0 or Volume = 0 to avoid division by zero
- The first period's ADL starts from 0.0
"""
@inline Base.@propagate_inbounds function ADL(prices::Matrix{T}) where T <: AbstractFloat
    n = size(prices, 1)

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]
    volumes = @view prices[:, 4]

    # Pre-allocate arrays
    adl = zeros(T,n)

    @inbounds for i in 1:n
        if (highs[i] - lows[i]) == 0 || volumes[i] == 0
            mfv = 0.0
        else
            clv = (2 * closes[i] - lows[i] - highs[i]) / (highs[i] - lows[i])
            mfv = clv * volumes[i]
        end

        # Calculate ADL
        adl[i] = (i > 1 ? adl[i-1] : 0.0) + mfv
    end

    return adl
end

@prep_miso ADL [High, Low, Close, Volume]
