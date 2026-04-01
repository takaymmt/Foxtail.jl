# TSFrames Usage Analysis in Foxtail.jl

**Date**: 2026-04-01
**Scope**: Comprehensive codebase analysis of TSFrames dependency

## 1. Project Overview

Foxtail.jl is a Julia package for technical analysis indicators (version 0.1.0-DEV).
It provides 24 indicator implementations organized as SISO/MISO/SIMO/MIMO patterns,
all built on top of TSFrames.jl for time series data handling.

- **Julia version**: 1.12.5 (from Manifest.toml)
- **Manifest format**: 2.0

## 2. TSFrames Dependency Declaration

### Project.toml

```toml
[deps]
TSFrames = "9f90e835-9451-4aaa-bcb1-743a1b8d2f84"

[compat]
TSFrames = "0.2.2"
```

**Pinned to exact version 0.2.2** (no `~` or `>=` — Julia treats `0.2.2` as `>=0.2.2, <0.3.0`).

### Manifest.toml Entry

```toml
[[deps.TSFrames]]
deps = ["Artifacts", "DataFrames", "Dates", "Random", "RecipesBase",
        "RollingFunctions", "ShiftedArrays", "Statistics", "StatsBase", "Tables"]
git-tree-sha1 = "4db6e77d1e4b85699846080491bc162b4f6df328"
uuid = "9f90e835-9451-4aaa-bcb1-743a1b8d2f84"
version = "0.2.2"
```

TSFrames 0.2.2 transitively brings in: DataFrames, Dates, Random, RecipesBase,
RollingFunctions, ShiftedArrays, Statistics, StatsBase, Tables, Artifacts.

## 3. Files Using TSFrames

### Direct `using TSFrames` Statements (2 files)

| File | Line | Statement |
|------|------|-----------|
| `src/Foxtail.jl` | 3 | `using TSFrames, LinearAlgebra` |
| `src/indicators/JMA.jl` | 92 | `using TSFrames` (redundant, already loaded by module) |
| `test/runtests.jl` | 2 | `using Test, CSV, TSFrames` |

### Files Using TSFrame Type via Macros (24 indicator files)

Every indicator file in `src/indicators/` uses one of the `@prep_*` macros, which
generate functions that accept `TSFrame` and return `TSFrame`. The macros are
defined in `src/macro.jl`.

## 4. TSFrames API Surface Used

The codebase uses a very **narrow slice** of the TSFrames API:

### Types
- `TSFrame` — the core time series type (used as function parameter type and return type)

### Constructors
- `TSFrame(data, index, colnames=[...])` — construct from data + index + column names

### Accessors
- `ts[:, field]` — column access by Symbol (returns Vector)
- `ts[:, fields] |> Matrix` — multi-column access piped to Matrix
- `index(ts)` — get the time index of a TSFrame
- `names(tsframe)` — get column names (used in tests only)

### External Functions (from CSV.jl)
- `CSV.read(path, TSFrame)` — read CSV directly into TSFrame (test only)

### Indexing
- `aapl[end-100:end]` — row range slicing (test only)

## 5. Macro-Generated TSFrame Wrappers

The `src/macro.jl` file defines 4 macros that auto-generate TSFrame wrapper functions:

| Macro | Pattern | Generated Signature | TSFrame Operations |
|-------|---------|--------------------|--------------------|
| `@prep_siso` | Single In, Single Out | `f(ts::TSFrame; field=:Close, ...)` | `ts[:, field]`, `TSFrame(result, index(ts), colnames=[...])` |
| `@prep_miso` | Multi In, Single Out | `f(ts::TSFrame; fields=[...], ...)` | `ts[:, fields] \|> Matrix`, `TSFrame(result, index(ts), colnames=[...])` |
| `@prep_simo` | Single In, Multi Out | `f(ts::TSFrame; field=:Close, ...)` | `ts[:, field]`, `TSFrame(result, index(ts), colnames=[...])` |
| `@prep_mimo` | Multi In, Multi Out | `f(ts::TSFrame; fields=[...], ...)` | `ts[:, fields] \|> Matrix`, `TSFrame(result, index(ts), colnames=[...])` |

All 24 indicators use these macros. The actual computation is done on raw `Vector{Float64}` or `Matrix{Float64}`, with TSFrame serving purely as an I/O wrapper.

### Indicator-to-Macro Mapping

**SISO (14 indicators)**: ALMA, DEMA, EMA, HMA, JMA, KAMA, RSI, SMA, SMMA, T3, TEMA, TMA, WMA, ZLEMA
**MISO (4 indicators)**: ADL, ATR, ChaikinOsc, OBV
**SIMO (4 indicators)**: BB, MACD, MACD3, StochRSI
**MIMO (2 indicators)**: Stoch, WR

## 6. Additional TSFrame Usage Outside Macros

Two files define TSFrame-accepting functions manually (not via macros):

1. **`src/indicators/SMMA.jl:61`** — `RMA(ts::TSFrame; ...)` alias that delegates to `SMMA(ts; ...)`
2. **`src/indicators/TMA.jl:42`** — `TRIMA(ts::TSFrame; ...)` alias that delegates to `TMA(ts; ...)`

These are simple one-line delegation wrappers.

## 7. Test File TSFrame Usage

`test/test_Indicators.jl`:
- Loads CSV data as TSFrame: `CSV.read(path, TSFrame)`
- Slices data: `aapl[end-100:end]`
- Tests return type: `@test result isa TSFrame`
- Checks column names: `@test names(result)[1] == "SMA_50"`

## 8. Key Observations for Migration

1. **Extremely narrow API surface**: Only 4-5 TSFrame operations are used across the
   entire codebase. Migration to a different time series library would primarily
   require changes to `src/macro.jl` (4 macros) plus 2 alias functions.

2. **Clean separation**: All core indicator computation is done on plain Julia arrays.
   TSFrame is only used as an I/O wrapper layer in the macro-generated functions.

3. **Redundant import in JMA.jl**: `src/indicators/JMA.jl` line 92 has `using TSFrames`
   which is unnecessary since `src/Foxtail.jl` already imports it at module scope.

4. **Version constraint**: `TSFrames = "0.2.2"` in `[compat]` means any version
   `>= 0.2.2` and `< 0.3.0` is acceptable per Julia's semver resolution.

5. **Migration bottleneck**: The 4 macros in `src/macro.jl` are the single point of
   change. All 24 indicator files would not need modification since they only use
   `@prep_*` macros and raw array computations.

6. **Test changes**: `test/runtests.jl` and `test/test_Indicators.jl` would need
   updates for CSV reading and type assertions if TSFrame type changes.

## 9. Dependency Tree Impact

TSFrames 0.2.2 brings in these transitive dependencies:
- DataFrames (heavy dependency)
- RollingFunctions
- ShiftedArrays
- RecipesBase
- StatsBase
- Statistics
- Tables
- Artifacts
- Dates, Random

Replacing TSFrames could significantly reduce the dependency tree if a lighter
alternative is used.

## 10. File Inventory

```
src/
  Foxtail.jl          -- Module entry, `using TSFrames`
  macro.jl             -- 4 macros generating TSFrame wrappers (KEY FILE)
  indicators/          -- 24 indicator files, all use @prep_* macros
    ALMA.jl, ATR.jl, ADL.jl, BollingerBands.jl, ChaikinOsc.jl,
    DEMA.jl, EMA.jl, HMA.jl, JMA.jl, KAMA.jl, MACD.jl, MACD3.jl,
    OBV.jl, RSI.jl, SMA.jl, SMMA.jl, Stochastic.jl, StochasticRSI.jl,
    T3.jl, TEMA.jl, TMA.jl, WilliamsR.jl, WMA.jl, ZLEMA.jl
  tools/               -- Utility data structures (no TSFrames usage)
    CircBuff.jl, CircDeque.jl, MinMaxQueue.jl
test/
  runtests.jl          -- `using TSFrames`
  test_Indicators.jl   -- Uses TSFrame type and CSV.read(path, TSFrame)
  test_CircBuff.jl     -- No TSFrames usage
  test_CircDeque.jl    -- No TSFrames usage
  test_MinMaxQueue.jl  -- No TSFrames usage
```
