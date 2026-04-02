using Test
using Foxtail
using TSFrames
using CSV

@testset "Indicators AAPL Integration" begin
    # Load and filter AAPL data: 2023-03-01 to 2024-06-30
    aapl_full = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
    aapl = TSFrames.subset(aapl_full, Date("2023-03-01"), Date("2024-06-30"))
    nrows = nrow(aapl)  # 335

    closes  = Float64.(aapl[:, :Close])
    highs   = Float64.(aapl[:, :High])
    lows    = Float64.(aapl[:, :Low])
    volumes = Float64.(aapl[:, :Volume])
    hlc     = hcat(highs, lows, closes)
    hl      = hcat(highs, lows)
    hlcv    = hcat(highs, lows, closes, volumes)
    cv      = hcat(closes, volumes)
    hlv     = hcat(highs, lows, volumes)

    @testset "AAPL: SMA" begin
        sma5 = SMA(closes; n=5)
        @test length(sma5) == nrows
        @test !any(isnan, sma5) && !any(isinf, sma5)

        # Regression: last 5 values
        expected_last5 = [211.25399780273438, 209.73399963378907, 209.5260009765625,
                          210.41000366210938, 211.03600158691407]
        @test sma5[end-4:end] ≈ expected_last5 atol=1e-6

        # Manual verification: SMA(5) at last bar = average of last 5 closes
        @test sma5[end] ≈ sum(closes[end-4:end]) / 5 atol=1e-10

        # Spot checks at known indices
        @test sma5[100] ≈ 193.3300018310547 atol=1e-6
        @test sma5[200] ≈ 195.16600341796874 atol=1e-6
        @test sma5[300] ≈ 180.652001953125 atol=1e-6
    end

    @testset "AAPL: EMA" begin
        ema10 = EMA(closes; n=10)
        @test length(ema10) == nrows
        @test !any(isnan, ema10) && !any(isinf, ema10)

        # Regression: last 3 values
        expected_last3 = [209.05162663278043, 209.96951380927771, 210.0877831379886]
        @test ema10[end-2:end] ≈ expected_last3 atol=1e-6

        # Spot checks at known indices
        @test ema10[100] ≈ 192.19404932529875 atol=1e-6
        @test ema10[200] ≈ 193.67219947004935 atol=1e-6
        @test ema10[300] ≈ 177.0504344914364 atol=1e-6
    end

    @testset "AAPL: RSI" begin
        rsi14 = RSI(closes)
        @test length(rsi14) == nrows
        @test !any(isnan, rsi14) && !any(isinf, rsi14)

        # Warmup: first value is 0.0
        @test rsi14[1] == 0.0

        # Range: all values (except warmup) in [0, 100]
        @test all(0.0 .<= rsi14[2:end] .<= 100.0)

        # Regression: last 3 values
        expected_last3 = [67.35823242281467, 68.135239948417, 61.66347404093098]
        @test rsi14[end-2:end] ≈ expected_last3 atol=1e-6

        # Spot checks at known indices
        @test rsi14[100] ≈ 60.93890884545557 atol=1e-6
        @test rsi14[200] ≈ 69.48990059171027 atol=1e-6
        @test rsi14[300] ≈ 64.87368041482502 atol=1e-6
    end

    @testset "AAPL: ROC" begin
        roc10 = ROC(closes; n=10)
        @test length(roc10) == nrows
        @test !any(isnan, roc10) && !any(isinf, roc10)

        # Warmup: first 10 values are 0.0
        @test all(roc10[1:10] .== 0.0)

        # Regression: last 3 values
        expected_last3 = [2.9447290771168833, 0.4834086187126157, -1.689698601175619]
        @test roc10[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: BB" begin
        # BB columns: col1=Center, col2=Upper, col3=Lower
        bb = BB(closes; n=20, num_std=2.0)
        @test size(bb) == (nrows, 3)
        @test !any(isnan, bb) && !any(isinf, bb)

        # Structural: Upper >= Center >= Lower
        @test all(bb[:, 2] .>= bb[:, 1] .- 1e-10)
        @test all(bb[:, 1] .>= bb[:, 3] .- 1e-10)

        # Center == SMA(20) (exact match)
        sma20 = SMA(closes; n=20)
        @test all(isapprox.(bb[:, 1], sma20; atol=1e-10))

        # Symmetric bands: upper - center == center - lower
        @test all(isapprox.(bb[:, 2] .- bb[:, 1], bb[:, 1] .- bb[:, 3]; atol=1e-10))

        # Regression: last 3 rows (n=20)
        @test bb[end, 1] ≈ 205.5625 atol=1e-6
        @test bb[end, 2] ≈ 222.66006682000804 atol=1e-6
        @test bb[end, 3] ≈ 188.46493317999196 atol=1e-6
    end

    @testset "AAPL: MACD" begin
        # MACD columns: col1=Line, col2=Signal, col3=Histogram
        m = MACD(closes)
        @test size(m) == (nrows, 3)
        @test !any(isnan, m) && !any(isinf, m)

        # Structural: Histogram = Line - Signal (exact)
        @test all(isapprox.(m[:, 3], m[:, 1] .- m[:, 2]; atol=1e-10))

        # Regression: last 3 rows
        @test m[end, 1] ≈ 6.203631879252754 atol=1e-6
        @test m[end, 2] ≈ 6.628613268005394 atol=1e-6
        @test m[end, 3] ≈ -0.4249813887526406 atol=1e-6

        # Spot checks at index 100 and 200
        @test m[100, 1] ≈ 2.716246916325275 atol=1e-6
        @test m[200, 1] ≈ 3.6025042257840596 atol=1e-6
    end

    @testset "AAPL: PPO" begin
        # PPO columns: col1=Line, col2=Signal, col3=Histogram
        ppo = PPO(closes)
        @test size(ppo) == (nrows, 3)
        @test !any(isnan, ppo) && !any(isinf, ppo)

        # Structural: Histogram = Line - Signal (exact)
        @test all(isapprox.(ppo[:, 3], ppo[:, 1] .- ppo[:, 2]; atol=1e-10))

        # Regression: last 3 rows
        @test ppo[end, 1] ≈ 3.0544894460857277 atol=1e-6
        @test ppo[end, 2] ≈ 3.3183837099320033 atol=1e-6
        @test ppo[end, 3] ≈ -0.26389426384627557 atol=1e-6
    end

    @testset "AAPL: KST" begin
        # KST columns: col1=Line, col2=Signal
        kst = KST(closes)
        @test size(kst) == (nrows, 2)
        @test !any(isnan, kst) && !any(isinf, kst)

        # Structural: Signal = SMA(9) of Line
        sma9_line = SMA(kst[:, 1]; n=9)
        @test all(isapprox.(kst[:, 2], sma9_line; atol=1e-10))

        # Regression: last 3 rows
        @test kst[end, 1] ≈ 94.09401953851903 atol=1e-6
        @test kst[end, 2] ≈ 89.14314361594337 atol=1e-6
    end

    @testset "AAPL: ATR" begin
        atr14 = ATR(hlc)
        @test length(atr14) == nrows
        @test !any(isnan, atr14) && !any(isinf, atr14)

        # Non-negative
        @test all(atr14 .>= 0.0)

        # Regression: last 3 values
        expected_last3 = [5.295448440476773, 5.041388567032995, 5.138537327756721]
        @test atr14[end-2:end] ≈ expected_last3 atol=1e-6

        # Spot check
        @test atr14[100] ≈ 3.1703104973769114 atol=1e-6
        @test atr14[200] ≈ 3.012505975530658 atol=1e-6
    end

    @testset "AAPL: CCI" begin
        cci = CCI(hlc)
        @test length(cci) == nrows
        @test !any(isnan, cci) && !any(isinf, cci)

        # Magnitude: for real AAPL data, CCI should stay within [-500, 500]
        @test all(abs.(cci) .< 500.0)

        # Regression: last 3 values (computed on subset 2023-03-01 to 2024-06-28)
        expected_last3 = [70.91563155094146, 72.57762773845828, 54.24874221497218]
        @test cci[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: MFI" begin
        mfi = MFI(hlcv)
        @test length(mfi) == nrows
        @test !any(isnan, mfi) && !any(isinf, mfi)

        # Range: [0, 100] (with tiny fp tolerance)
        @test all(-1e-8 .<= mfi .<= 100.0 + 1e-8)

        # Regression: last 3 values
        expected_last3 = [57.1579072188662, 60.17928146104886, 55.44238207877109]
        @test mfi[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: CMF" begin
        cmf = CMF(hlcv)
        @test length(cmf) == nrows
        @test !any(isnan, cmf) && !any(isinf, cmf)

        # Range: [-1, 1] (with tolerance)
        @test all(-1.0 - 1e-8 .<= cmf .<= 1.0 + 1e-8)

        # Regression: last 3 values
        expected_last3 = [-0.1180613247698732, -0.10443009868442184, -0.13920860721842354]
        @test cmf[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: OBV" begin
        obv = OBV(cv)
        @test length(obv) == nrows
        @test !any(isnan, obv) && !any(isinf, obv)

        # Sign consistency: OBV changes in same direction as close
        dclose = diff(closes)
        dobv = diff(obv)
        nonzero = dclose .!= 0
        @test all(sign.(dobv[nonzero]) .== sign.(dclose[nonzero]))

        # Regression: last 3 values
        expected_last3 = [1.0670996e9, 1.1168723e9, 1.0343296e9]
        @test obv[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: ADL" begin
        adl = ADL(hlcv)
        @test length(adl) == nrows
        @test !any(isnan, adl) && !any(isinf, adl)

        # Regression: last 3 values
        expected_last3 = [6.395618806505955e8, 6.411769332655203e8, 5.677895155883453e8]
        @test adl[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: WR" begin
        # WR columns: col1=Raw, col2=EMA
        wr = WR(hlc)
        @test size(wr) == (nrows, 2)
        @test !any(isnan, wr) && !any(isinf, wr)

        # Range: Raw WR in [-100, 0]
        @test all(-100.0 - 1e-8 .<= wr[:, 1] .<= 0.0 + 1e-8)

        # Regression: last 3 values (raw, EMA)
        @test wr[end, 1] ≈ -34.153300494754625 atol=1e-6
        @test wr[end, 2] ≈ -27.870905984765848 atol=1e-6

        # Spot checks
        @test wr[100, 1] ≈ -47.11952378890634 atol=1e-6
        @test wr[200, 1] ≈ -0.3790831712238124 atol=1e-6
    end

    @testset "AAPL: Stoch" begin
        # Stoch columns: col1=K, col2=D
        stoch = Stoch(hlc)
        @test size(stoch) == (nrows, 2)
        @test !any(isnan, stoch) && !any(isinf, stoch)

        # Range: K and D in [0, 100]
        @test all(0.0 - 1e-8 .<= stoch[:, 1] .<= 100.0 + 1e-8)
        @test all(0.0 - 1e-8 .<= stoch[:, 2] .<= 100.0 + 1e-8)

        # Regression: last 3 K values
        expected_K = [64.18302929088797, 71.26562711077624, 73.10756130487563]
        @test stoch[end-2:end, 1] ≈ expected_K atol=1e-6

        # Regression: last 3 D values
        expected_D = [60.16954838983289, 64.2622577263288, 69.51873923551322]
        @test stoch[end-2:end, 2] ≈ expected_D atol=1e-6
    end

    @testset "AAPL: StochRSI" begin
        # StochRSI columns: col1=K, col2=D
        srsi = StochRSI(closes)
        @test size(srsi) == (nrows, 2)
        @test !any(isnan, srsi) && !any(isinf, srsi)

        # Range: K and D in [0, 100] (tiny fp noise tolerated)
        @test all(-1e-8 .<= srsi[:, 1] .<= 100.0 + 1e-8)
        @test all(-1e-8 .<= srsi[:, 2] .<= 100.0 + 1e-8)

        # Regression: last 3 K values
        expected_K = [36.735423007746185, 41.72903363729409, 39.64881047826745]
        @test srsi[end-2:end, 1] ≈ expected_K atol=1e-6
    end

    @testset "AAPL: DMI" begin
        # DMI columns: col1=+DI, col2=-DI, col3=ADX
        dmi = DMI(hlc)
        @test size(dmi) == (nrows, 3)
        @test !any(isnan, dmi) && !any(isinf, dmi)

        # Range: +DI >= 0, -DI >= 0, ADX in [0, 100]
        @test all(dmi[:, 1] .>= 0.0)
        @test all(dmi[:, 2] .>= 0.0)
        @test all(0.0 .<= dmi[:, 3] .<= 100.0)

        # Regression: last row
        @test dmi[end, 1] ≈ 30.838536574682212 atol=1e-6  # +DI
        @test dmi[end, 2] ≈ 12.96574787652681 atol=1e-6   # -DI
        @test dmi[end, 3] ≈ 45.986681632443 atol=1e-6     # ADX
    end

    @testset "AAPL: Aroon" begin
        # Aroon columns: col1=Up, col2=Down, col3=Oscillator
        aroon = Aroon(hl)
        @test size(aroon) == (nrows, 3)
        @test !any(isnan, aroon) && !any(isinf, aroon)

        # Range: Up and Down in [0, 100], Osc in [-100, 100]
        @test all(0.0 .<= aroon[:, 1] .<= 100.0)
        @test all(0.0 .<= aroon[:, 2] .<= 100.0)
        @test all(-100.0 .<= aroon[:, 3] .<= 100.0)

        # Structural: Oscillator = Up - Down
        @test all(isapprox.(aroon[:, 3], aroon[:, 1] .- aroon[:, 2]; atol=1e-10))

        # Regression: last 3 rows
        @test aroon[end, 1] ≈ 56.0 atol=1e-6
        @test aroon[end, 2] ≈ 4.0 atol=1e-6
        @test aroon[end, 3] ≈ 52.0 atol=1e-6
    end

    @testset "AAPL: VWAP" begin
        vwap = VWAP(hlcv)
        @test length(vwap) == nrows
        @test !any(isnan, vwap) && !any(isinf, vwap)

        # Range: within [min(Low), max(High)]
        @test all(minimum(lows) .<= vwap .<= maximum(highs))

        # Regression: last 3 values
        expected_last3 = [180.45159625031891, 180.5349986932059, 180.66530054960666]
        @test vwap[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: ForceIndex" begin
        fi = ForceIndex(cv)
        @test length(fi) == nrows
        @test !any(isnan, fi) && !any(isinf, fi)

        # Regression: last 3 values
        expected_last3 = [9.429837108168639e7, 8.687104646836722e7, 3.3425253709859543e7]
        @test fi[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: VPT" begin
        vpt = VPT(cv)
        @test length(vpt) == nrows
        @test !any(isnan, vpt) && !any(isinf, vpt)

        # Regression: last 3 values
        expected_last3 = [3.67434061820284e7, 3.694179820448304e7, 3.560013779041325e7]
        @test vpt[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: NVI" begin
        nvi = NVI(cv)
        @test length(nvi) == nrows
        @test !any(isnan, nvi) && !any(isinf, nvi)

        # Always positive
        @test all(nvi .> 0.0)

        # Regression: last 3 values
        expected_last3 = [1135.3674669687928, 1139.892996988284, 1139.892996988284]
        @test nvi[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: PVI" begin
        pvi = PVI(cv)
        @test length(pvi) == nrows
        @test !any(isnan, pvi) && !any(isinf, pvi)

        # Always positive
        @test all(pvi .> 0.0)

        # Regression: last 3 values
        expected_last3 = [1292.579008366402, 1292.579008366402, 1271.5692511427737]
        @test pvi[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: EMV" begin
        emv = EMV(hlv)
        @test length(emv) == nrows
        @test !any(isnan, emv) && !any(isinf, emv)

        # Regression: last 3 values
        expected_last3 = [9.385430670475998, 10.237717998499997, 9.731104010806472]
        @test emv[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: DonchianChannel" begin
        # DonchianChannel columns: col1=Upper, col2=Lower, col3=Middle
        dc = DonchianChannel(hlc)
        @test size(dc) == (nrows, 3)
        @test !any(isnan, dc) && !any(isinf, dc)

        # Structural: Upper >= Middle >= Lower
        @test all(dc[:, 1] .>= dc[:, 3] .- 1e-10)  # Upper >= Middle
        @test all(dc[:, 3] .>= dc[:, 2] .- 1e-10)  # Middle >= Lower

        # Regression: last row
        @test dc[end, 1] ≈ 220.1999969482422 atol=1e-6   # Upper
        @test dc[end, 2] ≈ 189.91000366210938 atol=1e-6  # Lower
        @test dc[end, 3] ≈ 205.05500030517578 atol=1e-6  # Middle
    end

    @testset "AAPL: KeltnerChannel" begin
        # KeltnerChannel columns: col1=Middle, col2=Upper, col3=Lower
        kc = KeltnerChannel(hlc)
        @test size(kc) == (nrows, 3)
        @test !any(isnan, kc) && !any(isinf, kc)

        # Structural: Upper >= Middle >= Lower
        @test all(kc[:, 2] .>= kc[:, 1] .- 1e-10)  # Upper >= Middle
        @test all(kc[:, 1] .>= kc[:, 3] .- 1e-10)  # Middle >= Lower

        # Regression: last row
        @test kc[end, 1] ≈ 205.72605238720612 atol=1e-6  # Middle
        @test kc[end, 2] ≈ 215.73976422802747 atol=1e-6  # Upper
        @test kc[end, 3] ≈ 195.71234054638478 atol=1e-6  # Lower
    end

    @testset "AAPL: Supertrend" begin
        # Supertrend columns: col1=Value, col2=Direction
        st = Supertrend(hlc)
        @test size(st) == (nrows, 2)
        @test !any(isnan, st) && !any(isinf, st)

        # Direction is always +1 or -1
        @test all(d -> d == 1.0 || d == -1.0, st[:, 2])

        # Directional invariant: dir=1 => value <= close, dir=-1 => value >= close
        up_idx = st[:, 2] .== 1.0
        down_idx = st[:, 2] .== -1.0
        @test all(st[up_idx, 1] .<= closes[up_idx])
        @test all(st[down_idx, 1] .>= closes[down_idx])

        # Regression: last row (uptrend, computed on subset)
        @test st[end, 1] ≈ 199.5669903287957 atol=1e-6
        @test st[end, 2] == 1.0
    end

    @testset "AAPL: ParabolicSAR" begin
        # ParabolicSAR columns: col1=Value, col2=Direction
        psar = ParabolicSAR(hl)
        @test size(psar) == (nrows, 2)
        @test !any(isnan, psar) && !any(isinf, psar)

        # Direction is always +1 or -1
        @test all(d -> d == 1.0 || d == -1.0, psar[:, 2])

        # dir=1 => SAR <= Low (100% for this data)
        up_idx = psar[:, 2] .== 1.0
        @test all(psar[up_idx, 1] .<= lows[up_idx] .+ 1e-10)

        # dir=-1 => SAR >= High (>99% — 1 edge case on reversal bar)
        down_idx = psar[:, 2] .== -1.0
        @test sum(psar[down_idx, 1] .>= highs[down_idx] .- 1e-10) / sum(down_idx) > 0.99

        # Regression: last row
        @test psar[end, 1] ≈ 202.29738177851118 atol=1e-6
        @test psar[end, 2] == 1.0
    end

    @testset "AAPL: Ichimoku" begin
        ich = Ichimoku(hlc)
        # Outputs nrows + 26 rows (senkou projection)
        @test size(ich, 1) == nrows + 26
        @test size(ich, 2) == 5

        # No Inf anywhere
        @test !any(isinf, ich)

        # NaN pattern: SenkouA and SenkouB are NaN in first 26 rows
        @test all(isnan, ich[1:26, 3])
        @test all(isnan, ich[1:26, 4])

        # NaN pattern: Tenkan and Kijun are NaN in projection rows (336:361)
        @test all(isnan, ich[nrows+1:nrows+26, 1])
        @test all(isnan, ich[nrows+1:nrows+26, 2])

        # NaN pattern: Chikou is NaN for last 52 rows (26 data + 26 projection)
        @test all(isnan, ich[nrows-25:nrows+26, 5])

        # Regression: spot check at row 200
        @test ich[200, 1] ≈ 192.7249984741211 atol=1e-6   # Tenkan
        @test ich[200, 2] ≈ 188.48500061035156 atol=1e-6  # Kijun
    end

    @testset "AAPL: SqueezeMomentum" begin
        sm = SqueezeMomentum(hlc; n=20)
        @test size(sm) == (nrows, 2)
        @test !any(isnan, sm) && !any(isinf, sm)

        # Squeeze column is 0.0 or 1.0 only
        @test all(v -> v == 0.0 || v == 1.0, sm[:, 2])

        # Invariant: squeeze=1 implies BB width < KC width
        bb20 = BB(closes; n=20)
        kc20 = KeltnerChannel(hlc; n=20)
        bb_width = bb20[:, 2] .- bb20[:, 3]
        kc_width = kc20[:, 2] .- kc20[:, 3]
        @test all(i -> sm[i, 2] == 1.0 ? bb_width[i] < kc_width[i] : true, 1:nrows)

        # Regression: last row
        @test sm[end, 1] ≈ 8.680797392400088 atol=1e-6
        @test sm[end, 2] == 0.0
    end

    @testset "AAPL: ChaikinOsc" begin
        chaikin = ChaikinOsc(hlcv)
        @test length(chaikin) == nrows
        @test !any(isnan, chaikin) && !any(isinf, chaikin)

        # Regression: last 3 values
        expected_last3 = [-1.2446425169675422e8, -1.0829899900989032e8, -1.1519111953437519e8]
        @test chaikin[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: DPO" begin
        dpo = DPO(closes)
        @test length(dpo) == nrows
        @test !any(isnan, dpo) && !any(isinf, dpo)

        # Regression: last 3 values
        expected_last3 = [21.90750198364259, 21.714008331298828, 16.95199661254884]
        @test dpo[end-2:end] ≈ expected_last3 atol=1e-6
    end

    @testset "AAPL: Moving Averages" begin
        mas = Dict(
            "SMA"   => SMA(closes; n=20),
            "EMA"   => EMA(closes; n=20),
            "SMMA"  => SMMA(closes; n=20),
            "WMA"   => WMA(closes; n=20),
            "HMA"   => HMA(closes; n=20),
            "DEMA"  => DEMA(closes; n=20),
            "TEMA"  => TEMA(closes; n=20),
            "TMA"   => TMA(closes; n=20),
            "ALMA"  => ALMA(closes; n=20),
            "KAMA"  => KAMA(closes; n=20),
            "T3"    => T3(closes; n=20),
            "ZLEMA" => ZLEMA(closes; n=20),
            "JMA"   => JMA(closes; n=20),
        )
        for (name, ma) in mas
            @testset "$name" begin
                @test length(ma) == nrows
                @test !any(isnan, ma)
                @test !any(isinf, ma)
                # All MAs should track price within reasonable range (AAPL ~145-220)
                @test all(abs.(ma .- closes) .< 100.0)
            end
        end

        # Regression for MA variants (n=10) last values
        @test DEMA(closes; n=10)[end] ≈ 213.38948747529093 atol=1e-6
        @test TEMA(closes; n=10)[end] ≈ 212.1633274868708 atol=1e-6
        @test WMA(closes; n=10)[end] ≈ 211.2054551558061 atol=1e-6
        @test HMA(closes; n=10)[end] ≈ 211.56865968031818 atol=1e-6
        @test KAMA(closes; n=10)[end] ≈ 207.30562736022347 atol=1e-6
        @test ALMA(closes; n=10)[end] ≈ 211.69326096353495 atol=1e-6
        @test ZLEMA(closes; n=10)[end] ≈ 212.26832318053894 atol=1e-6
        @test T3(closes; n=10)[end] ≈ 212.87445899652994 atol=1e-6
    end
end
