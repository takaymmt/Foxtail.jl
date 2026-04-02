# Work Log: Researcher

## Summary

Conducted comprehensive research to answer the spike question: "Should Foxtail.jl prioritize adding more indicators vs. improving documentation?" Gathered evidence from web surveys, backtesting studies, comparable library analysis, and internal codebase assessment. Conclusion: **GO-B (Documentation Priority)** -- the library has achieved critical indicator coverage mass, but documentation gaps (outdated README, no published API docs, no quickstart) are the primary adoption barrier.

## Tasks Completed

### Task 1: Survey indicator popularity among professionals
- Searched for professional trader indicator rankings, hedge fund usage patterns, and backtesting studies
- Found quantitative backtesting data (100 years of Dow Jones): RSI 79.4% win rate, BB 77.8%, Donchian 74.1%, Ichimoku 1.77 return rate
- Confirmed institutional focus: VWAP, ADX, moving averages are universal in professional contexts
- Hedge funds use TA as one component among many (not sole basis), focusing on momentum, mean-reversion, and volume confirmation

### Task 2: Identify gaps -- what's NOT in Foxtail.jl
- Compared against TA-Lib (200 indicators), pandas-ta (150+), OnlineTechnicalIndicators.jl (57)
- Foxtail.jl covers ALL Tier 1 (8/8) and Tier 2 (12/12) professional indicators
- Remaining gaps are specialist: Anchored VWAP, TRIX, TSI, Coppock Curve, CMO, Chandelier Exit, Fisher Transform
- Candlestick patterns (60+ in TA-Lib) are a separate domain, out of scope

### Task 3: Evaluate documentation standards
- Analyzed OnlineTechnicalIndicators.jl docs: published via Documenter.jl, structured with quickstart + API reference + architecture
- Analyzed pandas-ta docs: published website, quickstart guide, category-organized API reference
- Analyzed TA-Lib docs: complete function reference, category-organized, no tutorials
- Assessed Foxtail.jl docs: excellent in-code docstrings but invisible; excellent adding-indicator.md; severely outdated README; no published API docs; no quickstart

### Task 4: Check existing survey in the project
- Read /Users/taka/proj/Foxtail.jl/.claude/docs/research/technical-indicators-survey.md
- All 7 "Critical Gaps" from the previous survey are now implemented (VWAP, ADX/DMI, Supertrend, Ichimoku, Parabolic SAR, Keltner Channel, Donchian Channel)
- All Phase 1 and Phase 2 recommendations are implemented
- Phase 3 partially done (ConnorsRSI, PivotPoints done; Anchored VWAP not done)

## Sources Consulted

### Indicator Popularity & Backtesting
- [NewTrading.io - Best Technical Indicators Tested Over 100 Years](https://www.newtrading.io/best-technical-indicators/)
- [QuantifiedStrategies - 100 Best Trading Indicators 2026](https://www.quantifiedstrategies.com/trading-indicators/)
- [QuantifiedStrategies - Best Indicators for Technical Analysis 2025](https://www.quantifiedstrategies.com/indicators-for-technical-analysis/)
- [Quadcode - Top 15 Technical Trading Indicators for 2025](https://quadcode.com/blog/top-10-technical-trading-indicators-for-2024)
- [TradeLink - Next-Generation Indicators 2025](https://tradelink.pro/blog/next-generation-indicators-what-top-traders-use-in-2025/)

### Institutional / Hedge Fund Usage
- [HedgeFundAlpha - Do Hedge Funds Use Technical Analysis](https://hedgefundalpha.com/investment-strategy/do-hedge-funds-use-technical-analysis/)
- [DayTrading.com - What Do Hedge Funds Think of Technical Analysis](https://www.daytrading.com/hedge-funds-technical-analysis)
- [TechnologyHQ - How Hedge Funds Really See TA in 2025](https://www.technologyhq.org/do-hedge-funds-use-technical-analysis/)

### Library Comparisons
- [TA-Lib - All Supported Functions](https://ta-lib.github.io/ta-lib-python/funcs.html)
- [pandas-ta PyPI](https://pypi.org/project/pandas-ta/)
- [pandas-ta API Overview](https://www.pandas-ta.dev/api/)
- [OnlineTechnicalIndicators.jl Docs](https://femtotrader.github.io/OnlineTechnicalIndicators.jl/dev/)
- [OnlineTechnicalIndicators.jl GitHub](https://github.com/femtotrader/OnlineTechnicalIndicators.jl)
- [Sling Academy - TA-Lib vs pandas-ta Comparison](https://www.slingacademy.com/article/comparing-ta-lib-to-pandas-ta-which-one-to-choose/)

### Documentation & Adoption
- [GitHub Open Source Survey 2017](https://opensourcesurvey.org/2017/) -- 93% cite incomplete docs as pervasive problem
- [GitHub Open Source Survey 2024](https://opensourcesurvey.org/2024/)
- [Jellyfish - Developer Experience Best Practices](https://jellyfish.co/library/developer-experience/best-practices/)
- [Draft.dev - Documentation Best Practices for Developer Tools](https://draft.dev/learn/documentation-best-practices-for-developer-tools)
- [GetDX - Developer Documentation Impact](https://getdx.com/blog/developer-documentation/)

### Specialist Indicators
- [TrendSpider - True Strength Index](https://trendspider.com/learning-center/true-strength-index/)
- [StockCharts - True Strength Index](https://chartschool.stockcharts.com/table-of-contents/technical-indicators-and-overlays/technical-indicators/true-strength-index)
- [QuantifiedStrategies - Anchored VWAP Trading Strategy](https://www.quantifiedstrategies.com/anchored-vwap-trading-strategy/)

## Evidence Collected (per sub-question)

### SQ1: Primary adoption barrier
- **Finding: Documentation is the primary barrier**
- README lists 26+ implemented indicators as "ToDos (not implemented yet)" -- severely misleading
- No published API docs; no quickstart tutorial
- 93% of developers cite incomplete/outdated documentation as a problem (GitHub Survey)
- Documentation is a top trust signal (34.2%) and top abandonment trigger (17.3%)
- All must-have indicators are already implemented

### SQ2: Professional workflow coverage
- **Finding: Excellent coverage of all major workflows**
- Trend-following, mean-reversion, momentum, volume analysis, volatility, breakout systems all well-covered
- 50 indicators comparable to OnlineTechnicalIndicators.jl (57) and covers ~60-65% of TA-Lib core
- Only missing Fibonacci (price-action pattern, not a computed indicator)

### SQ3: Must-have indicator gaps
- **Finding: No critical gaps remain**
- All Tier 1 + Tier 2 indicators (top 20 most popular) are implemented
- Remaining gaps: Anchored VWAP (medium demand), TRIX/TSI/Coppock (low-medium demand)
- None block professional adoption

### SQ4: Documentation sufficiency for professionals
- **Finding: Insufficient -- multiple critical gaps**
- README outdated (shows wrong state of library)
- No Documenter.jl-generated API docs
- No quickstart tutorial
- 5 recent indicators missing from reference
- Excellent in-code docstrings exist but are invisible without source reading

### SQ5: Investment ROI comparison
- **Finding: Documentation ROI is 5-10x higher than additional indicators**
- Fixing README: 1-2 hours, HIGH impact (correct first impression)
- Documenter.jl setup: 4-8 hours, HIGH impact (discoverable API)
- Adding specialist indicators: 10-20 hours, LOW impact (diminishing returns)

## Key Findings

1. **Foxtail.jl has achieved critical mass**: All 20 most important professional indicators are implemented. Adding more yields diminishing returns.

2. **Documentation is the clear bottleneck**: Outdated README, no published API docs, no quickstart tutorial. This creates a false impression the library is incomplete.

3. **README inaccuracy is the single most damaging issue**: A professional evaluating the library would incorrectly conclude it lacks VWAP, ADX, Ichimoku, Supertrend, etc. and move on.

4. **Highest ROI action**: Fix README + set up Documenter.jl + write quickstart (10-16 hours total) >> add 5+ specialist indicators (10-20 hours).

5. **Recommendation: GO-B** with minor HYBRID element (opportunistically add Anchored VWAP, TRIX, TSI).

## Issues Encountered

- Several web fetches returned 403 errors or raw HTML (ADTmag, CatchyAgency) -- worked around with alternative sources
- pandas-ta API page didn't list individual indicators on the overview page -- used PyPI and comparison articles instead
- GitHub's 2024 Open Source Survey focused on security/AI themes, not documentation specifically -- relied on 2017 survey (93% documentation statistic) which remains the most-cited data point
- Test run confirmed all 4,307 tests pass, verifying the 50-indicator implementation is solid
