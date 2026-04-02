# Spike Report: Indicators vs Documentation — Foxtail.jl

## Question
Should Foxtail.jl prioritize adding more technical indicators favored by professional/experienced traders, OR improving documentation quality?

## Verdict: GO-B (Documentation Priority)
**Confidence**: HIGH  
**Decisive factor**: READMEの重大な誤記と文書不足により、実装済みの競争力が市場に対してほぼ不可視になっている。

## Investigation Parameters
- Time budget: ~60 minutes
- Mode: RESEARCH-ONLY
- Date: 2026-04-02
- Team: Researcher (Opus) + Feasibility Analyst (Codex)

---

## Success Criteria Evaluation

| Criterion | Evidence | Met? |
|-----------|----------|------|
| GO-A: Must-have gaps block adoption | Top-20指標は全て実装済み。ワークフロー8.5/10カバー | NO |
| GO-B: Docs are the bottleneck | README誤記・workflow guideゼロ・validation例なし | YES |
| HYBRID: Both gaps, docs > indicators | Anchored VWAPのみ実需ギャップ。ROI比は3-10x docs優位 | PARTIAL |

---

## Sub-question Findings

### SQ1: Primary adoption barrier
- **Finding**: ドキュメント不備（README誤記が特に深刻）
- **Evidence**: 実装済み26+指標が "ToDo (not implemented yet)" として誤表示。外部評価者が誤判断する
- **Assessment**: Documentation bottleneck confirmed

### SQ2: Workflow coverage of current 50 indicators
- **Finding**: 8.5/10スコア。主要ワークフロー10中7つがFULL coverage
- **Evidence**: Trend-following, Mean-reversion, Momentum, Volume confirmation, Breakout, Volatility全て対応
- **Assessment**: SUFFICIENT — 指標充足期に到達

### SQ3: Must-have indicator gaps
- **Finding**: 実質的な必須欠落はなし
- **Evidence**: 残ギャップはAnchored VWAP（一定需要）、TRIX/TSI/Coppock Curve（ニッチ）のみ
- **Assessment**: NO BLOCKING GAPS

### SQ4: Documentation sufficiency
- **Finding**: 不十分 — 複数の重大欠陥あり
- **Evidence**:
  - README: 実装済み指標を未実装と誤記
  - indicator-reference.md: 最近追加5指標が未反映
  - workflow guide: ゼロ
  - TA-Lib検証例: ゼロ
  - migration guide: ゼロ
- **Assessment**: CRITICAL GAPS — highest priority

### SQ5: ROI comparison
- **Finding**: ドキュメント改善のROIが3-10x高い
- **Evidence**: GitHub survey「93%が不完全ドキュメントを問題視」。docs修正10-16時間=HIGH impact vs 指標追加10-20時間=LOW impact（逓減）

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| README誤記が新規ユーザーを誤誘導 | HIGH | HIGH | 最優先で修正 |
| 指標数で競合(OnlineTechnicalIndicators: 57)に見劣り | MEDIUM | LOW | docs改善でカバー |
| workflow guide作成に時間がかかる | MEDIUM | MEDIUM | まずREADME修正から着手 |
| Anchored VWAP需要が実は高い | LOW | MEDIUM | docs改善後に再評価 |

---

## Architecture Compatibility
- Assessment: COMPATIBLE — 既存ドキュメント構造（indicator-reference.md）を拡張する方向
- Required changes: README全面改訂, indicator-reference.md更新, 新規ページ追加(workflow guides, validation)
- Migration Complexity: LOW（コード変更なし）

---

## Alternatives Considered

| Alternative | Pros | Cons | Verdict |
|-------------|------|------|---------|
| 指標追加優先(GO-A) | 数字上の充実 | 逓減リスク高・docs問題は残る | REJECT |
| ドキュメント優先(GO-B) | ROI高・trust gap解消 | 指標数で見劣りリスク | **RECOMMENDED** |
| ハイブリッド(20/80) | バランス | 集中力が分散 | GO-B達成後に検討 |

---

## Recommendation: GO-B

現状の採用ボトルネックは機能不足ではなく「見え方・信頼性・導入容易性」の不足。
Foxtail.jlは「もっと指標を足さないと使われない」段階ではなく、「既にある強みがドキュメント不備で正しく伝わっていない」段階。

### Priority Actions (ordered)

1. **URGENT — 1-2h**: `README.md` 全面改訂 — 誤記修正・50指標反映・現状の強みを正しく伝える
2. **URGENT — 1-2h**: `indicator-reference.md` 更新 — 5指標(ConnorsRSI, MassIndex, UltimateOsc, Vortex, PivotPoints)を追加
3. **HIGH — 2-4h**: quickstart tutorial追加 — 実データで5分で動く例
4. **HIGH — 3-5d**: workflow guides作成 — trend-following / mean-reversion / breakout / momentum
5. **HIGH — 2-3d**: TA-Lib検証例追加 — trust gap解消（プロ向け信頼性の核心）
6. **MEDIUM — 2-3d**: migration guide追加 — pandas-ta/TA-Lib比較表
7. **LOW — 再評価**: Anchored VWAP実装 — docs改善後に需要再評価してから着手

### Key constraints to carry forward
- README修正なしでは以降の実装追加も評価されにくい（最優先）
- API doc整備だけでは不十分：workflow guide + validation までセットで信頼形成
- `Anchored VWAP` はdocs改善後に独立したスパイクで再評価を推奨

---

## Source Files
- Research: `.claude/docs/research/spike-indicators-vs-docs-research.md`
- Feasibility: `.claude/docs/research/spike-indicators-vs-docs-feasibility.md`
- Logs: `.claude/logs/agent-teams/spike-indicators-vs-docs/`
