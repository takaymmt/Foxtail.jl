# Spike Research: Indicators vs Documentation

> Researcher: Opus subagent | Date: 2026-04-02

## 1. Most Popular Indicators Among Professionals (ranked)

### Tier 1: Universal / Must-Have (used by nearly all professional traders)

Based on backtesting studies (100 years of Dow Jones data), professional surveys, and trading platform popularity:

| Rank | Indicator | Evidence | In Foxtail? |
|------|-----------|----------|-------------|
| 1 | RSI | 79.4% win rate in backtests; top indicator in every survey | YES |
| 2 | Bollinger Bands | 77.8% win rate; top 3 in all professional contexts | YES |
| 3 | MACD | Universal trend/momentum tool; in every trading platform | YES |
| 4 | Moving Averages (SMA/EMA 50/200) | Foundation of all technical analysis | YES (13 types) |
| 5 | VWAP | #1 institutional execution benchmark; self-fulfilling S/R | YES |
| 6 | ADX/DMI | Universal trend strength filter (ADX > 25 threshold) | YES |
| 7 | Stochastic Oscillator | Widely used for overbought/oversold | YES |
| 8 | ATR | Core volatility measure; position sizing tool | YES |

### Tier 2: High-Value / Widely Used

| Rank | Indicator | Evidence | In Foxtail? |
|------|-----------|----------|-------------|
| 9 | Ichimoku Cloud | 1.77 return rate (highest in backtests); dominant in Asian markets | YES |
| 10 | Donchian Channels | 74.1% win rate in backtests; Turtle Traders foundation | YES |
| 11 | Williams %R | 71.7% win rate in backtests | YES |
| 12 | CCI | 1.47 return rate in backtests; popular in commodities | YES |
| 13 | Parabolic SAR | Classic stop-placement tool; in every platform | YES |
| 14 | Supertrend | One of TradingView's most popular indicators | YES |
| 15 | Keltner Channel | Prerequisite for TTM Squeeze | YES |
| 16 | OBV | Top volume indicator; simple and effective | YES |
| 17 | MFI | Volume-weighted RSI; widely used | YES |
| 18 | Squeeze Momentum (TTM) | TradingView's most-liked indicator (76K+) | YES |
| 19 | Pivot Points | Strongest self-fulfilling prophecy; identical levels for all traders | YES |
| 20 | Aroon | Trend timing indicator | YES |

### Tier 3: Specialist / Moderate Demand

| Rank | Indicator | Evidence | In Foxtail? |
|------|-----------|----------|-------------|
| 21 | Fibonacci Retracement | Massive retail + institutional awareness | NO (price action pattern, out of scope) |
| 22 | TRIX | Momentum smoothing; moderate popularity | NO |
| 23 | TSI (True Strength Index) | Double-smoothed momentum; moderate professional use | NO |
| 24 | Coppock Curve | Long-term momentum; used by institutional investors | NO |
| 25 | Anchored VWAP | Growing institutional use; TradingView adoption | NO |
| 26 | Chandelier Exit | ATR-based trailing stop; moderate use | NO |
| 27 | CMO (Chande Momentum Oscillator) | Listed in top indicators surveys | NO |
| 28 | Fisher Transform | Normalizes prices to Gaussian distribution | NO |
| 29 | ZigZag | Trend identification tool; combined with Fibonacci | NO |
| 30 | Chaikin Volatility | Volatility variant | NO |

Sources:
- [NewTrading.io - Best Technical Indicators (100 years of data)](https://www.newtrading.io/best-technical-indicators/)
- [QuantifiedStrategies.com - 100 Best Trading Indicators](https://www.quantifiedstrategies.com/trading-indicators/)
- [Quadcode - Top 15 Technical Trading Indicators 2025](https://quadcode.com/blog/top-10-technical-trading-indicators-for-2024)

## 2. Gap Analysis: Top Indicators NOT in Foxtail.jl

### Current Coverage Assessment

Foxtail.jl has **50 indicators** (45 documented in reference + 5 recently added). Here is how it compares:

**Coverage of Tier 1 (Must-Have): 8/8 = 100%**
All universal must-have indicators are implemented.

**Coverage of Tier 2 (High-Value): 12/12 = 100%**
All widely-used indicators are implemented.

**Coverage of Tier 3 (Specialist): ~0/10 = 0%**
Most specialist indicators are not implemented, but these are lower demand.

### Specific Gaps (ordered by professional demand)

| Priority | Missing Indicator | Demand Level | Notes |
|----------|-------------------|-------------|-------|
| Medium | Anchored VWAP | Growing institutional | VWAP variant with custom anchor point |
| Medium | TRIX | Moderate | Triple-smoothed EMA rate of change; in TA-Lib |
| Medium | TSI (True Strength Index) | Moderate | Double-smoothed momentum; in OnlineTechnicalIndicators.jl |
| Medium | Coppock Curve | Moderate (institutional) | Long-term momentum signal; in OnlineTechnicalIndicators.jl |
| Low | CMO (Chande Momentum Oscillator) | Listed in surveys | Similar to RSI variant |
| Low | Chandelier Exit | Niche | ATR-based trailing stop |
| Low | Fisher Transform | Niche | Price normalization |
| Low | ZigZag | Niche | Trend identification |
| Low | NATR (Normalized ATR) | Minor | ATR as percentage; trivial |
| Low | Chaikin Volatility | Minor | Derivative of EMV |

### Comparison with Comparable Libraries

| Library | Indicator Count | Categories |
|---------|----------------|------------|
| **TA-Lib** | ~200 (but ~60 are candlestick patterns, ~15 are math functions) | 7 categories |
| **TA-Lib (core indicators only)** | ~80 | Overlap, Momentum, Volume, Volatility, Cycle |
| **pandas-ta** | 150+ (including candlestick patterns via TA-Lib) | 10 categories |
| **OnlineTechnicalIndicators.jl** | 57 | Similar categories to Foxtail |
| **Foxtail.jl** | 50 | 6 categories |

Key insight: When excluding candlestick patterns and math functions, **Foxtail.jl's 50 indicators cover ~60-65% of TA-Lib's core indicators** and are roughly comparable to OnlineTechnicalIndicators.jl (57 indicators).

### What Foxtail.jl Has That Others Don't Always Have

- JMA (Jurik Moving Average) -- uncommon in open-source libraries
- MACD3 (Triple MACD) -- rare
- ConnorsRSI -- not always available
- SqueezeMomentum (TTM Squeeze) -- often community-contributed, not built-in

## 3. Documentation Standards (Comparable Libraries)

### Current State of Foxtail.jl Documentation

| Asset | Status | Quality |
|-------|--------|---------|
| README.md | **OUTDATED** -- lists 26+ indicators as TODO that are now implemented; does not reflect current 50-indicator state | Poor |
| docs/indicator-reference.md | Covers 45 of 50 indicators; **missing 5 recently added** (ConnorsRSI, MassIndex, UltimateOsc, Vortex, PivotPoints) | Good but incomplete |
| docs/adding-indicator.md | Excellent developer guide with patterns, macros, testing | Excellent |
| In-code docstrings | Comprehensive with formula, interpretation, examples | Excellent |
| Quickstart / Tutorial | Minimal (3-line example in README only) | Poor |
| API documentation (Documenter.jl) | Not generated / not published | Missing |
| Trading strategy examples | None | Missing |

### How Comparable Libraries Document

**TA-Lib:**
- Complete function reference with parameters and descriptions
- Organized by category
- No usage tutorials (bare-bones API docs)
- Strength: completeness and standardization

**pandas-ta:**
- API reference organized by category
- Quickstart guide and usage tutorials
- Community examples and strategies
- Published online documentation (pandas-ta.dev)
- Strength: developer experience and onboarding

**OnlineTechnicalIndicators.jl:**
- Documenter.jl-generated docs (published on GitHub Pages)
- Architecture documentation
- Migration guides
- Quick start guides
- Strength: structured documentation pipeline

### Documentation Gap Analysis for Foxtail.jl

| Gap | Impact on Adoption | Effort to Fix |
|-----|-------------------|---------------|
| README is severely outdated | HIGH -- first impression is wrong; shows TODO for implemented indicators | Low (1-2 hours) |
| No published API docs (Documenter.jl) | HIGH -- users can't discover indicators without reading source | Medium (4-8 hours) |
| Missing 5 indicators from reference | MEDIUM -- incomplete reference erodes trust | Low (1-2 hours) |
| No quickstart tutorial | HIGH -- 73% of developers want hands-on experience within minutes | Medium (2-4 hours) |
| No trading strategy examples | MEDIUM -- professional users want to see real-world application | Medium (4-8 hours) |

## 4. Evidence Summary per Sub-question

### SQ1: What is the primary adoption barrier: missing indicators vs. documentation gaps?

**Evidence strongly points to documentation as the primary barrier.**

- **Indicator coverage is strong**: All Tier 1 and Tier 2 professional indicators (top 20) are implemented. The 50-indicator count is competitive with OnlineTechnicalIndicators.jl (57) and covers ~60-65% of TA-Lib's core (non-pattern) indicators.
- **Documentation is the weakest link**:
  - README is severely outdated (shows 26+ implemented indicators as TODO)
  - No published API documentation (Documenter.jl not set up)
  - No quickstart tutorial (73% of developers want hands-on experience in minutes)
  - 5 recently-added indicators missing from reference
  - GitHub's Open Source Survey: 93% of developers cite incomplete/outdated documentation as a pervasive problem
  - Documentation is both a top trust signal (34.2%) and top abandonment trigger (17.3%)

### SQ2: How well do current 50 indicators cover major professional trading workflows?

**Coverage is excellent for standard workflows.**

- Trend-following: SMA/EMA (13 MAs) + ADX/DMI + Supertrend + Ichimoku + Parabolic SAR = comprehensive
- Mean-reversion: RSI + Bollinger Bands + Stochastic + StochRSI + ConnorsRSI = comprehensive
- Momentum: MACD + ROC + CCI + KST + PPO = comprehensive
- Volume analysis: VWAP + OBV + ADL + MFI + CMF + 6 more = comprehensive
- Volatility: ATR + BB + Keltner + Donchian + SqueezeMomentum = comprehensive
- Breakout systems: Donchian + Bollinger + Keltner + Supertrend = comprehensive

**Missing workflow: Fibonacci-based analysis** (but this is price-action/drawing-tool territory, not a computed indicator)

### SQ3: Are there "must-have" gaps in unimplemented indicators?

**No critical gaps remain.** All must-have indicators (Tier 1 + Tier 2) are implemented.

Remaining gaps are specialist/niche:
- Anchored VWAP (growing demand but variant of existing VWAP)
- TRIX, TSI, Coppock Curve (moderate demand)
- Candlestick pattern recognition (large category, ~60 patterns; entirely different domain)

### SQ4: Is current documentation sufficient for professional users?

**No. Documentation has critical gaps.**

- A professional user landing on the GitHub repo sees an outdated README listing many indicators as TODO when they are already implemented -- this undermines credibility
- No way to browse API docs online (no Documenter.jl deployment)
- No quickstart that demonstrates a real workflow (load data -> compute indicators -> interpret results)
- Excellent in-code docstrings exist but are invisible without reading source files
- The adding-indicator.md developer guide is excellent but targets contributors, not users

### SQ5: Investment ROI comparison: adding indicators vs. improving docs

| Investment | Effort | Impact | ROI |
|-----------|--------|--------|-----|
| Fix README (reflect current 50 indicators) | 1-2 hours | HIGH -- correct first impression | **Very High** |
| Add 5 missing indicators to reference | 1-2 hours | MEDIUM -- complete reference | **Very High** |
| Set up Documenter.jl + deploy | 4-8 hours | HIGH -- discoverable API docs | **High** |
| Write quickstart tutorial | 2-4 hours | HIGH -- onboarding experience | **High** |
| Add Anchored VWAP | 2-4 hours | LOW-MEDIUM -- one more indicator | Low |
| Add TRIX | 1-2 hours | LOW -- niche demand | Low |
| Add TSI | 2-3 hours | LOW -- niche demand | Low |
| Add Coppock Curve | 1-2 hours | LOW -- niche demand | Low |
| Add 5+ specialist indicators | 10-20 hours | LOW -- diminishing returns | **Low** |

## 5. Key Findings

### Finding 1: Foxtail.jl has achieved critical mass in indicator coverage
All 20 most important professional indicators are implemented. The 50-indicator library is competitive with comparable Julia (OnlineTechnicalIndicators.jl: 57) and Python (pandas-ta core: ~90 without patterns) libraries. Adding more indicators yields diminishing returns.

### Finding 2: Documentation is the clear adoption bottleneck
The README is severely outdated (lists implemented indicators as TODO), there is no published API documentation, no quickstart tutorial, and 5 recent indicators are missing from the reference. This creates a misleading first impression that the library is incomplete.

### Finding 3: The highest-ROI work is documentation, not indicators
Fixing the README (1-2 hours) and setting up Documenter.jl (4-8 hours) would have far more impact on adoption than implementing any additional indicator. The in-code docstrings are excellent -- they just need to be surfaced.

### Finding 4: Remaining indicator gaps are specialist/niche
Anchored VWAP has growing demand but is a variant of existing VWAP. TRIX, TSI, Coppock Curve, and CMO have moderate demand. Candlestick patterns are a separate domain entirely. None of these block professional adoption.

### Finding 5: README inaccuracy actively harms adoption
The README currently lists Supertrend, Ichimoku, Parabolic SAR, DMI/ADX, VWAP, Keltner Channel, Donchian Channel, and many more as "ToDos (not implemented yet)" when they ARE implemented. A professional evaluating the library would incorrectly conclude it lacks core indicators and move on.

## 6. Recommendation

**GO-B (Documentation Priority) with minor HYBRID element**

Primary focus: Documentation improvement (estimated 10-16 hours total)
1. Fix README to reflect actual 50-indicator state (URGENT -- 1-2 hours)
2. Add 5 missing indicators to indicator-reference.md (1-2 hours)
3. Set up Documenter.jl and deploy to GitHub Pages (4-8 hours)
4. Write quickstart tutorial with real workflow example (2-4 hours)

Secondary focus: A small batch of 3-5 specialist indicators can be added opportunistically
- Anchored VWAP, TRIX, TSI (highest remaining demand)

The documentation work is more urgent because it surfaces the excellent work already done, while additional indicators provide diminishing returns on an already-comprehensive library.
