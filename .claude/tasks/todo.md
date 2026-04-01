# Foxtail.jl — Implementation TODO

> Created: 2026-04-01 | Last updated: 2026-04-01
> Based on: market impact survey + codebase architecture analysis

## Progress: 17 indicators implemented this session (3702 tests passing)

## Priority Rationale

Rankings combine two factors:
- **Market Impact**: self-fulfilling prophecy strength, institutional adoption, TradingView usage
- **Implementation Ease**: code complexity, reuse of existing building blocks (EMA, ATR, MinMaxQueue)

## Phase 1 — Critical ✅ COMPLETE

- [x] **VWAP** — `@prep_miso [High, Low, Close, Volume]`
- [x] **Supertrend** — `@prep_mimo [High,Low,Close] → [Value, Direction]`
- [x] **Keltner Channel** — `@prep_mimo [High,Low,Close] → [Middle, Upper, Lower]`
- [x] **ADX / DMI** — `@prep_mimo [High,Low,Close] → [DIPlus, DIMinus, ADX]`
- [x] **Donchian Channel** — `@prep_mimo [High,Low,Close] → [Upper, Lower, Middle]`
- [x] **ROC** — `@prep_siso`

## Phase 2 — Trend Systems ✅ COMPLETE

- [x] **Parabolic SAR** — `@prep_mimo [High,Low] → [Value, Direction]`
- [x] **Ichimoku Cloud** — manual TSFrame wrapper; N+26 row output; `[Tenkan, Kijun, SenkouA, SenkouB, Chikou]`
- [x] **CCI** — `@prep_miso [High,Low,Close]`
- [x] **Aroon** — `@prep_mimo [High,Low] → [Up, Down, Oscillator]` (required MinMaxQueue extension)
- [x] **PPO** — `@prep_simo → [Line, Signal, Histogram]`

## Phase 3 — Volume & Money Flow ✅ COMPLETE

- [x] **MFI** — `@prep_miso [High,Low,Close,Volume]`
- [x] **CMF** — `@prep_miso [High,Low,Close,Volume]`
- [x] **Force Index** — `@prep_miso [Close,Volume]`
- [x] **VPT** — `@prep_miso [Close,Volume]`
- [x] **NVI / PVI** — `@prep_miso [Close,Volume]` (×2)
- [x] **KST** — `@prep_simo → [Line, Signal]`
- [x] **EMV** — `@prep_miso [High,Low,Volume]`

## Phase 4 — New Indicators (from survey) ✅ COMPLETE

- [x] **Squeeze Momentum (TTM Squeeze)** — `@prep_mimo [High,Low,Close] → [Histogram, Squeeze]`

## Phase 5 — Low Priority / Remaining

- [ ] **Pivot Points** (Standard/Fibonacci/Woodie/Camarilla/DM) ★★★★
  - Design: function reads previous row's OHLC; user pre-aggregates for weekly/monthly
  - Needs `@prep_mimo [High,Low,Close,Open] → [Pivot, R1, R2, R3, S1, S2, S3]`
  - Multiple method support via `method::Symbol` parameter

- [ ] **Connors RSI** ★★★
  - `@prep_siso` — composite of RSI(3) + StreakRSI(2) + %Rank(ROC(1), 100)
  - Needs: streak calculation helper + rolling percentile rank helper

- [ ] **Vortex Indicator** ★★
  - `@prep_mimo [High,Low,Close] → [VIPlus, VIMinus]`
  - Uses TR() (available)

- [ ] **Mass Index** ★
  - `@prep_miso [High,Low]`
  - Σ(EMA(range, 9) / EMA(EMA(range, 9), 9))

- [ ] **Ultimate Oscillator** ★★
  - `@prep_miso [High,Low,Close]`
  - 3-timeframe buying pressure / TR ratios

- [ ] **DPO** ★ — `@prep_siso` ✅ DONE (implemented in Phase 3 batch)

## Infrastructure Changes Made

- `MinMaxQueue`: added `get_max_idx()` / `get_min_idx()` (Aroon対応)
- `src/Foxtail.jl`: exported the new MinMaxQueue functions
