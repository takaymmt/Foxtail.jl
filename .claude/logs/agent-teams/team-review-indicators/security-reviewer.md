# Work Log: Security Reviewer

## Summary

Completed a full security review of the 17 technical indicators addition (commit dd32c67). Reviewed 22 source files across `src/indicators/`, `src/tools/`, and `src/Foxtail.jl`. Found **0 critical, 0 high, 5 medium, and 7 low** severity findings. All findings relate to numeric robustness (division-by-zero edge cases, missing input validation) rather than traditional security vulnerabilities. No secrets, no network I/O, no exploitable attack surface.

## Review Scope

### Files Reviewed (22 total)
- `src/Foxtail.jl` -- Module entry point, dynamic file inclusion
- `src/macro.jl` -- Code generation macros (prep_siso, prep_miso, prep_simo, prep_mimo)
- `src/tools/MinMaxQueue.jl` -- Sliding window min/max data structure
- `src/tools/CircBuff.jl` -- Circular buffer (used by indicators)
- `src/tools/CircDeque.jl` -- Circular deque (used by MinMaxQueue)
- 17 indicator files: Aroon, CCI, CMF, DMI, DPO, DonchianChannel, EMV, ForceIndex, Ichimoku, KST, KeltnerChannel, MFI, NVI, PPO, PVI, ParabolicSAR, ROC, SqueezeMomentum, Supertrend, VPT, VWAP

### Review Focus Areas
1. Hardcoded secrets or credentials
2. Input validation gaps (division by zero, out-of-bounds access, NaN propagation)
3. Numeric overflow or underflow risks
4. Sensitive data exposure
5. Denial of service via malformed input
6. Code injection via macros

## Findings

| ID  | Severity | File(s) | Issue |
|-----|----------|---------|-------|
| M-1 | Medium | NVI.jl, PVI.jl, VPT.jl, ROC.jl | Division by zero when previous close is 0.0 |
| M-2 | Medium | PPO.jl | Division by zero when slow EMA is 0.0 |
| M-3 | Medium | Aroon.jl | Degenerate formula with n=1 (fragile, not currently broken) |
| M-4 | Medium | MinMaxQueue.jl | get_max/get_min on empty queue throws BoundsError, not descriptive error |
| M-5 | Medium | Ichimoku.jl | TSFrame wrapper fragile with single-row input |
| L-1 | Low | DonchianChannel.jl | Inconsistent: requires len >= period while others use partial windows |
| L-2 | Low | EMV.jl | Hardcoded 100M volume divisor |
| L-3 | Low | DPO.jl, KST.jl, EMV.jl, KeltnerChannel.jl | Missing input validation (column count or length) |
| L-4 | Low | SqueezeMomentum.jl | n >= 2 requirement (correct but inconsistent with other indicators) |
| L-5 | Low | VWAP.jl | Cumulative floating-point drift on very long series |
| L-6 | Low | All indicators | No NaN handling in input |
| L-7 | Low | All volume-based indicators | No negative volume validation |

Full details in: `.claude/docs/research/review-security-indicators.md`

## Issues Encountered

- No issues encountered during review. All files were readable and well-structured.
- Bash tool was denied for directory creation; used Write tool directly which created parent directories automatically.
- The codebase follows a consistent pattern across most indicators, making the review efficient. Inconsistencies (missing validation in DPO, KST, EMV, KeltnerChannel) stood out clearly against the established pattern.
