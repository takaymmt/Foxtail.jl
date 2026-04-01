"""
    KST(prices::Vector{Float64}; r1::Int=10, r2::Int=13, r3::Int=15, r4::Int=20, s1::Int=10, s2::Int=13, s3::Int=15, s4::Int=20, signal::Int=9) -> Matrix{Float64}

Calculate Know Sure Thing (KST) — a momentum oscillator based on smoothed rate-of-change for four different timeframes.

## Parameters
- `prices`: Input price vector (`Float64`), typically closing prices.
- `r1`: ROC period 1 (default: 10).
- `r2`: ROC period 2 (default: 13).
- `r3`: ROC period 3 (default: 15).
- `r4`: ROC period 4 (default: 20).
- `s1`: SMA smoothing period for ROC1 (default: 10).
- `s2`: SMA smoothing period for ROC2 (default: 13).
- `s3`: SMA smoothing period for ROC3 (default: 15).
- `s4`: SMA smoothing period for ROC4 (default: 20).
- `signal`: SMA period for the signal line (default: 9).

## Returns
Matrix of size `(length(prices), 2)`:
- Column 1: KST line
- Column 2: Signal line (SMA of KST line)

## Formula
```math
\\begin{aligned}
ROC1 &= SMA_{s1}(ROC(P, r1)) \\\\
ROC2 &= SMA_{s2}(ROC(P, r2)) \\\\
ROC3 &= SMA_{s3}(ROC(P, r3)) \\\\
ROC4 &= SMA_{s4}(ROC(P, r4)) \\\\
KST &= 1 \\cdot ROC1 + 2 \\cdot ROC2 + 3 \\cdot ROC3 + 4 \\cdot ROC4 \\\\
Signal &= SMA_{signal}(KST)
\\end{aligned}
```

## Interpretation
- KST crossing above signal line: bullish signal.
- KST crossing below signal line: bearish signal.
- Positive KST: upward momentum across multiple timeframes.
- Divergence between KST and price: potential trend reversal.
- Created by: Martin Pring.

## Example
```julia
prices = collect(1.0:100.0)
result = KST(prices)
# result[:,1] = KST line, result[:,2] = Signal line
```

## See Also
[`ROC`](@ref), [`MACD`](@ref), [`SMA`](@ref)
"""
function KST(prices::Vector{Float64}; r1::Int=10, r2::Int=13, r3::Int=15, r4::Int=20,
             s1::Int=10, s2::Int=13, s3::Int=15, s4::Int=20, signal::Int=9)
    len = length(prices)

    # Calculate smoothed ROC components
    roc1 = apply_ma(ROC(prices; n=r1), :SMA; n=s1)
    roc2 = apply_ma(ROC(prices; n=r2), :SMA; n=s2)
    roc3 = apply_ma(ROC(prices; n=r3), :SMA; n=s3)
    roc4 = apply_ma(ROC(prices; n=r4), :SMA; n=s4)

    # KST = 1*ROC1 + 2*ROC2 + 3*ROC3 + 4*ROC4
    kst_line = 1.0 .* roc1 .+ 2.0 .* roc2 .+ 3.0 .* roc3 .+ 4.0 .* roc4

    # Signal = SMA(KST, signal)
    signal_line = apply_ma(kst_line, :SMA; n=signal)

    # Combine results
    results = zeros(len, 2)
    results[:, 1] = kst_line
    results[:, 2] = signal_line

    return results
end

@prep_simo KST [Line, Signal] r1=10 r2=13 r3=15 r4=20 s1=10 s2=13 s3=15 s4=20 signal=9
