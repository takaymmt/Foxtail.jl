# Foxtail.jl — Task List

> Last updated: 2026-04-02
> Decision basis: Spike "Indicators vs Documentation" (GO-B, confidence: HIGH)
> Full spike report: `.claude/docs/research/spike-indicators-vs-docs.md`

---

## Active Sprint: Documentation Improvement

### 🔴 URGENT (do first)

- [x] **README.md 全面改訂** ✅ 2026-04-02
  - 誤記修正、50指標の正確な反映、ToDoリスト削除
  - 新構成: Features / Installation / Quick Start / Supported Indicators（7カテゴリ表）

- [x] **indicator-reference.md に5指標追加** ✅ 2026-04-02
  - ConnorsRSI, MassIndex, UltimateOscillator, Vortex, PivotPoints を追加
  - Summary Table・詳細セクション・各参照テーブルを全て更新、指標番号を1-50に振り直し

### 🟡 HIGH (次のスプリント)

- [ ] **quickstart tutorial 追加**
  - 実データ（ランダム or AAPL）で5分以内に動く例
  - 複数指標の組み合わせを1つのワークフロー例として示す
  - 工数目安: 2-4h

- [ ] **TA-Lib 検証例ページ追加**
  - RSI / MACD / Bollinger Bands を TA-Lib リファレンス値と照合する例
  - プロ向けの信頼性 (trust gap) 解消が目的
  - 工数目安: 2-3d

- [ ] **workflow guides 作成**
  - Trend-following ワークフロー（EMA + DMI + ATR）
  - Mean-reversion ワークフロー（BB + RSI + volume）
  - Breakout ワークフロー（Donchian + ATR + OBV）
  - Momentum ワークフロー（MACD + RSI + MFI）
  - 工数目安: 3-5d

### 🟢 MEDIUM (その後)

- [ ] **migration guide 追加**
  - pandas-ta / TA-Lib からの移行チートシート
  - 指標名マッピング + パラメータ対応表
  - 工数目安: 2-3d

- [ ] **indicator comparison tables**
  - 同カテゴリ内でどれを選ぶか（例: MACD vs PPO vs KST for momentum）
  - 工数目安: 1-2d

---

## Deferred (保留)

### 指標追加（docs改善後に再検討）

- [ ] **Anchored VWAP** ★★★ — 唯一の実需ギャップ。docs改善後に需要を再評価してから着手
- [ ] **TRIX** ★★ — ニッチ。後回し可
- [ ] **TSI (True Strength Index)** ★★ — ニッチ。後回し可
- [ ] **Coppock Curve** ★ — ニッチ。後回し可

### インフラ・その他

- [ ] **Documenter.jl セットアップ + GitHub Pages デプロイ**
  - 優先度はworkflow guides完成後
  - 工数目安: 4-8h

---

## Completed ✅

### 指標実装（50指標）

#### Moving Averages (13)
- [x] ALMA, DEMA, EMA, HMA, JMA, KAMA, SMA, SMMA, T3, TEMA, TMA, WMA, ZLEMA

#### Trend (7)
- [x] Aroon, DMI/ADX, DonchianChannel, Ichimoku, KeltnerChannel, ParabolicSAR, Supertrend

#### Momentum (9)
- [x] CCI, DPO, KST, MACD, MACD3, PPO, ROC, RSI, StochRSI

#### Oscillators (3)
- [x] Stoch, WR, SqueezeMomentum

#### Volume (11)
- [x] ADL, ChaikinOsc, CMF, EMV, ForceIndex, MFI, NVI, OBV, PVI, VPT, VWAP

#### Volatility (2)
- [x] ATR, BB

#### Recent additions (5)
- [x] ConnorsRSI, MassIndex, UltimateOscillator, Vortex, PivotPoints

### インフラ
- [x] MinMaxQueue: `get_max_idx()` / `get_min_idx()` 追加（Aroon対応）
- [x] テスト: 4,115本全通過
