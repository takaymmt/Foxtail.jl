# Foxtail.jl Codebase Analysis for New Indicator Implementation

> Date: 2026-04-02
> Purpose: Comprehensive pattern reference for implementing new technical indicators

---

## 1. Directory Structure & File Organization

```
src/
  Foxtail.jl              # Module definition, exports tools, auto-includes indicators
  macro.jl                # @prep_siso, @prep_miso, @prep_simo, @prep_mimo macros + apply_ma()
  indicators/
    <IndicatorName>.jl    # One file per indicator (PascalCase filename)
  tools/
    CircBuff.jl           # Circular buffer (FIFO, fixed-size)
    CircDeque.jl          # Circular deque (double-ended)
    MinMaxQueue.jl        # Sliding window min/max (O(1) query, amortized O(1) update)

test/
  runtests.jl             # Test runner; loads all test files
  aapl.csv                # AAPL historical data for integration tests
  test_CircBuff.jl
  test_CircDeque.jl
  test_MinMaxQueue.jl
  test_Indicators_SISO.jl # Tests for single-input single-output indicators
  test_Indicators_MISO.jl # Tests for multi-input single-output indicators
  test_Indicators_SIMO.jl # Tests for single-input multi-output indicators
  test_Indicators_MIMO.jl # Tests for multi-input multi-output indicators
  test_Indicators_AAPL.jl # Regression tests against AAPL data with hardcoded expected values
```

### Key Conventions
- **One indicator per file**, named `<IndicatorName>.jl` in PascalCase
- **Auto-include**: `src/Foxtail.jl` auto-includes ALL `.jl` files in `src/indicators/` via `readdir`. No manual include needed.
- **Auto-export**: The `@prep_*` macros automatically `export` the indicator. No manual export needed.
- Tests are organized by macro type (SISO/MISO/SIMO/MIMO), NOT by indicator name.
- Total test count: ~4,115 tests.

---

## 2. Macro System (@prep_siso, @prep_miso, @prep_simo, @prep_mimo)

These macros generate TSFrame wrapper functions around the core numeric functions.

### 2.1 @prep_siso — Single Input Single Output

**Signature pattern:**
```julia
# Core function: Vector -> Vector
function IndicatorName(prices::Vector{Float64}; n::Int=14, ...) -> Vector{Float64}

# Macro generates TSFrame wrapper + export
@prep_siso IndicatorName n=14 ...
```

**What the macro generates:**
```julia
function IndicatorName(ts::TSFrame; n::Int=14, field::Symbol=:Close)
    prices = ts[:, field]
    results = IndicatorName(prices; n=n)
    return TSFrame(results, index(ts), colnames=[:IndicatorName_14])  # _n suffix when n present
end
export IndicatorName
```

**Column naming**: `Symbol(name, "_", n)` when `n` is present, otherwise just `Symbol(name)`.

**Examples:**
- `@prep_siso RSI n=14 ma_type=SMMA` — note Symbol params are unquoted
- `@prep_siso EMA n=10`
- `@prep_siso ROC n=14`

### 2.2 @prep_miso — Multiple Input Single Output

**Signature pattern:**
```julia
# Core function: Matrix -> Vector
function IndicatorName(prices::Matrix{Float64}; n::Int=14, ...) -> Vector{Float64}

# Macro: specify input fields as vector
@prep_miso IndicatorName [High, Low, Close] n=14 ...
```

**What the macro generates:**
```julia
function IndicatorName(ts::TSFrame; n::Int=14, fields::Vector{Symbol}=[:High, :Low, :Close])
    prices = ts[:, fields] |> Matrix
    results = IndicatorName(prices; n=n)
    return TSFrame(results, index(ts), colnames=[:IndicatorName_14])
end
export IndicatorName
```

**Examples:**
- `@prep_miso ATR [High, Low, Close] n=14 ma_type=EMA`
- `@prep_miso CCI [High, Low, Close] n=14`

### 2.3 @prep_simo — Single Input Multiple Output

**Signature pattern:**
```julia
# Core function: Vector -> Matrix
function IndicatorName(prices::Vector{Float64}; ...) -> Matrix{Float64}

# Macro: specify output suffixes as vector
@prep_simo IndicatorName [Suffix1, Suffix2, ...] param1=val1 ...
```

**What the macro generates:**
```julia
function IndicatorName(ts::TSFrame; field::Symbol=:Close, ...)
    prices = ts[:, field]
    results = IndicatorName(prices; ...)
    return TSFrame(results, index(ts), colnames=[:IndicatorName_Suffix1, :IndicatorName_Suffix2])
end
export IndicatorName
```

**Examples:**
- `@prep_simo BB [Center, Upper, Lower] n=14 num_std=2.0 ma_type=SMA`
- `@prep_simo MACD [Line, Signal, Histogram] fast=12 slow=26 signal=9`
- `@prep_simo KST [Line, Signal] r1=10 r2=13 r3=15 r4=20 s1=10 s2=13 s3=15 s4=20 signal=9`

### 2.4 @prep_mimo — Multiple Input Multiple Output

**Signature pattern:**
```julia
# Core function: Matrix -> Matrix
function IndicatorName(prices::Matrix{Float64}; ...) -> Matrix{Float64}

# Macro: specify both input fields and output suffixes
@prep_mimo IndicatorName [High, Low, Close] [Suffix1, Suffix2, ...] param1=val1 ...
```

**What the macro generates:**
```julia
function IndicatorName(ts::TSFrame; n::Int=14, fields::Vector{Symbol}=[:High, :Low, :Close])
    prices = ts[:, fields] |> Matrix
    results = IndicatorName(prices; n=n)
    return TSFrame(results, index(ts), colnames=[:IndicatorName_Suffix1, :IndicatorName_Suffix2])
end
export IndicatorName
```

**Examples:**
- `@prep_mimo Stoch [High, Low, Close] [K, D] n=14 k_smooth=3 d_smooth=3 ma_type=SMA`
- `@prep_mimo Aroon [High, Low] [Up, Down, Oscillator] n=25`
- `@prep_mimo DMI [High, Low, Close] [DIPlus, DIMinus, ADX] n=14`
- `@prep_mimo Supertrend [High, Low, Close] [Value, Direction] n=7 mult=3.0`

### 2.5 Special Case: Ichimoku

Ichimoku does NOT use a macro because its output has extra rows (displacement). It defines its own TSFrame wrapper manually and calls `export Ichimoku` explicitly.

---

## 3. Core Function Implementation Patterns

### 3.1 Standard Structure

Every indicator follows this pattern:

```julia
"""
    IndicatorName(prices::...; params...) -> Vector/Matrix

Detailed docstring with:
## Parameters
## Returns
## Formula (LaTeX math blocks)
## Interpretation
## Example
## See Also
"""
@inline Base.@propagate_inbounds function IndicatorName(prices::...; params...)
    # 1. Parameter validation
    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    # 2. Extract columns (for matrix input)
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    # 3. Core computation with @inbounds loops

    # 4. Return results
    return hcat(col1, col2, col3)  # for multi-output
    return result                   # for single-output
end

@prep_<type> IndicatorName [inputs] [outputs] params...
```

### 3.2 Key Coding Patterns

- **`@inline Base.@propagate_inbounds`**: Standard annotation for all indicator functions.
- **`@inbounds` blocks**: Used inside loops for performance.
- **`@view`**: Used for column extraction from matrices (avoids allocation).
- **`hcat(col1, col2, ...)`**: Standard way to combine multiple output columns.
- **`zeros(len)` / `zeros(len, ncols)`**: Pre-allocation pattern.
- **Parameter shadowing**: `period = n` is common (saves original `n` before `n` is reused as `length`).

### 3.3 Multi-output Return Pattern

All multi-output indicators return `Matrix{Float64}` via `hcat`:
```julia
return hcat(di_plus, di_minus, adx)  # DMI: 3 columns
return hcat(value, direction)         # Supertrend: 2 columns
return hcat(slow_k, slow_d)           # Stochastic: 2 columns
```

---

## 4. Available Building Blocks

### 4.1 Moving Averages (via `apply_ma`)

```julia
apply_ma(data::Vector{Float64}, ma_type::Symbol; n::Int) -> Vector{Float64}
```

Supported types: `:SMA`, `:EMA`, `:SMMA`/`:RMA`, `:WMA`

Internally calls `SMA()`, `EMA()`, `SMMA()`, `WMA()` — all accept `Vector{T}` and return `Vector{T}`.

### 4.2 Individual MA Functions (direct use)

| Function | Signature | Alpha |
|----------|-----------|-------|
| `SMA(data; n)` | `Vector{T} -> Vector{T}` | Simple average |
| `EMA(data; n)` | `Vector{T} -> Vector{T}` | `alpha = 2/(1+n)` |
| `SMMA(data; n)` | `Vector{T} -> Vector{T}` | `alpha = 1/n` (Wilder's) |
| `WMA(data; n)` | `Vector{T} -> Vector{T}` | Linear weights |

### 4.3 Stats Functions (MA + StdDev simultaneously)

| Function | Returns | Used By |
|----------|---------|---------|
| `SMA_stats(prices; n)` | Matrix `[mean, std]` | BollingerBands |
| `EMA_stats(data; n)` | Matrix `[mean, std]` | BollingerBands |
| `SMMA_stats(data; n)` | Matrix `[mean, std]` | BollingerBands |

### 4.4 TR (True Range)

```julia
TR(prices::Matrix{Float64}) -> Vector{Float64}
```
- Input: `[High, Low, Close]` matrix
- Returns: True Range vector
- Defined in `ATR.jl`
- Used by: ATR, DMI, Supertrend (via ATR), KeltnerChannel

### 4.5 ROC (Rate of Change)

```julia
ROC(prices::Vector{Float64}; n::Int=14) -> Vector{Float64}
```
- Returns percentage change: `(P[i] - P[i-n]) / P[i-n] * 100`
- First `n` values are 0.0
- Used by: KST

### 4.6 MinMaxQueue

```julia
mmq = MinMaxQueue{Float64}(capacity)
update!(mmq, high_val, low_val, index)
remove_old!(mmq, cutoff_index)  # removes indices <= cutoff
get_max(mmq)      # O(1) current max
get_min(mmq)      # O(1) current min
get_max_idx(mmq)  # index of max
get_min_idx(mmq)  # index of min
```

Used by: Stochastic, WilliamsR, Aroon, DonchianChannel, Ichimoku, SqueezeMomentum

### 4.7 CircBuff

```julia
buf = CircBuff{Float64}(capacity)
push!(buf, value)
first(buf)        # oldest element
last(buf)         # newest element
length(buf)
value(buf)        # view of current elements
```

Used by: SMA, WMA, SqueezeMomentum (_linreg_last)

### 4.8 Other Reusable Indicators

These can be called directly as building blocks:
- `ATR(prices::Matrix; n, ma_type)` — used by Supertrend, KeltnerChannel, SqueezeMomentum
- `EMA(data::Vector; n)` — used by MACD, DEMA, TEMA, HMA, KeltnerChannel, SqueezeMomentum
- `BB(prices::Vector; n, num_std, ma_type)` — used by SqueezeMomentum
- `KeltnerChannel(prices::Matrix; n, mult)` — used by SqueezeMomentum

---

## 5. Test Patterns

### 5.1 Test File Assignment by Macro Type

| Macro | Test File | Input Data |
|-------|-----------|------------|
| `@prep_siso` | `test_Indicators_SISO.jl` | `data_vec = collect(1.0:50.0)`, `small = [1.0..10.0]` |
| `@prep_miso` | `test_Indicators_MISO.jl` | `vec3 = hcat(high, low, close)`, `vec4 = hcat(high, low, close, vol)` |
| `@prep_simo` | `test_Indicators_SIMO.jl` | `data_vec = collect(1.0:50.0)`, `small = [1.0..10.0]` |
| `@prep_mimo` | `test_Indicators_MIMO.jl` | `vec2 = hcat(high, low)`, `vec3 = hcat(high, low, close)` |
| (regression) | `test_Indicators_AAPL.jl` | Real AAPL CSV data, hardcoded expected values |

### 5.2 Test Structure Per Indicator

Each indicator's test block follows this pattern:

```julia
@testset "IndicatorName" begin
    # 1. Type/shape checks (core function)
    @test IndicatorName(vec3) isa Matrix{Float64}  # or Vector

    # 2. TSFrame wrapper checks
    res = IndicatorName(data_ts)
    @test res isa TSFrame
    @test names(res)[1] == "IndicatorName_Suffix1"
    @test names(res)[2] == "IndicatorName_Suffix2"

    # 3. Parameter variation
    @test IndicatorName(data_ts; n=25) isa TSFrame
    @test IndicatorName(data_ts; ma_type=:EMA) isa TSFrame

    # 4. No NaN/Inf check
    result = IndicatorName(vec3)
    @test !any(isnan, result)
    @test !any(isinf, result)

    # 5. Numerical validation with known small data
    known_data = Float64[10 8 9; 11 9 10; ...]
    r = IndicatorName(known_data; n=3)
    @test r[1,1] ≈ expected_value atol=1e-8

    # 6. Range/bound checks
    @test all(v -> 0.0 <= v <= 100.0, result[:, 1])

    # 7. Behavioral checks (e.g., rising prices -> uptrend)
    rising = hcat([10.0+i for i in 1:30], ...)
    @test IndicatorName(rising)[end, 2] == 1.0  # uptrend

    # 8. AAPL smoke test
    aapl_result = IndicatorName(data_ts)
    @test aapl_result isa TSFrame
    @test size(aapl_result)[1] == size(data_ts)[1]

    # 9. Input validation (ArgumentError tests)
    @test_throws ArgumentError IndicatorName(rand(10, 2))  # wrong column count
    @test_throws ArgumentError IndicatorName(rand(10, 3); n=0)  # invalid param
end
```

### 5.3 AAPL Regression Tests (test_Indicators_AAPL.jl)

- Uses real AAPL data filtered to 2023-03-01 .. 2024-06-28 (335 rows)
- Tests with hardcoded expected values at specific indices (100, 200, 300, end)
- Includes canary check for dataset shape/values
- Spot checks + regression values for last N values

---

## 6. Implementation Checklist for New Indicators

### Step 1: Create `src/indicators/<Name>.jl`

1. Write comprehensive docstring (Parameters, Returns, Formula, Interpretation, Example, See Also)
2. Implement core function with `@inline Base.@propagate_inbounds`
3. Include `@inbounds` for inner loops
4. Add parameter validation (`throw(ArgumentError(...))`)
5. Add the appropriate `@prep_<type>` macro call at the end

### Step 2: Add Tests

1. Determine test file based on macro type (SISO/MISO/SIMO/MIMO)
2. Add `@testset` block following the standard pattern
3. Include: type checks, TSFrame checks, NaN/Inf checks, numerical validation, range checks, behavioral checks, input validation

### Step 3: (Optional) Add AAPL Regression Test

- Add to `test_Indicators_AAPL.jl` with hardcoded expected values

### Things NOT needed:
- No manual `include()` in `Foxtail.jl` (auto-included)
- No manual `export` statement (macro handles it)
- No changes to `runtests.jl` (test files already included)

---

## 7. Gotchas & Important Notes

1. **Parameter shadowing of `n`**: Many indicators do `period = n` at the start, then reuse `n = length(prices)`. Be careful with this pattern.

2. **Symbol parameters in macros**: In `@prep_*` calls, Symbol values are written without `:` prefix. E.g., `ma_type=SMMA` not `ma_type=:SMMA`.

3. **`field` parameter is special**: In `@prep_siso`/`@prep_simo`, `field` is consumed by the wrapper and NOT forwarded to the core function. Don't add `field` to the core function signature.

4. **`fields` keyword forbidden in MISO/MIMO**: The macros add `fields` automatically. Don't include it in params.

5. **No `n` parameter = no `_n` suffix**: Column names only get `_n` suffix when `n` is a parameter. If the indicator uses `fast`, `slow`, etc. instead of `n`, the column name is just the indicator name.

6. **Ichimoku is special**: It bypasses the macro system because its output has more rows than input. Manual TSFrame wrapper + manual export needed.

7. **Test data is deterministic**: Test files use fixed numeric arrays, NOT `rand()`. The 100-element arrays in MISO/MIMO tests are shared across all indicator testsets within that file.

8. **`atol` conventions**: Most numerical checks use `atol=1e-8` to `1e-10`. AAPL regression tests use `atol=1e-6`.

9. **`apply_ma` is the standard way** to provide configurable MA smoothing (supports SMA, EMA, SMMA/RMA, WMA).

10. **All indicators produce output of same length as input** (except Ichimoku). Leading values may be 0.0 or partially computed during warmup period.

---

## 8. Indicator Category Summary (45 implemented)

### SISO (Single In, Single Out) — 16 indicators
ALMA, DEMA, DPO, EMA, HMA, JMA, KAMA, NVI, OBV, PVI, ROC, RSI, SMA, SMMA, T3, TEMA, TMA, WMA, ZLEMA

### MISO (Multi In, Single Out) — 9 indicators
ADL, ATR, CCI, CMF, EMV, ForceIndex, MFI, VPT, VWAP

### SIMO (Single In, Multi Out) — 6 indicators
BB, KST, MACD, MACD3, PPO, StochasticRSI

### MIMO (Multi In, Multi Out) — 11 indicators
Aroon, DMI, DonchianChannel, Ichimoku*, KeltnerChannel, ParabolicSAR, SqueezeMomentum, Stochastic, Supertrend, WilliamsR

(*Ichimoku uses manual wrapper, not @prep_mimo)

---

## 9. Example: Complete Indicator Implementation (Pattern Reference)

### MIMO indicator with multiple params (Supertrend-style)

```julia
# src/indicators/NewIndicator.jl

"""
    NewIndicator(prices::Matrix{Float64}; n::Int=14, mult::Float64=2.0) -> Matrix{Float64}

[Docstring...]
"""
@inline Base.@propagate_inbounds function NewIndicator(prices::Matrix{Float64}; n::Int=14, mult::Float64=2.0)
    if size(prices, 2) != 3
        throw(ArgumentError("prices matrix must have 3 columns [High, Low, Close]"))
    end
    if n < 1
        throw(ArgumentError("period must be positive"))
    end

    len = size(prices, 1)
    highs = @view prices[:, 1]
    lows = @view prices[:, 2]
    closes = @view prices[:, 3]

    output1 = zeros(len)
    output2 = zeros(len)

    # ... core logic using existing building blocks ...
    atr_vals = ATR(prices; n=n)
    ema_vals = EMA(Vector(closes); n=n)

    @inbounds for i in 1:len
        # ... computation ...
    end

    return hcat(output1, output2)
end

@prep_mimo NewIndicator [High, Low, Close] [Output1, Output2] n=14 mult=2.0
```

### SIMO indicator composing existing functions (KST-style)

```julia
# src/indicators/NewSIMO.jl

function NewSIMO(prices::Vector{Float64}; n::Int=14, signal::Int=9)
    len = length(prices)

    rsi_vals = RSI(prices; n=n)
    signal_line = apply_ma(rsi_vals, :SMA; n=signal)

    results = zeros(len, 2)
    results[:, 1] = rsi_vals
    results[:, 2] = signal_line

    return results
end

@prep_simo NewSIMO [Line, Signal] n=14 signal=9
```
