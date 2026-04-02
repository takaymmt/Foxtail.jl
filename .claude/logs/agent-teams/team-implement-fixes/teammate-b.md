# Teammate-B Work Log

## File Ownership
- test/test_Indicators_MISO.jl

## Tasks Completed

### Task 1: EMV zero-division edge case tests
- Added two edge case tests inside the existing EMV testset (lines 695-714):
  - **Test A**: High == Low (hl_diff = 0) -- verifies no NaN/Inf when box_ratio denominator is zero
  - **Test B**: Volume == 0 (box_ratio = 0) -- verifies no NaN/Inf when volume is zero

### Task 2: MFI both-flows-zero test
- Added constant typical-price edge case test inside the existing MFI testset (lines 398-403):
  - All 10 bars have identical H/L/C values, so TP never changes
  - Verifies no NaN/Inf and that MFI returns 100.0 for every bar (neutral convention when both flows are zero)

### Task 3: CCI tautology fix
- **Found tautology at line 248** (originally):
  ```julia
  @test any(x -> x > 0.0, r) || any(x -> x < 0.0, r) || all(x -> x ≈ 0.0, r)
  ```
  This is always true: every set of real numbers is either has a positive element, has a negative element, or is all zeros. The three disjuncts are an exhaustive partition.
- **Replaced with meaningful assertion**:
  ```julia
  @test any(x -> x > 0.0, r) && any(x -> x < 0.0, r)
  ```
  For the oscillating `small_hlc` data (TP = [2,5,3,6,4]), CCI must produce both positive and negative values. The `&&` (conjunction) actually tests a property of the output.

## Verification
- Ran `julia --project=. -e "using Pkg; Pkg.test()"` -- all 4115 tests pass.
