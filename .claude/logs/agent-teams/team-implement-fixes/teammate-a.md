# Teammate-A Work Log

## Files Owned
- `src/indicators/MFI.jl`
- `src/indicators/CMF.jl`

## Task 1: Fix misleading comment in MFI.jl (line 83)

**Problem**: Comment said `"tp[j] == tp[j-1] or j == 1: both remain 0.0 (neutral)"` but the loop starts at `j=2`, so `j == 1` never occurs inside the loop body. The `j == 1` case is handled by `pos_mf`/`neg_mf` being initialized as `zeros(nrows)`.

**Fix**: Split the comment into two lines:
- `# tp[j] == tp[j-1]: both remain 0.0 (neutral)`
- `# Note: j == 1 is not reached here; pos_mf[1]/neg_mf[1] stay 0.0 from initialization`

## Task 2: FP drift protection in MFI.jl sliding window

**Problem**: `pos_flow` and `neg_flow` running sums can theoretically go slightly negative due to floating-point accumulation errors over very long series.

**Fix**: Added clamping after the add/subtract update and before the ratio calculation:
```julia
pos_flow = max(0.0, pos_flow)
neg_flow = max(0.0, neg_flow)
```

Location: lines 101-103 (after subtract block, before the if/elseif ratio logic).

## Task 3: FP drift protection in CMF.jl sliding window

**Problem**: `sum_vol` running sum could theoretically drift to slightly negative via FP accumulation. The zero-guard used `== 0.0` which would miss negative values.

**Fix**:
1. Added `sum_vol = max(0.0, sum_vol)` after the subtract block (line 89).
2. Changed zero-guard from `sum_vol == 0.0` to `sum_vol <= 0.0` (line 91) as belt-and-suspenders defense.
   - Note: `sum_mfv` was NOT clamped since it can legitimately be negative.

## Verification

All 4111 tests pass:
```
Test Summary: | Pass  Total   Time
Foxtail.jl    | 4111   4111  15.8s
     Testing Foxtail tests passed
```
