"""
    ALMA(prices::Vector; n::Int=10, offset::Float64=0.85, sigma::Float64=6.0) -> Vector{Float64}

Calculate Arnaud Legoux Moving Average (ALMA) — a Gaussian-weighted moving average that reduces lag while maintaining smoothness.

## Parameters
- `prices`: Input price series (any numeric vector).
- `n`: Window size / period length (default: 10). Valid range: `n >= 1`.
- `offset`: Controls weight distribution center (default: 0.85). Valid range: `0.0` to `1.0`.
  Higher values emphasize recent prices; lower values emphasize older prices.
- `sigma`: Controls Gaussian curve width (default: 6.0). Valid range: `> 0`.
  Lower values create sharper (more responsive) curves; higher values create gentler (smoother) curves.

## Returns
Vector of ALMA values for the input series.

## Formula
```math
ALMA_t = \\sum_{i=0}^{n-1} \\hat{w}_i \\cdot P_{t-n+1+i}
```
where the normalized Gaussian weights are:
```math
w_i = \\exp\\!\\left(-\\frac{(i - m)^2}{2s^2}\\right), \\quad
m = \\text{offset} \\cdot (n-1), \\quad s = \\frac{n}{\\sigma}, \\quad
\\hat{w}_i = \\frac{w_i}{\\sum_j w_j}
```

## Interpretation
- Combines low lag (via offset toward recent prices) with smoothness (via Gaussian weighting).
- `offset=0.85` places the Gaussian peak near the most recent data, reducing lag.
- `sigma=6.0` provides a broad, smooth bell curve; smaller values sharpen the response.
- Common parameter sets: short-term (n=9), medium-term (n=21), long-term (n=50).
- Created by: Arnaud Legoux and Dimitris Kouzis-Loukas.

## Example
```julia
prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0]
result = ALMA(prices; n=5, offset=0.85, sigma=6.0)
```

## See Also
[`EMA`](@ref), [`HMA`](@ref), [`KAMA`](@ref)
"""

@inline Base.@propagate_inbounds function ALMA(prices::Vector; n::Int=10, offset::Float64=0.85, sigma::Float64=6.0)
	period = n
	len = length(prices)
	result = Vector{Float64}(undef, len)
	result[1] = copy(prices[1])

	m = 0.0
	s = 0.0
	weights = zeros(eltype(prices), period)
	@inbounds for window in 2:period
		m = offset * (window - 1)
		s = window / sigma
		@inbounds for j in 0:(window-1)
			weights[j+1] = exp(-((j - m)^2) / (2 * s^2))
		end
		weights ./= sum(weights)
		result[window] = dot(view(prices, 1:window), view(weights,1:window))
	end
	@inbounds for i in (period+1):len
		result[i] = dot(view(prices, (i-period+1):i), weights)
	end
	return result
end

@prep_siso ALMA n=10 (offset=0.85, sigma=6.0)