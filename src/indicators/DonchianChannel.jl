@inline Base.@propagate_inbounds function DonchianChannel(prices::Matrix{Float64}; n::Int=20)
    period = n
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end

    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)
    if len < period
        throw(ArgumentError("price series length must be greater than or equal to period"))
    end

    highs = @view prices[:, 1]
    lows = @view prices[:, 2]

    upper = zeros(len)
    lower = zeros(len)
    middle = zeros(len)

    mmq = MinMaxQueue{Float64}(period + 1)

    # Build up initial window
    @inbounds for i in 1:period
        update!(mmq, highs[i], lows[i], i)

        upper[i] = get_max(mmq)
        lower[i] = get_min(mmq)
        middle[i] = (upper[i] + lower[i]) / 2.0
    end

    # Sliding window
    @inbounds for i in (period+1):len
        remove_old!(mmq, i - period)
        update!(mmq, highs[i], lows[i], i)

        upper[i] = get_max(mmq)
        lower[i] = get_min(mmq)
        middle[i] = (upper[i] + lower[i]) / 2.0
    end

    return hcat(upper, lower, middle)
end

@prep_mimo DonchianChannel [High, Low, Close] [Upper, Lower, Middle] n=20
