function OBV(ts::TSFrame; field::Vector{Symbol} = [:Close, :Volume])
	data = ts[:, field] |> Matrix
	results = OBV(data)
	colnames = [:OBV]
	return TSFrame(results, index(ts), colnames = colnames)
end
export OBV

"""
    OBV(data::Matrix{Float64})

Calculate On Balance Volume (OBV) indicator.

OBV is a cumulative indicator that adds volume on up days and subtracts volume on down days.
It shows buying/selling pressure through volume changes.

# Arguments
- `data`: Price matrix with columns [close, volume]

# Returns
- Vector containing OBV values

# Formula
If close > close_prev:
    OBV = OBV_prev + Volume
If close < close_prev:
    OBV = OBV_prev - Volume
If close = close_prev:
    OBV = OBV_prev
"""
@inline Base.@propagate_inbounds function OBV(data::Matrix{Float64})
    if size(data, 2) != 2
        throw(ArgumentError("data matrix must have 2 columns [close volume]"))
    end

    n = size(data, 1)
    results = zeros(n)

    # Extract price and volume data
    closes = @view data[:, 1]
    volumes = @view data[:, 2]

    # Initialize first value with first volume
    @inbounds results[1] = volumes[1]

    # Calculate OBV
    @inbounds for i in 2:n
        if closes[i] > closes[i-1]
            results[i] = results[i-1] + volumes[i]
        elseif closes[i] < closes[i-1]
            results[i] = results[i-1] - volumes[i]
        else
            results[i] = results[i-1]
        end
    end

    return results
end
