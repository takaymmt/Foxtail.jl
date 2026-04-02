# Quality Review: Foxtail.jl -- 17 Technical Indicators Addition

**Reviewer**: Quality Reviewer (Opus subagent)
**Date**: 2026-04-01
**Commit**: dd32c67
**Scope**: 21 new/modified source files, 2 test files

---

## Executive Summary

Overall code quality is **good**. The implementation follows consistent patterns, leverages the macro system effectively, and has thorough test coverage with numerical validation. The docstrings are exemplary -- among the best I have seen in a Julia library. There are a handful of findings worth addressing, mostly Medium/Low severity.

**Statistics**:
- High severity: 2
- Medium severity: 8
- Low severity: 10

---

## Findings

### HIGH SEVERITY

#### H-1: ROC -- Division by zero when price is zero (ROC.jl, line 13)

**File**: `src/indicators/ROC.jl`, line 13
**Current code**:
```julia
result[i] = (prices[i] - prices[i-period]) / prices[i-period] * 100.0
```

**Issue**: If `prices[i-period]` is `0.0`, this produces `Inf` or `NaN`. Unlike most indicators where zero-price is unrealistic, ROC can be applied to arbitrary time series (oscillators, spreads) where zero values are plausible.

**Suggested improvement**: Add a zero guard, returning `0.0` when the denominator is zero, or document that zero prices are unsupported.

```julia
if prices[i-period] == 0.0
    result[i] = 0.0
else
    result[i] = (prices[i] - prices[i-period]) / prices[i-period] * 100.0
end
```

**Impact**: Runtime `NaN`/`Inf` propagation into downstream indicators (KST depends on ROC).

---

#### H-2: VPT -- Division by zero when previous close is zero (VPT.jl, line 51)

**File**: `src/indicators/VPT.jl`, line 51
**Current code**:
```julia
results[i] = results[i-1] + volumes[i] * (closes[i] - closes[i-1]) / closes[i-1]
```

**Issue**: Same division-by-zero risk as ROC. If `closes[i-1] == 0.0`, produces `Inf`/`NaN`.

**Suggested improvement**: Guard against zero denominator.

---

### MEDIUM SEVERITY

#### M-1: NVI/PVI -- Division by zero when previous close is zero (NVI.jl:57, PVI.jl:56)

**File**: `src/indicators/NVI.jl`, line 57; `src/indicators/PVI.jl`, line 56
**Current code**:
```julia
results[i] = results[i-1] * (1.0 + (closes[i] - closes[i-1]) / closes[i-1])
```

**Issue**: Division by zero if `closes[i-1] == 0.0`. Same pattern as H-1/H-2 but NVI/PVI are specifically for stock prices where zero close is extremely unlikely (hence Medium, not High).

**Suggested improvement**: Add zero guard consistent with ROC fix.

---

#### M-2: EMV -- Magic number 100_000_000 (EMV.jl, line 56)

**File**: `src/indicators/EMV.jl`, line 56
**Current code**:
```julia
box_ratio = (vol[i] / 100_000_000.0) / hl_diff
```

**Issue**: The `100_000_000.0` is a magic number. While the EMV formula traditionally uses this divisor for volume normalization, it should be a named constant for clarity.

**Suggested improvement**:
```julia
const EMV_VOLUME_DIVISOR = 1e8
# ...
box_ratio = (vol[i] / EMV_VOLUME_DIVISOR) / hl_diff
```

---

#### M-3: MFI -- O(n*k) sliding window computation (MFI.jl, lines 73-87)

**File**: `src/indicators/MFI.jl`, lines 73-87
**Current code**:
```julia
@inbounds for i in 1:nrows
    pos_flow = 0.0
    neg_flow = 0.0
    start = max(1, i - n + 1)
    for j in start:i
        # ...
    end
end
```

**Issue**: The nested loop computes the rolling sum by re-summing the entire window each iteration, resulting in O(n*k) time complexity. For large datasets with large windows, this is significantly slower than the O(n) approach using a CircBuff-based rolling sum.

**Suggested improvement**: Use a sliding window with additive/subtractive updates, similar to how CMF also has this pattern (CMF.jl, lines 74-89).

**Note**: CMF.jl has the same O(n*k) pattern. Both should be improved.

---

#### M-4: CMF -- O(n*k) sliding window computation (CMF.jl, lines 74-89)

**File**: `src/indicators/CMF.jl`, lines 74-89

Same issue as M-3. The inner loop re-sums the window each bar.

---

#### M-5: CCI -- Using CircBuff value() creates allocation in hot loop (CCI.jl, lines 66-79)

**File**: `src/indicators/CCI.jl`, lines 66-79
**Current code**:
```julia
@inbounds for i in 1:nrows
    # ...
    buf = value(cb)
    wlen = length(cb)
    sma_tp = 0.0
    for j in 1:wlen
        sma_tp += buf[j]
    end
    # ...
end
```

**Issue**: `value(cb)` returns `view(cb.buffer, _buf_idx(cb, 1:cb._length))` which allocates the index array on every call. Inside a hot loop, this causes unnecessary GC pressure.

**Suggested improvement**: Replace `value(cb)` with direct indexing `cb[j]` or maintain a running sum and use additive updates.

---

#### M-6: Ichimoku TSFrame wrapper -- oneunit fallback is fragile (Ichimoku.jl, line 152)

**File**: `src/indicators/Ichimoku.jl`, line 152
**Current code**:
```julia
unit_step = oneunit(idx[end] - idx[end])
```

**Issue**: `oneunit(zero(T))` for date types returns `Day(1)` or `Millisecond(1)` depending on type, but `idx[end] - idx[end]` is always zero-like. This is a fragile pattern. For `DateTime` indices, `oneunit(Millisecond(0))` returns `Millisecond(1)`, which is almost certainly not the intended step size.

**Suggested improvement**: Document this edge case or throw an error for single-element inputs.

---

#### M-7: KeltnerChannel -- Missing input validation for minimum length (KeltnerChannel.jl)

**File**: `src/indicators/KeltnerChannel.jl`
**Current code**: No length validation present.

**Issue**: Unlike `DonchianChannel` and `Supertrend` which validate `period < 1`, `KeltnerChannel` does not validate that the input length is sufficient. ATR and EMA will handle this internally, but the error message will be confusing for the user.

**Suggested improvement**: Add:
```julia
if len < period
    throw(ArgumentError("price series length must be >= period"))
end
```

---

#### M-8: DPO -- Redundant bounds check (DPO.jl, lines 46-50)

**File**: `src/indicators/DPO.jl`, lines 46-50
**Current code**:
```julia
@inbounds for i in (shift+1):len
    idx = i - shift
    if idx >= 1
        result[i] = prices[i] - sma_values[idx]
    end
end
```

**Issue**: The `if idx >= 1` check is always true because `i >= shift+1` implies `idx = i - shift >= 1`. This is dead code inside the `@inbounds` block.

**Suggested improvement**: Remove the redundant check:
```julia
@inbounds for i in (shift+1):len
    result[i] = prices[i] - sma_values[i - shift]
end
```

---

### LOW SEVERITY

#### L-1: ROC -- Missing docstring (ROC.jl)

**File**: `src/indicators/ROC.jl`
**Issue**: ROC is the only new indicator without a docstring. All other 16 indicators have comprehensive docstrings with parameters, formula, interpretation, and examples.

**Suggested improvement**: Add a docstring matching the established pattern.

---

#### L-2: DonchianChannel -- Missing docstring (DonchianChannel.jl)

**File**: `src/indicators/DonchianChannel.jl`
**Issue**: No docstring. Same as L-1.

---

#### L-3: KeltnerChannel -- Missing docstring (KeltnerChannel.jl)

**File**: `src/indicators/KeltnerChannel.jl`
**Issue**: No docstring. Same as L-1.

---

#### L-4: PPO -- Missing `@inline Base.@propagate_inbounds` annotation (PPO.jl, line 47)

**File**: `src/indicators/PPO.jl`, line 47
**Current code**:
```julia
function PPO(prices::Vector{Float64}; fast::Int = 12, slow::Int = 26, signal::Int = 9)
```

**Issue**: Most indicators in this PR use `@inline Base.@propagate_inbounds`. PPO, KST, and Ichimoku's TSFrame wrapper do not. While this is not strictly required for functions that don't use `@inbounds` indexing themselves, it breaks consistency.

**Note**: This is a stylistic consistency issue. The `@inline` hint is likely unnecessary for these higher-level functions that delegate to EMA/SMA, but worth noting for pattern consistency.

---

#### L-5: KST -- Missing `@inline Base.@propagate_inbounds` annotation (KST.jl, line 52)

Same as L-4.

---

#### L-6: Inconsistent naming -- `nrows` vs `len` vs `n` for array length

**Files**: Multiple indicators
**Issue**: Some files use `len` for the array length (Supertrend, ForceIndex), others use `nrows` (CCI, MFI, CMF, Aroon), and VWAP/VPT/NVI/PVI shadow the parameter `n` by also using `n = size(data, 1)`. The latter is particularly confusing for indicators that also have a period parameter named `n`.

**Affected files**: `VWAP.jl` (line 41), `VPT.jl` (line 39), `NVI.jl` (line 44), `PVI.jl` (line 44) -- all use `n` for array length even though `n` is conventionally the period in this codebase.

**Suggested improvement**: Standardize on `len` for array length across all indicators. For `VWAP`/`VPT`/`NVI`/`PVI` which have no period parameter, using `n` is acceptable but breaks convention with the rest of the codebase.

---

#### L-7: PPO allocates an unnecessary intermediate matrix (PPO.jl, lines 67-72)

**File**: `src/indicators/PPO.jl`, lines 67-72
**Current code**:
```julia
results = zeros(len, 3)
results[:, 1] = ppo_line
results[:, 2] = signal_line
results[:, 3] = histogram
```

**Issue**: Could use `hcat(ppo_line, signal_line, histogram)` directly like other indicators, avoiding the intermediate `zeros` allocation and column-by-column copy.

---

#### L-8: KST -- Same unnecessary intermediate allocation pattern (KST.jl, lines 69-73)

Same as L-7.

---

#### L-9: SqueezeMomentum -- Unnecessary Vector() copy of Close column (SqueezeMomentum.jl, line 62)

**File**: `src/indicators/SqueezeMomentum.jl`, line 62
**Current code**:
```julia
closes = Vector(prices[:, 3])
```

**Issue**: `BB` requires a `Vector{Float64}`, so this copy is technically necessary. However, it could use `@view prices[:, 3]` and convert in-place for the `BB` call, or document why the copy is needed.

**Impact**: Minor -- one extra allocation for the close column.

---

#### L-10: ParabolicSAR -- Function length exceeds 30-line guideline (ParabolicSAR.jl, 44-138)

**File**: `src/indicators/ParabolicSAR.jl`, lines 44-138
**Issue**: The main function body is ~95 lines. While the logic is inherently sequential and well-structured with clear comments, it exceeds the 30-line target significantly.

**Suggested improvement**: Consider extracting the uptrend/downtrend logic into helper functions. However, this is a judgment call -- the function is readable as-is and splitting it might hurt readability for a stateful algorithm.

---

## Consistency Analysis

### Positive Patterns (consistently followed)
1. **Macro usage**: All indicators correctly use `@prep_siso`, `@prep_miso`, `@prep_simo`, or `@prep_mimo`
2. **Input validation**: All matrix-input indicators validate column count
3. **Period validation**: All indicators with a period parameter validate `n >= 1` (except minor gaps noted above)
4. **`@view` usage**: Column extraction from matrices consistently uses `@view`
5. **`@inbounds` usage**: Hot loops consistently use `@inbounds` blocks
6. **Docstring structure**: 16/17 indicators follow the exact same docstring template (Parameters, Returns, Formula, Interpretation, Example, See Also)
7. **Test structure**: All indicators have type tests, numerical validation, AAPL smoke tests

### Areas of Inconsistency
1. **`@inline Base.@propagate_inbounds` annotation**: Present on 15/17 core functions, missing on PPO and KST
2. **Docstrings**: Missing on ROC, DonchianChannel, KeltnerChannel
3. **Length variable naming**: `len` vs `nrows` vs `n`
4. **Division-by-zero guards**: Some indicators guard (CCI, CMF), others don't (ROC, VPT, NVI, PVI)

---

## Test Quality Assessment

### Strengths
- **Numerical validation**: All indicators have hand-calculated expected values, not just "does it run" tests
- **Edge cases**: Constant prices, monotonic trends, alternating patterns tested
- **Range validation**: Bounded indicators (MFI, Aroon, ADX) verify output ranges
- **Cross-validation**: PPO verified against MACD, ForceIndex verified against EMA(raw_force)
- **Input validation**: Error-throwing tests for wrong column counts

### Gaps
- **Missing edge case**: No tests for zero-price inputs (would catch H-1, H-2)
- **Missing edge case**: No single-element input tests for most indicators
- **No property-based tests**: Could benefit from random input testing for invariants (e.g., Aroon Oscillator always equals Up - Down)

---

## MinMaxQueue Review

**File**: `src/tools/MinMaxQueue.jl`

**Quality**: Excellent. Clean implementation of the monotonic deque pattern.

- Docstring is thorough with complexity analysis
- `@inline` on all methods is appropriate
- Type parameterization is correct
- All 6 methods (update!, remove_old!, get_max, get_min, get_max_idx, get_min_idx) are consistent
- Test coverage in `test_MinMaxQueue.jl` is comprehensive (189 lines of tests)

**One note**: The struct stores `Tuple{T, Int}` pairs. For large sliding windows, a struct-of-arrays approach might be more cache-friendly, but this is micro-optimization and not worth changing for correctness.

---

## Recommendations

### Must Fix (before release)
1. **H-1**: Add division-by-zero guard to ROC (KST depends on it)
2. **H-2**: Add division-by-zero guard to VPT

### Should Fix (improve quality)
3. **L-1, L-2, L-3**: Add docstrings to ROC, DonchianChannel, KeltnerChannel
4. **M-8**: Remove dead code in DPO
5. **M-2**: Extract magic number in EMV

### Nice to Have (performance/consistency)
6. **M-3, M-4**: Optimize MFI/CMF to O(n) sliding window
7. **M-5**: Fix CCI allocation in hot loop
8. **L-6**: Standardize length variable naming
