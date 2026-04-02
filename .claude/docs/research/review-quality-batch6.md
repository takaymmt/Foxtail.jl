# Quality Review: Batch 6 Indicators

> Reviewer: Quality Reviewer (Opus subagent)
> Date: 2026-04-02
> Files reviewed: MassIndex.jl, UltimateOsc.jl, Vortex.jl, ConnorsRSI.jl, PivotPoints.jl
> Reference files: ATR.jl, CCI.jl, Aroon.jl, RSI.jl
> Design doc: indicator-formulas.md, DESIGN-remaining-indicators.md
> Test status: All 4,267 tests pass

---

## Summary

Overall quality is **high**. All 5 indicators follow established codebase patterns, formulas match the research document, and comprehensive tests exist. I found **0 High severity**, **3 Medium severity**, and **7 Low severity** issues.

---

## Findings

### Finding 1: MassIndex rolling sum uses O(n) per-bar iteration instead of O(1) running sum

- **Severity**: Medium
- **File**: `MassIndex.jl`, lines 87-97
- **Category**: Performance

**Current code:**
```julia
@inbounds for i in 1:nrows
    push!(cb, ratio[i])
    buf = value(cb)
    s = 0.0
    for j in 1:length(cb)
        s += buf[j]
    end
    results[i] = s
end
```

**Issue**: The rolling sum is computed by iterating over the entire CircBuff each bar, giving O(n) per bar and O(n*rows) total. Other indicators in the codebase (e.g., CMF.jl lines 74-96, Vortex.jl lines 78-97) use an O(1) running-sum pattern where they maintain a running total and subtract the outgoing element.

**Suggested improvement:**
```julia
running_sum = 0.0
@inbounds for i in 1:nrows
    if isfull(cb)
        running_sum -= first(cb)
    end
    push!(cb, ratio[i])
    running_sum += ratio[i]
    results[i] = running_sum
end
```

**Impact**: For default n=25 this is not critical, but it is an inconsistency with the O(1) pattern used elsewhere. The `value(cb)` call also creates a view on each iteration that is unnecessary.

---

### Finding 2: UltimateOsc rolling sums use O(n) per-bar iteration instead of O(1) running sum

- **Severity**: Medium
- **File**: `UltimateOsc.jl`, lines 90-137
- **Category**: Performance

**Current code:**
```julia
@inbounds for i in 1:nrows
    push!(bp_fast_cb, bp[i])
    # ...6 pushes...

    sum_bp_fast = 0.0
    # ...6 zeros...

    buf = value(bp_fast_cb)
    for j in 1:length(bp_fast_cb)
        sum_bp_fast += buf[j]
    end
    # ...repeat for 5 more buffers...
end
```

**Issue**: Same O(n) per-bar pattern as MassIndex. With 6 separate CircBuffs each doing full iteration, this is particularly wasteful. The CMF.jl and Vortex.jl patterns demonstrate the O(1) running-sum approach used elsewhere in this codebase.

**Suggested improvement**: Maintain 6 running-sum variables (like Vortex does with 3) and use the `isfull` / subtract-first / push / add pattern for O(1) per bar.

**Impact**: For default periods (7, 14, 28), performance impact is minor with typical data sizes. However, the inconsistency with the Vortex indicator (which correctly uses running sums in the same batch) is notable -- two indicators implemented in the same batch use different patterns for the same operation.

---

### Finding 3: Design doc Woodie formula has a typo (2C vs 2O)

- **Severity**: Medium
- **File**: `DESIGN-remaining-indicators.md`, line 366
- **Category**: Documentation accuracy

**Current text in design doc:**
```
P  = (H + L + 2C) / 4
```

**Should be:**
```
P  = (H + L + 2O) / 4
```

**Verification**: The research document (indicator-formulas.md line 50) correctly states `PP = (H + L + 2 * O_current) / 4`. The implementation (PivotPoints.jl line 136) correctly uses `(H + L + 2.0 * O) / 4.0`. The test (test_Indicators_MIMO.jl line 891) correctly uses `(110.0 + 100.0 + 2.0 * 102.0) / 4.0` with Open=102.

**Impact**: The implementation is correct. Only the design document contains the error. However, this is a Medium severity issue because the design doc is an authoritative reference and a future developer reading only the design doc could be confused.

---

### Finding 4: MassIndex ratio division-by-zero sets 0.0 instead of 1.0

- **Severity**: Low
- **File**: `MassIndex.jl`, lines 77-80
- **Category**: Mathematical semantics

**Current code:**
```julia
if double_ema[i] == 0.0
    ratio[i] = 0.0
else
    ratio[i] = single_ema[i] / double_ema[i]
end
```

**Discussion**: When both single_ema and double_ema are 0.0 (constant zero range = H==L), the ratio is mathematically indeterminate (0/0). Setting it to 0.0 means the Mass Index sum will be lower than the period n, which could mislead. A value of 1.0 would be more natural since in normal operation the ratio hovers near 1.0, and the Mass Index would then hover near n (its expected center).

**However**: This is a design choice, not a bug. The test at line 752 validates `r[1] approx 1.0` for bar 1, and the constant-range test validates convergence to n. The 0/0 case only occurs with pathological data (H==L for every bar), and the existing behavior is documented. Marking as Low because the current behavior is defensible.

---

### Finding 5: ConnorsRSI returns broadcasted expression instead of pre-allocated vector

- **Severity**: Low
- **File**: `ConnorsRSI.jl`, line 65
- **Category**: Performance / Style consistency

**Current code:**
```julia
return (rsi_price .+ rsi_streak .+ pct_rank) ./ 3.0
```

**Discussion**: This uses Julia's broadcasting which allocates intermediate arrays. Most other indicators in the codebase pre-allocate a result vector and fill it in a loop with `@inbounds`. However, this is only 2 allocations for the full computation, and the style is idiomatic Julia. The difference is measurable only for very large inputs.

**Impact**: Negligible performance difference in practice. The code is more readable this way.

---

### Finding 6: Vortex indicator uses both CircBuff and running-sum (redundant)

- **Severity**: Low
- **File**: `Vortex.jl`, lines 74-103
- **Category**: Redundancy

**Current code:**
```julia
cb_vm_plus  = CircBuff{Float64}(n)
# ...
sum_vm_plus  = 0.0
# ...
if isfull(cb_vm_plus)
    sum_vm_plus  -= first(cb_vm_plus)
# ...
push!(cb_vm_plus, vm_plus[i])
sum_vm_plus  += vm_plus[i]
```

**Discussion**: The CircBuff is used only to remember which element to subtract when the window slides. The actual sums are tracked separately. This is a valid pattern, but an alternative would be to use a simple index-based subtraction (like CMF.jl does with `sum_mfv -= mfv[i - n]`) since the data is already stored in `vm_plus`/`vm_minus`/`tr_vals` arrays. This would eliminate 3 CircBuff allocations.

**Impact**: Minor. The current approach is correct and the CircBuff overhead is small.

---

### Finding 7: ConnorsRSI does not validate period relationships

- **Severity**: Low
- **File**: `ConnorsRSI.jl`, lines 48-51
- **Category**: Input validation

**Current code:**
```julia
len > 1 || throw(ArgumentError("price series length must be greater than 1"))
n_rsi >= 1 || throw(ArgumentError("n_rsi must be positive"))
n_streak >= 1 || throw(ArgumentError("n_streak must be positive"))
n_pctrank >= 1 || throw(ArgumentError("n_pctrank must be positive"))
```

**Discussion**: The function validates that `len > 1` but does not check that `len > n_rsi + 1` or `len > n_streak + 1`, which are requirements of the internal `RSI()` calls. If someone calls `ConnorsRSI(rand(3); n_rsi=14)`, the error will come from RSI with a less descriptive message. However, this is consistent with the existing codebase pattern where inner function validation catches such errors (e.g., ATR does not re-validate EMA's length requirements).

**Impact**: Low. The error still occurs; just the message could be more helpful.

---

### Finding 8: MassIndex and UltimateOsc do not check for empty input

- **Severity**: Low
- **File**: `MassIndex.jl`, `UltimateOsc.jl`
- **Category**: Input validation

**Discussion**: Neither MassIndex nor UltimateOsc explicitly validates that the input matrix has at least 1 row. With 0 rows, `EMA()` would receive an empty vector. However, this is consistent with the existing pattern -- ATR.jl, CCI.jl also do not check for empty input. Only Aroon explicitly checks (line 55-57). This is a low-priority inconsistency.

---

### Finding 9: PivotPoints `_pivot_woodie!` does not use Close parameter

- **Severity**: Low
- **File**: `PivotPoints.jl`, lines 125-147
- **Category**: API consistency

**Current signature:**
```julia
function _pivot_woodie!(result, highs, lows, closes, opens)
```

**Discussion**: The `closes` parameter is passed but never used inside `_pivot_woodie!`. The Woodie method intentionally uses Open instead of Close for the pivot calculation, and uses the same R1/S1/R2/S2/R3/S3 formulas as Classic (which derive from P and H/L only, not C). The `closes` parameter exists for API consistency with other `_pivot_*!` functions but is dead code.

**Impact**: Harmless. The compiler will optimize it away, and the consistent function signature makes the dispatch code in the main function cleaner. Not a bug.

---

### Finding 10: Magic number 0.015 not named as constant in design (CCI reference)

- **Severity**: Low
- **File**: N/A (existing codebase reference)
- **Category**: Observation only

**Discussion**: This is not a finding in the batch 6 code. Noting for context that the existing CCI.jl uses `0.015` inline. None of the batch 6 indicators introduce new unexplained magic numbers. The Fibonacci coefficients (0.382, 0.618) and Camarilla coefficient (1.1) are standard, well-documented values in the indicator formulas.

---

## Correctness Verification Summary

### MassIndex
- Formula matches research doc: single EMA -> double EMA -> ratio -> rolling sum. **PASS**
- Warmup: starts accumulating from bar 1 with partial sums. **PASS**
- Column naming: `MassIndex_25` (via `@prep_miso` with `n=25`). **PASS**

### UltimateOsc
- Formula matches research doc: BP, TR, three-period sum ratios, weighted combination. **PASS**
- Bar 1 handling: `bp[1] = 0.0` (no previous close). **PASS**
- Weights: 4:2:1 with divisor 7. **PASS**
- Column naming: `UltimateOsc` (no period suffix since 3 params). **PASS**

### Vortex
- Formula matches research doc: VM+, VM-, rolling sums, normalized by TR sum. **PASS**
- Bar 1 handling: `vm_plus[1] = 0.0`, `vm_minus[1] = 0.0`. **PASS**
- Column naming: `Vortex_VIPlus`, `Vortex_VIMinus`. **PASS**

### ConnorsRSI
- Component 1 (RSI of price): delegates to existing RSI. **PASS**
- Component 2 (RSI of streak): streak resets to 0 on equal close. **PASS**
- Component 3 (percentile rank of ROC): strictly less than, excludes current value. **PASS**
- Composite: average of 3 components. **PASS**
- Column naming: `ConnorsRSI`. **PASS**

### PivotPoints
- Classic: `P = (H+L+C)/3`, standard R1-R3/S1-S3 formulas. **PASS**
- Fibonacci: same P, Fibonacci retracement coefficients. **PASS**
- Woodie: `P = (H+L+2O)/4`, uses Open not Close. **PASS**
- Camarilla: centered on Close with 1.1/12, 1.1/6, 1.1/4 coefficients. **PASS**
- DeMark: 3 conditional branches (C<O, C>O, C==O). **PASS**
- DeMark NaN: R2/R3/S2/S3 are NaN (via `fill(NaN, len, 7)` init). **PASS**
- Column naming: `PivotPoints_Pivot`, `PivotPoints_R1`, etc. **PASS**

---

## Pattern Consistency Checklist

| Pattern | MassIndex | UltimateOsc | Vortex | ConnorsRSI | PivotPoints |
|---------|-----------|-------------|--------|------------|-------------|
| `@inline Base.@propagate_inbounds` | Yes | Yes | Yes | Yes | Yes |
| `@view` for slicing | Yes | Yes | Yes | N/A (vector) | Yes |
| `@inbounds` in loops | Yes | Yes | Yes | Yes | Yes |
| `CircBuff` usage | Yes | Yes | Yes | No (not needed) | No (not needed) |
| Error message format | Consistent | Consistent | Consistent | Consistent | Consistent |
| Division-by-zero guard | Yes | Yes | Yes | N/A | N/A |
| Return type annotation | No | No | No | Yes (::Vector{Float64}) | No |
| Docstring format | Full | Full | Full | Full | Full |
| `@prep_*` macro | Correct | Correct | Correct | Correct | Correct |

**Note on return type annotation**: ConnorsRSI annotates the return type `::Vector{Float64}` on the function signature, while the other 4 do not. This is inconsistent but not harmful. The existing codebase is mixed on this (RSI.jl does not annotate, for example).

---

## Final Assessment

**Verdict: APPROVED with minor recommendations**

The batch 6 implementation is production-ready. All formulas are correct, tests are comprehensive (covering happy paths, edge cases, boundary values, error conditions), and the code follows established codebase conventions.

### Recommended Actions (optional, non-blocking)
1. **Consider**: Refactor MassIndex and UltimateOsc rolling sums to use O(1) running-sum pattern for consistency with CMF and Vortex.
2. **Fix**: Woodie formula typo in DESIGN-remaining-indicators.md (2C -> 2O).
3. **Consider**: Remove unused `closes` parameter from `_pivot_woodie!` or add a comment explaining why it is kept for API symmetry.
