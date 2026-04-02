@inline Base.@propagate_inbounds function ROC(prices::Vector{Float64}; n::Int=14)
    period = n
    period < 1 && throw(ArgumentError("period must be positive"))

    len = length(prices)
    len < period + 1 && throw(ArgumentError("price series length must be greater than period + 1"))

    result = zeros(len)

    # Startup period: first n values are 0.0
    # After startup: ROC[i] = (P[i] - P[i-n]) / P[i-n] * 100
    @inbounds for i in (period+1):len
        result[i] = iszero(prices[i-period]) ? 0.0 : (prices[i] - prices[i-period]) / prices[i-period] * 100.0
    end

    return result
end

@prep_siso ROC n=14
