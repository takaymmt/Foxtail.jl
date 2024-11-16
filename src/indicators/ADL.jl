# Accumulation/Distribution Indicator
# function ADL(ts::TSFrame; field::Vector{Symbol} = [:High, :Low, :Close, :Volume])
# 	prices = ts[:, field] |> Matrix
# 	results = ADL(prices)
# 	colnames = [:ADL]
# 	return TSFrame(results, index(ts), colnames = colnames)
# end
# export ADL

@inline Base.@propagate_inbounds function ADL(prices::Matrix{T}) where T <: AbstractFloat
    n = size(prices, 1)

    # Extract price data
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]
    volumes = @view prices[:, 4]

    # Pre-allocate arrays
    adl = zeros(T,n)

    # # Calculate Money Flow Multiplier and Money Flow Volume
    # @inbounds for i in 1:n
    #     clv = (2 * closes[i] - lows[i] - highs[i]) / (highs[i] - lows[i])
    #     # clv = ((closes[i] - lows[i]) - (highs[i] - closes[i])) / (highs[i] - lows[i])
    #     mfv = clv * volumes[i]

    #     # Calculate ADL
    #     adl[i] = (i > 1 ? adl[i-1] : 0.0) + mfv
    # end

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
