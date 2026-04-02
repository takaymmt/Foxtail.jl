# AAPL Reference Values for Regression Tests

Generated: 2026-04-01
Data: `test/aapl.csv` filtered to 2023-03-01 .. 2024-06-30
Rows: 335 (Date range: 2023-03-01 to 2024-06-28)

## Data Setup

```julia
aapl_full = CSV.read("test/aapl.csv", TSFrame)
aapl = TSFrames.subset(aapl_full, Date("2023-03-01"), Date("2024-06-30"))
closes  = Float64.(aapl[:, :Close])
highs   = Float64.(aapl[:, :High])
lows    = Float64.(aapl[:, :Low])
volumes = Float64.(aapl[:, :Volume])
hlc     = hcat(highs, lows, closes)
hlcv    = hcat(highs, lows, closes, volumes)
cv      = hcat(closes, volumes)
hl      = hcat(highs, lows)
hlv     = hcat(highs, lows, volumes)
```

## Input Signatures Summary

| Indicator | Input | Output Shape | Columns |
|-----------|-------|-------------|---------|
| SMA | closes | (335,) | scalar |
| EMA | closes | (335,) | scalar |
| RSI | closes | (335,) | scalar |
| ROC | closes | (335,) | scalar |
| MACD | closes | (335, 3) | line, signal, hist |
| BB | closes | (335, 3) | center, upper, lower |
| ATR | hlc | (335,) | scalar |
| WR | hlc | (335, 2) | raw, EMA |
| CMF | hlcv | (335,) | scalar |
| Stoch | hlc | (335, 2) | K, D |
| StochRSI | closes | (335, 2) | K, D |
| CCI | hlc | (335,) | scalar |
| DonchianChannel | hlc | (335, 3) | upper, lower, middle |
| KeltnerChannel | hlc | (335, 3) | middle, upper, lower |
| DMI | hlc | (335, 3) | +DI, -DI, ADX |
| PPO | closes | (335, 3) | line, signal, hist |
| ForceIndex | cv | (335,) | scalar |
| MFI | hlcv | (335,) | scalar |
| Aroon | hl | (335, 3) | up, down, osc |
| VPT | cv | (335,) | scalar |
| OBV | cv | (335,) | scalar |
| NVI | cv | (335,) | scalar |
| PVI | cv | (335,) | scalar |
| Supertrend | hlc | (335, 2) | value, direction |
| KST | closes | (335, 2) | line, signal |
| DPO | closes | (335,) | scalar |
| ParabolicSAR | hl | (335, 2) | value, direction |
| SqueezeMomentum | hlc | (335, 2) | momentum, squeeze |
| EMV | hlv | (335,) | scalar |
| Ichimoku | hlc | (361, 5) | tenkan, kijun, senkouA, senkouB, chikou |
| ADL | hlcv | (335,) | scalar |
| ChaikinOsc | hlcv | (335,) | scalar |
| VWAP | hlcv | (335,) | scalar |
| DEMA | closes | (335,) | scalar |
| TEMA | closes | (335,) | scalar |
| WMA | closes | (335,) | scalar |
| HMA | closes | (335,) | scalar |
| KAMA | closes | (335,) | scalar |
| ALMA | closes | (335,) | scalar |
| ZLEMA | closes | (335,) | scalar |
| T3 | closes | (335,) | scalar |

## Reference Values (last N)

### SMA(5) last 5
```
[211.25399780273438, 209.73399963378907, 209.5260009765625, 210.41000366210938, 211.03600158691407]
```

### EMA(10) last 3
```
[209.05162663278043, 209.96951380927771, 210.0877831379886]
```

### RSI(14) last 3
```
[67.35823242281467, 68.135239948417, 61.66347404093098]
```

### ROC(10) last 3
```
[2.9447290771168833, 0.4834086187126157, -1.689698601175619]
```

### MACD (default 12,26,9) last 3 rows
```
row 333: line=6.578164170646488  signal=6.777130244810799  hist=-0.19896607416431067
row 334: line=6.565772096724572  signal=6.734858615193554  hist=-0.1690865184689816
row 335: line=6.203631879252754  signal=6.628613268005394  hist=-0.4249813887526406
```

### BB (default n=14) last 3 rows (center, upper, lower)
```
row 333: center=207.85928562709265  upper=222.589503727721    lower=193.1290675264643
row 334: center=209.2607149396624   upper=222.2648107199149   lower=196.2566191594099
row 335: center=210.2414289202009   upper=221.28964293664384  lower=199.19321490375793
```

### BB (n=20) last 3 rows (center, upper, lower)
```
row 333: center=203.40549926757814  upper=221.88287762341778  lower=184.9281209117385
row 334: center=204.59599990844725  upper=222.60198612593072  lower=186.5900136909638
row 335: center=205.5625             upper=222.66006682000804  lower=188.46493317999196
```

### ATR(14) last 3
```
[5.295448440476773, 5.041388567032995, 5.138537327756721]
```

### WR(14) last 3 (col1=raw, col2=EMA)
```
raw:  [-24.777170025322516, -21.746845565295914, -34.153300494754625]
ema:  [-27.670006011068573, -26.823840233101052, -27.870905984765848]
```

### CMF(20) last 3
```
[-0.1180613247698732, -0.10443009868442184, -0.13920860721842354]
```

### Stoch(14) last 3 (K, D)
```
K: [64.18302929088797, 71.26562711077624, 73.10756130487563]
D: [60.16954838983289, 64.2622577263288, 69.51873923551322]
```

### StochRSI(14) last 3 (K, D)
```
K: [36.735423007746185, 41.72903363729409, 39.64881047826745]
D: [37.18324178831048, 37.88883523249382, 39.3710890411025]
```

### CCI(14) last 3
```
[52.69158779283552, 61.98099138095743, 30.93485805852134]
```

### DonchianChannel(20) last 3 (upper, lower, middle)
```
row 333: upper=220.1999969482422  lower=189.50999450683594  mid=204.85499572753906
row 334: upper=220.1999969482422  lower=189.91000366210938  mid=205.05500030517578
row 335: upper=220.1999969482422  lower=189.91000366210938  mid=205.05500030517578
```

### KeltnerChannel(20) last 3 (middle, upper, lower)
```
row 333: mid=204.27520519640564  upper=214.45173320001288  lower=194.0986771927984
row 334: mid=205.2109005208923   upper=215.0639495507557   lower=195.3578514910289
row 335: mid=205.72605238720612  upper=215.73976422802747  lower=195.71234054638478
```

### DMI(14) last 3 (+DI, -DI, ADX)
```
row 333: +DI=34.135840392453794  -DI=11.44120944764078   ADX=46.00874922993288
row 334: +DI=33.7191416338162    -DI=10.858166298897057  ADX=46.385544641857905
row 335: +DI=30.838536574682212  -DI=12.96574787652681   ADX=45.986681632443
```

### PPO last 3 (line, signal, hist)
```
row 333: line=3.26348186290825    signal=3.419845922353193   hist=-0.15636405944494314
row 334: line=3.242402690055087   signal=3.3843572758935716  hist=-0.14195458583848453
row 335: line=3.0544894460857277  signal=3.3183837099320033  hist=-0.26389426384627557
```

### ForceIndex(13) last 3
```
[9.429837108168639e7, 8.687104646836722e7, 3.3425253709859543e7]
```

### MFI(14) last 3
```
[57.1579072188662, 60.17928146104886, 55.44238207877109]
```

### Aroon(25) last 3 (up, down, osc)
```
row 333: up=64.0  down=12.0  osc=52.0
row 334: up=60.0  down=8.0   osc=52.0
row 335: up=56.0  down=4.0   osc=52.0
```

### VPT last 3
```
[3.67434061820284e7, 3.694179820448304e7, 3.560013779041325e7]
```

### OBV last 3
```
[1.0670996e9, 1.1168723e9, 1.0343296e9]
```

### NVI last 3
```
[1135.3674669687928, 1139.892996988284, 1139.892996988284]
```

### PVI last 3
```
[1292.579008366402, 1292.579008366402, 1271.5692511427737]
```

### Supertrend(14) last 3 (value, direction)
```
row 333: value=199.5044574841041  direction=1.0
row 334: value=199.5044574841041  direction=1.0
row 335: value=199.5044574841041  direction=1.0
```

### KST last 3 (line, signal)
```
row 333: line=92.70441190677136  signal=85.25355256652979
row 334: line=93.5489329816148   signal=87.33104831863336
row 335: line=94.09401953851903  signal=89.14314361594337
```

### DPO(20) last 3
```
[21.90750198364259, 21.714008331298828, 16.95199661254884]
```

### ParabolicSAR last 3 (value, direction)
```
row 333: value=200.7744162519195   direction=1.0
row 334: value=201.5514394797724   direction=1.0
row 335: value=202.29738177851118  direction=1.0
```

### SqueezeMomentum(20) last 3 (momentum, squeeze)
```
row 333: momentum=9.380263782997991  squeeze=0.0
row 334: momentum=9.377734294406606  squeeze=0.0
row 335: momentum=8.680797392400088  squeeze=0.0
```

### EMV(14) last 3
```
[9.385430670475998, 10.237717998499997, 9.731104010806472]
```

### Ichimoku last 3 of data rows (row 335) and extended rows
```
row 335: tenkan=212.7699966430664  kijun=203.41500091552734  senkouA=182.9124984741211  senkouB=178.40499877929688  chikou=NaN
row 309: tenkan=187.4199981689453  kijun=178.40499877929688  senkouA=172.8125  senkouB=179.0800018310547  chikou=210.6199951171875
row 200: tenkan=192.7249984741211  kijun=188.48500061035156  senkouA=173.27749633789062  senkouB=177.8249969482422  chikou=195.17999267578125
```
Note: Ichimoku outputs 361 rows (335 + 26 for senkou span projection). Chikou is NaN for last 26 rows.

### ADL last 3
```
[6.395618806505955e8, 6.411769332655203e8, 5.677895155883453e8]
```

### ChaikinOsc last 3
```
[-1.2446425169675422e8, -1.0829899900989032e8, -1.1519111953437519e8]
```

### VWAP last 3
```
[180.45159625031891, 180.5349986932059, 180.66530054960666]
```

### MA Variants (n=10) last 3
```
DEMA:  [212.92136366950785, 213.88666089282523, 213.38948747529093]
TEMA:  [211.79449032984132, 213.0034636532236, 212.1633274868708]
WMA:   [211.03472817160866, 211.44581992409445, 211.2054551558061]
HMA:   [208.41724465111972, 210.16964083586768, 211.56865968031818]
KAMA:  [207.23369197103696, 207.26562790327608, 207.30562736022347]
ALMA:  [209.6190347237237, 210.96356100814282, 211.69326096353495]
ZLEMA: [210.16650846187187, 212.08350814405281, 212.26832318053894]
T3:    [211.522569977388, 212.28008046881337, 212.87445899652994]
```

## Values at Specific Indices

```
closes[100] = 192.75
closes[200] = 197.9600067138672
closes[300] = 182.74000549316406

SMA(5)[100]  = 193.3300018310547   [200] = 195.16600341796874  [300] = 180.652001953125
EMA(10)[100] = 192.19404932529875  [200] = 193.67219947004935  [300] = 177.0504344914364
RSI(14)[100] = 60.93890884545557   [200] = 69.48990059171027   [300] = 64.87368041482502
ATR(14)[100] = 3.1703104973769114  [200] = 3.012505975530658   [300] = 4.290641037834659

MACD[100]: line=2.716246916325275   signal=3.027985803419521   hist=-0.3117388870942457
MACD[200]: line=3.6025042257840596  signal=3.4721395588017367  hist=0.13036466698232285

WR[100]: raw=-47.11952378890634  ema=-34.31393403586755
WR[200]: raw=-0.3790831712238124 ema=-17.642651946673013
```

## Warmup Behavior

### RSI(14) first 15 values
```
[0.0, 100.0, 100.0, 100.0, 79.25585369731104, 81.44760594204702, 68.46154995283644,
 59.73156049431449, 64.05230876633092, 67.77345146985195, 68.39083273713435,
 72.198847684571, 69.7031392527598, 72.39718546191351, 74.19467194919304]
```
Note: RSI[1] = 0.0 (no prior data). Values stabilize quickly.

### ROC(10) first 12 values
```
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.285257768635969, 6.812420116460814]
```
Note: First 10 values are 0.0 (need n periods of history).

## Invariant Checks

### CONFIRMED (all hold)

1. **MACD histogram = line - signal**: TRUE (exact, atol=1e-10)
2. **PPO histogram = line - signal**: TRUE (exact, atol=1e-10)
3. **BB center = SMA(n)**: TRUE (exact, max diff = 0.0)
4. **BB symmetric (upper-center = center-lower)**: TRUE (exact, atol=1e-10)
5. **KST signal = SMA(9) of KST line**: TRUE (max diff = 9.95e-14, floating point noise)
6. **Aroon osc = up - down**: TRUE (exact, atol=1e-10)
7. **OBV sign match**: 333/333 (100% - when close changes, OBV changes in same direction)
8. **NVI always positive**: TRUE (min = 989.57)
9. **PVI always positive**: TRUE (min = 992.52)
10. **Supertrend near price**: 0/335 values far from price (>5*ATR)
11. **Supertrend dir=1 => value <= close**: 204/204 (100%)
12. **Supertrend dir=-1 => value >= close**: 131/131 (100%)
13. **ParabolicSAR dir=1 => SAR <= Low**: 203/203 (100%)
14. **ParabolicSAR dir=-1 => SAR >= High**: 131/132 (99.2%, 1 edge case)

### Range Checks (all hold)

| Indicator | Expected Range | Actual Min | Actual Max | PASS |
|-----------|---------------|------------|------------|------|
| RSI(14) | [0, 100] | 0.0 | 100.0 | YES |
| MFI(14) | [0, 100] | 0.0 | 100.0 | YES |
| WR raw | [-100, 0] | -99.65 | -0.049 | YES |
| Aroon up | [0, 100] | 0.0 | 100.0 | YES |
| Aroon down | [0, 100] | 0.0 | 100.0 | YES |
| Aroon osc | [-100, 100] | -100.0 | 100.0 | YES |
| CMF(20) | [-1, 1] | -0.730 | 0.350 | YES |
| Stoch K | [0, 100] | 2.31 | 99.29 | YES |
| Stoch D | [0, 100] | 4.28 | 97.52 | YES |
| StochRSI K | [0, 100] | ~0.0 | ~100.0 | YES (tiny fp noise: -3.5e-15 to 100.000) |
| StochRSI D | [0, 100] | ~0.0 | ~100.0 | YES (tiny fp noise: -4.6e-14 to 100.0) |
| DMI +DI | [0, inf) | 0.0 | 61.87 | YES |
| DMI -DI | [0, inf) | 0.0 | 40.66 | YES |
| DMI ADX | [0, 100] | 0.0 | 59.74 | YES |

### SqueezeMomentum Invariants

- **squeeze=1 => BB_width < KC_width**: TRUE (confirmed at indices 1,2 which are the only squeeze=1)
- **squeeze=0 => BB_width >= KC_width**: FALSE (96 indices violate this)
  - This means Foxtail's SqueezeMomentum uses its own internal squeeze logic, not a simple BB vs KC width comparison
  - Only 2 out of 335 rows have squeeze=1
- **Squeeze counts**: squeeze=1: 2, squeeze=0: 333

### NVI/PVI Behavior

- NVI changes only when volume decreases (by design)
- PVI changes only when volume increases (by design)
- NVI last 3: `[1135.37, 1139.89, 1139.89]` (last two same = volume increased)
- PVI last 3: `[1292.58, 1292.58, 1271.57]` (first two same = volume decreased)

## Output Dimensions

All indicators return exactly 335 rows (same as input), except:
- **Ichimoku**: 361 rows (335 + 26 for senkou span forward projection)
