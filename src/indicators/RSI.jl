@inline Base.@propagate_inbounds function RSI(prices::Vector{Float64}, period::Int=14; smoothing::Symbol=:SMMA)
    period < 1 && throw(ArgumentError("period must be positive"))

    n = length(prices)
    n < period + 1 && throw(ArgumentError("price series length must be greater than period + 1"))

    # Calculate price changes
    changes = diff(prices)
    gains = zeros(n-1)
    losses = zeros(n-1)

    @inbounds for i in 1:length(changes)
        if changes[i] > 0
            gains[i] = changes[i]
        else
            losses[i] = abs(changes[i])
        end
    end

    # Calculate RS (Relative Strength)
    if smoothing == :SMMA
        gains = SMMA(gains, period)
        losses = SMMA(losses, period)
    elseif smoothing == :EMA
        gains = EMA(gains, period)
        losses = EMA(losses, period)
    else  # Simple moving average
        gains = SMA(gains, period)
        losses = SMA(losses, period)
    end

    rs = gains ./ losses

    # Calculate RSI
    rsi = zeros(n)
    rsi[1] = 0  # First value is undefined

    @inbounds for i in 2:n
        rsi[i] = 100.0 - (100.0 / (1.0 + rs[i-1]))
    end

    return rsi
end

@prep_SISO RSI