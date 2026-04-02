# Anchored VWAP -- Codebase Analysis

Date: 2026-04-02

## 1. Existing VWAP Implementation

### File: `src/indicators/VWAP.jl`

**Core function signature:**
```julia
VWAP(data::Matrix{Float64}) -> Vector{Float64}
```

**Algorithm:**
- Input: 4-column matrix `[High, Low, Close, Volume]`
- Computes Typical Price: `TP = (H + L + C) / 3`
- Accumulates `cum_tpv += TP * V` and `cum_v += V` from row 1 onward
- Output: `VWAP[i] = cum_tpv / cum_v` (or 0.0 if cum_v == 0)
- No parameters (no `n`, no lookback -- purely cumulative from index 1)

**TSFrame wrapper:**
```julia
@prep_miso VWAP [High, Low, Close, Volume]
```
This generates:
```julia
function VWAP(ts::TSFrame; fields::Vector{Symbol}=[:High, :Low, :Close, :Volume])
    prices = ts[:, fields] |> Matrix
    results = VWAP(prices)
    return TSFrame(results, index(ts), colnames=[:VWAP])
end
export VWAP
```
Note: VWAP has NO extra parameters, so the macro generates a wrapper with only `fields`.

### Key observation
VWAP always starts accumulation from row 1. Anchored VWAP needs to start from a user-specified row.

---

## 2. @prep_miso Macro (src/macro.jl)

### What it generates
For `@prep_miso NAME [fields...] param1=val1 param2=val2`:

```julia
function NAME(ts::TSFrame; param1::Type=val1, ..., fields::Vector{Symbol}=[...])
    prices = ts[:, fields] |> Matrix
    results = NAME(prices; param1=param1, ...)
    return TSFrame(results, index(ts), colnames=[:NAME])  # or [:NAME_n] if `n` param exists
end
export NAME
```

### Key behaviors
1. `fields` kwarg is auto-added (always last in kw_args)
2. `field` (singular) is excluded from `call_args` -- consumed by wrapper only (SISO pattern)
3. `fields` (plural) is excluded from params processing -- auto-generated in MISO
4. If `n` param exists, column name becomes `Symbol(NAME, :_, n)`; otherwise just `Symbol(NAME)`
5. All other params are forwarded to the core function via `call_args`
6. The function and export are both generated

### Limitation for Anchored VWAP
The macro does NOT support parameters that should be consumed by the TSFrame wrapper (like an `anchor` date/index) but NOT forwarded to the core function. Only `field` (SISO) has this "consume-only" behavior. For MISO, all params except `fields` are forwarded.

---

## 3. Test Patterns

### Unit tests: `test/test_Indicators_MISO.jl`
- Uses hardcoded 100-row fixture arrays (`_high_col`, `_low_col`, `_close_col`, `_vol_col`)
- Creates `vec4 = hcat(...)` for raw Matrix tests and `data_ts` for TSFrame tests
- Pattern per indicator:
  1. Type check: `@test VWAP(vec4) isa Vector{Float64}`
  2. TSFrame smoke: `res = VWAP(data_ts); @test res isa TSFrame; @test names(res)[1] == "VWAP"`
  3. No NaN/Inf check
  4. Numerical validation with small hand-computed data
  5. Boundary/property checks (e.g., VWAP in [min(Low), max(High)])
  6. Constant input test
  7. Input validation (`@test_throws ArgumentError`)

### Integration tests: `test/test_Indicators_AAPL.jl`
- Loads real AAPL CSV data (2023-03-01 to 2024-06-28, 335 rows)
- Lighter tests: length check, no NaN/Inf, range check

### Test registration: `test/runtests.jl`
- Array of test file base names; includes via loop
- No need to modify runtests.jl if adding tests to existing test files

---

## 4. Module Export Pattern

### File: `src/Foxtail.jl`
```julia
readdir(joinpath(@__DIR__, "indicators"), join=true) |>
    f -> filter(x -> endswith(x, ".jl"), f) .|> include
```
- **Auto-discovery**: All `.jl` files in `src/indicators/` are automatically included
- **Export via macro**: `@prep_miso` generates `export NAME`
- No manual export list needed for indicators

---

## 5. Existing Utility Functions

- **No date/index lookup helpers** exist in the codebase
- **No "anchor" concept** exists anywhere
- Tools: `CircBuff`, `CircDeque`, `MinMaxQueue` -- none relevant for anchoring
- `apply_ma()` in macro.jl is the only shared utility function

---

## 6. Files That Need to Change for Anchored VWAP

| File | Change |
|------|--------|
| `src/indicators/AnchoredVWAP.jl` | **NEW** -- Core algorithm + TSFrame wrapper |
| `test/test_Indicators_MISO.jl` | Add `@testset "AnchoredVWAP"` block |
| `test/test_Indicators_AAPL.jl` | Add AAPL integration test |
| `docs/indicator-reference.md` | Add entry to Volume section |
| `CLAUDE.md` | Update indicator count (45 -> 46) |

**NOT needed:**
- `src/Foxtail.jl` -- auto-discovery handles new files
- `test/runtests.jl` -- tests go in existing files
- `src/macro.jl` -- see design decision below

---

## 7. Design Challenge: Anchor Parameter

### The core question
The `anchor` parameter defines **where** accumulation starts. Two design approaches:

### Approach A: Core function with `anchor::Int` parameter
```julia
function AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1) -> Vector{Float64}
```
- Rows before `anchor` output NaN (or 0.0)
- Accumulation starts at row `anchor`
- Simple, consistent with other indicators
- TSFrame wrapper converts Date -> row index before calling core
- `@prep_miso` CAN forward `anchor::Int` to core function
- TSFrame wrapper needs CUSTOM code to also accept Date anchor

### Approach B: Slice input externally
- Caller slices `data[anchor:end, :]` before calling regular VWAP
- No new indicator needed, just a convenience wrapper
- Less useful -- loses alignment with original index

### Recommended: Approach A with hand-written TSFrame wrapper
**Reason:** The `@prep_miso` macro cannot handle the Date-to-index conversion needed for the TSFrame wrapper. A hand-written wrapper is needed:

```julia
# Core: works with integer anchor
function AnchoredVWAP(data::Matrix{Float64}; anchor::Int=1) -> Vector{Float64}

# TSFrame wrapper: hand-written (NOT @prep_miso)
function AnchoredVWAP(ts::TSFrame; anchor::Union{Int,Date}=1,
                       fields::Vector{Symbol}=[:High, :Low, :Close, :Volume])
    # Convert Date -> Int via index lookup
    anchor_idx = anchor isa Date ? _resolve_anchor(ts, anchor) : anchor
    prices = ts[:, fields] |> Matrix
    results = AnchoredVWAP(prices; anchor=anchor_idx)
    return TSFrame(results, index(ts), colnames=[:AnchoredVWAP])
end
export AnchoredVWAP
```

### Precedent
No existing indicator has a hand-written TSFrame wrapper -- all use macros. This would be the first. Alternative: skip `@prep_miso`, manually write both `export` and the wrapper.

### Output convention for pre-anchor rows
- Use `NaN` (consistent with how other indicators handle warmup/lookback periods, e.g., SMA fills early rows with NaN via SMMA-style conventions). Actually, checking VWAP itself: it outputs 0.0 for zero-volume. But for "no data yet" semantics, NaN is more appropriate.
- Need to verify codebase convention -- check what other indicators output for pre-warmup rows.

---

## 8. Pre-warmup Output Convention (checked)

Looking at existing indicators:
- VWAP: outputs 0.0 when cum_v == 0 (but always starts from row 1, so this edge case is rare)
- SMA/EMA/etc: The raw Vector functions output values from row 1 (partial window). No NaN convention at the raw level.
- The TSFrame wrappers don't add NaN either.

**Conclusion:** The codebase does NOT use NaN for pre-warmup. Most indicators compute partial results from row 1. For Anchored VWAP, outputting 0.0 (or NaN) before anchor is a new pattern. NaN is semantically cleaner ("no value here"), but 0.0 is more consistent with existing VWAP behavior. This is a design decision to make.
