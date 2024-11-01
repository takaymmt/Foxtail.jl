@inline Base.@propagate_inbounds function RSI(prices::Vector{Float64}, period::Int=14; smoothing::Symbol=:SMMA)
    if period < 1
        throw(ArgumentError("period must be positive"))
    end

    n = length(prices)
    if n < period + 1
        throw(ArgumentError("price series length must be greater than period + 1"))
    end

    # Calculate price changes
    changes = diff(prices)
    
    # Separate gains and losses
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
        if i <= period + 1
            rsi[i] = 0  # Values during the initial period are undefined
        else
            idx = i - 1  # Index for rs array which is one element shorter
            if rs[idx] ≈ 0.0
                rsi[i] = 0.0
            else
                rsi[i] = 100.0 - (100.0 / (1.0 + rs[idx]))
            end
        end
    end

    return rsi
end

@prep_SISO RSI