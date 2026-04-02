# Security Review: AnchoredVWAP Implementation

**Date**: 2026-04-02
**Reviewer**: Security Reviewer (Opus subagent)
**Commit**: "feat: AnchoredVWAP を追加（51指標目）"
**Verdict**: **PASS** -- No critical or high-severity issues found.

---

## Files Reviewed

| File | Status | Lines |
|------|--------|-------|
| `src/indicators/AnchoredVWAP.jl` | NEW | 114 |
| `test/test_Indicators_MISO.jl` (AnchoredVWAP section) | MODIFIED | Lines 225-279 |
| `test/test_Indicators_AAPL.jl` (AnchoredVWAP section) | MODIFIED | Lines 354-385 |
| `Project.toml` | MODIFIED | Added `Dates` stdlib |
| `docs/indicator-reference.md` | MODIFIED | Added AnchoredVWAP entry |
| `README.md` | MODIFIED | Updated indicator count to 51 |

---

## Checklist Results

| Check | Result | Notes |
|-------|--------|-------|
| Hardcoded secrets or credentials | PASS | None found |
| Injection vulnerabilities | PASS | Pure math library, no I/O, no string interpolation into commands |
| Input validation | PASS | All invalid inputs properly caught (see details below) |
| Integer overflow / float edge cases | INFO | See Finding #1 (Low severity) |
| Memory safety / bounds checking | PASS | See analysis below |
| Sensitive data exposure in error messages | PASS | Error messages reveal only row counts and anchor values (non-sensitive) |
| Dependency safety | PASS | `Dates` is Julia stdlib, no supply-chain risk |
| Input mutation | PASS | No mutation of input data; uses `@view` for read-only access |

---

## Findings

### Finding #1: Floating-Point Accumulation Precision (Low)

- **Severity**: Low
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 56-64
- **Description**: The cumulative sums `cum_tpv` and `cum_v` are accumulated in a naive loop. For very long series (millions of rows) with large volume values, floating-point precision could degrade due to catastrophic cancellation in the running sum. This is a numerical accuracy concern, not a security vulnerability.
- **Impact**: Marginal precision loss over extremely long series. Not exploitable.
- **Recommendation**: This matches the existing `VWAP.jl` pattern (line 48-55) and is acceptable for the library's use case. If higher precision is ever needed, Kahan summation could be applied. No action required now.

### Finding #2: Zero-Volume Division Guard Returns 0.0 (Low / Informational)

- **Severity**: Low (Informational)
- **File**: `src/indicators/AnchoredVWAP.jl`, line 63
- **Description**: When cumulative volume is zero, the result is `0.0` rather than `NaN`. This is a deliberate design choice consistent with `VWAP.jl` (line 55). Zero-volume at the start of a series produces `0.0` which could mislead downstream consumers expecting `NaN` for "undefined" values.
- **Impact**: Functional, not security. Downstream code comparing against `NaN` for "no data" will not detect this case.
- **Recommendation**: Document the behavior. No change needed for consistency with existing VWAP.

### Finding #3: `@inbounds` Used After Validation (Informational / No Issue)

- **Severity**: Informational (No Issue)
- **File**: `src/indicators/AnchoredVWAP.jl`, lines 37, 59
- **Description**: `@propagate_inbounds` is used on the function signature, and `@inbounds` is used on the inner loop. In Julia, `@inbounds` disables bounds checking for performance. This is safe here because:
  1. The `anchor` parameter is validated at lines 44-46 to be within `[1, n]`.
  2. The loop range `anchor:n` is guaranteed within bounds of the pre-allocated `results` vector and the `@view` slices.
  3. The `@view` slices reference all rows (`data[:, k]`), so any index in `1:n` is valid.
- **Impact**: None. Bounds are correctly enforced before the unsafe region.
- **Recommendation**: No action needed. Pattern matches existing codebase conventions.

---

## Detailed Analysis

### Input Validation Coverage

The raw function (`Matrix{Float64}` signature) validates:
1. **Empty matrix**: `size(data, 1) == 0` --> `ArgumentError` (line 38-39)
2. **Wrong column count**: `size(data, 2) != 4` --> `ArgumentError` (line 41-42)
3. **Anchor out of range**: `anchor < 1 || anchor > size(data, 1)` --> `ArgumentError` (line 44-46)

The TSFrame wrapper adds:
4. **Date-based anchor not found**: `findfirst` returns `nothing` --> `ArgumentError` (line 79-80)
5. **Integer anchor out of range**: Duplicated check in `_anchored_vwap_resolve` (line 85-86)

**Assessment**: Input validation is thorough. All boundary conditions are tested (anchor=0, anchor=n+1, wrong columns, empty matrix, nonexistent date). The duplicate range check in `_anchored_vwap_resolve` is redundant but harmless (defense in depth).

### Type Safety

- The raw function accepts only `Matrix{Float64}`, preventing type confusion.
- The anchor parameter is typed as `Int`, preventing accidental float anchors.
- The TSFrame resolver uses `Union{Int, Dates.TimeType}`, which is appropriately restrictive.
- Julia's type system prevents passing strings or other types without explicit conversion.

### Memory Safety

- `@view data[:, k]` creates non-owning views into the input matrix -- no copies, no dangling references.
- `fill(NaN, n)` allocates a fresh output vector -- no aliasing with input.
- No manual memory management or unsafe pointer operations.

### No Side Effects

- Input `data` matrix is never modified (read-only views).
- Input `TSFrame` is never modified.
- No global state is read or written.
- No I/O operations (no file, network, or logging calls).
- No environment variable access.

### Dependency Analysis: `Dates` stdlib

- `Dates` is part of Julia's standard library, shipped with every Julia installation.
- No external network dependency, no supply-chain risk.
- Used only for `Dates.TimeType` in the anchor resolution function.
- `Project.toml` correctly lists it with its official UUID (`ade2ca70-3891-5945-98fb-dc099432e06a`).
- No compat entry needed for stdlib packages (Julia pins them to the runtime version).

### Error Message Review

All error messages reveal only:
- The anchor value provided by the caller (`$anchor`)
- The number of rows in the data (`$(size(data, 1))` or `$n`)

These are non-sensitive computational parameters. No credentials, paths, or internal state are exposed.

### Test Coverage for Security-Relevant Cases

| Case | Test Present | File |
|------|-------------|------|
| anchor=0 (below range) | Yes | MISO line 274 |
| anchor=n+1 (above range) | Yes | MISO line 275 |
| Wrong column count (3 cols) | Yes | MISO line 276 |
| Empty matrix | Yes | MISO line 277 |
| Nonexistent date | Yes | MISO line 278 |
| anchor=1 (matches VWAP) | Yes | MISO line 233, AAPL line 365 |
| anchor=last row | Yes | MISO line 260 |
| Mid-range anchor | Yes | AAPL line 369 |
| Date vs Int parity | Yes | MISO line 269-271, AAPL line 375-377 |
| Output range bounds check | Yes | AAPL lines 380-384 |

---

## Summary

The AnchoredVWAP implementation is **clean from a security perspective**. It is a pure mathematical function with no I/O, no external dependencies beyond Julia stdlib, thorough input validation, and comprehensive test coverage for boundary conditions. The two low-severity findings (floating-point accumulation and zero-volume behavior) are informational and consistent with the existing VWAP implementation in the codebase.

**No action items required.**
