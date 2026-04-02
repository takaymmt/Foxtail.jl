using Test
using Foxtail
using TSFrames
using CSV

aapl = CSV.read(joinpath(@__DIR__, "aapl.csv"), TSFrame)
data_ts = aapl[end-100:end]

@testset "Indicators MISO" begin
    # Fixed realistic financial data replacing rand() arrays
    # 100-row arrays with plausible OHLCV-like values

    # High column: trending upward with noise
    _high_col = [
        102.5, 103.8, 101.2, 104.6, 105.3, 103.9, 106.1, 107.4, 105.8, 108.2,
        109.5, 107.3, 110.1, 111.6, 109.4, 112.3, 113.7, 111.5, 114.2, 115.8,
        113.6, 116.4, 117.9, 115.7, 118.5, 119.3, 117.1, 120.6, 121.4, 119.2,
        122.3, 123.8, 121.6, 124.4, 125.7, 123.5, 126.2, 127.9, 125.7, 128.4,
        129.5, 127.3, 130.1, 131.6, 129.4, 132.3, 133.7, 131.5, 134.2, 135.8,
        133.6, 136.4, 137.9, 135.7, 138.5, 139.3, 137.1, 140.6, 141.4, 139.2,
        142.3, 143.8, 141.6, 144.4, 145.7, 143.5, 146.2, 147.9, 145.7, 148.4,
        149.5, 147.3, 150.1, 151.6, 149.4, 152.3, 153.7, 151.5, 154.2, 155.8,
        153.6, 156.4, 157.9, 155.7, 158.5, 159.3, 157.1, 160.6, 161.4, 159.2,
        162.3, 163.8, 161.6, 164.4, 165.7, 163.5, 166.2, 167.9, 165.7, 168.4
    ]
    # Low column: below high with realistic spread
    _low_col = [
        99.1, 100.2, 98.5, 101.3, 102.1, 100.7, 103.0, 104.2, 102.6, 105.0,
        106.3, 104.1, 107.0, 108.4, 106.2, 109.1, 110.5, 108.3, 111.0, 112.6,
        110.4, 113.2, 114.7, 112.5, 115.3, 116.1, 113.9, 117.4, 118.2, 116.0,
        119.1, 120.6, 118.4, 121.2, 122.5, 120.3, 123.0, 124.7, 122.5, 125.2,
        126.3, 124.1, 127.0, 128.4, 126.2, 129.1, 130.5, 128.3, 131.0, 132.6,
        130.4, 133.2, 134.7, 132.5, 135.3, 136.1, 133.9, 137.4, 138.2, 136.0,
        139.1, 140.6, 138.4, 141.2, 142.5, 140.3, 143.0, 144.7, 142.5, 145.2,
        146.3, 144.1, 147.0, 148.4, 146.2, 149.1, 150.5, 148.3, 151.0, 152.6,
        150.4, 153.2, 154.7, 152.5, 155.3, 156.1, 153.9, 157.4, 158.2, 156.0,
        159.1, 160.6, 158.4, 161.2, 162.5, 160.3, 163.0, 164.7, 162.5, 165.2
    ]
    # Close column: between high and low
    _close_col = [
        100.8, 102.0, 99.8, 103.0, 103.7, 102.3, 104.5, 105.8, 104.2, 106.6,
        107.9, 105.7, 108.5, 110.0, 107.8, 110.7, 112.1, 109.9, 112.6, 114.2,
        112.0, 114.8, 116.3, 114.1, 116.9, 117.7, 115.5, 119.0, 119.8, 117.6,
        120.7, 122.2, 120.0, 122.8, 124.1, 121.9, 124.6, 126.3, 124.1, 126.8,
        127.9, 125.7, 128.5, 130.0, 127.8, 130.7, 132.1, 129.9, 132.6, 134.2,
        132.0, 134.8, 136.3, 134.1, 136.9, 137.7, 135.5, 139.0, 139.8, 137.6,
        140.7, 142.2, 140.0, 142.8, 144.1, 141.9, 144.6, 146.3, 144.1, 146.8,
        147.9, 145.7, 148.5, 150.0, 147.8, 150.7, 152.1, 149.9, 152.6, 154.2,
        152.0, 154.8, 156.3, 154.1, 156.9, 157.7, 155.5, 159.0, 159.8, 157.6,
        160.7, 162.2, 160.0, 162.8, 164.1, 161.9, 164.6, 166.3, 164.1, 166.8
    ]
    # Volume column: realistic trading volumes
    _vol_col = [
        25000.0, 31000.0, 28000.0, 35000.0, 42000.0, 27000.0, 38000.0, 45000.0, 30000.0, 40000.0,
        33000.0, 29000.0, 36000.0, 48000.0, 32000.0, 41000.0, 37000.0, 26000.0, 39000.0, 44000.0,
        34000.0, 43000.0, 46000.0, 28000.0, 37000.0, 41000.0, 31000.0, 47000.0, 50000.0, 33000.0,
        38000.0, 42000.0, 29000.0, 44000.0, 49000.0, 35000.0, 40000.0, 46000.0, 32000.0, 43000.0,
        36000.0, 30000.0, 39000.0, 51000.0, 34000.0, 45000.0, 48000.0, 27000.0, 41000.0, 47000.0,
        33000.0, 44000.0, 50000.0, 29000.0, 38000.0, 42000.0, 31000.0, 46000.0, 52000.0, 35000.0,
        40000.0, 45000.0, 28000.0, 43000.0, 48000.0, 34000.0, 39000.0, 47000.0, 30000.0, 44000.0,
        37000.0, 26000.0, 36000.0, 49000.0, 32000.0, 41000.0, 46000.0, 28000.0, 40000.0, 45000.0,
        33000.0, 43000.0, 51000.0, 29000.0, 38000.0, 42000.0, 31000.0, 47000.0, 53000.0, 35000.0,
        40000.0, 46000.0, 27000.0, 44000.0, 49000.0, 34000.0, 39000.0, 48000.0, 30000.0, 43000.0
    ]

    vec2 = hcat(_close_col, _vol_col)
    vec3 = hcat(_high_col, _low_col, _close_col)
    vec4 = hcat(_high_col, _low_col, _close_col, _vol_col)

    @testset "ADL" begin
        @test ADL(vec4) isa Vector{Float64}
        @test ADL(data_ts) isa TSFrame
        @test names(ADL(data_ts))[1] == "ADL"

        # No NaN/Inf in output
        adl_result = ADL(vec4)
        @test !any(isnan, adl_result)
        @test !any(isinf, adl_result)

        # Numerical validation
        # ADL: CLV = (2*Close - Low - High) / (High - Low); MFV = CLV * Volume
        # When close is at the midpoint, CLV=0 -> MFV=0
        mid_data = [10.0 8.0 9.0 1000.0; 11.0 9.0 10.0 2000.0; 12.0 10.0 11.0 3000.0]
        @test all(ADL(mid_data) .≈ 0.0)

        # When close is at high, CLV=1
        # i=1: CLV=(20-8-10)/2=1.0, MFV=1000, ADL=1000
        # i=2: CLV=(22-8-12)/4=0.5, MFV=1000, ADL=2000
        # i=3: CLV=(28-10-15)/5=0.6, MFV=1800, ADL=3800
        top_data = [10.0 8.0 10.0 1000.0; 12.0 8.0 11.0 2000.0; 15.0 10.0 14.0 3000.0]
        adl = ADL(top_data)
        @test adl[1] ≈ 1000.0 atol=1e-10
        @test adl[2] ≈ 2000.0 atol=1e-10
        @test adl[3] ≈ 3800.0 atol=1e-10
    end

    @testset "ATR" begin
        @test ATR(vec3) isa Vector{Float64}
        @test ATR(vec3; n=42) isa Vector{Float64}
        @test ATR(vec3; n=42, ma_type=:SMA) isa Vector{Float64}
        @test ATR(vec3; n=42, ma_type=:SMMA) isa Vector{Float64}
        @test ATR(data_ts) isa TSFrame
        atr = ATR(data_ts; n=42)
        @test atr isa TSFrame
        @test names(atr)[1] == "ATR_42"

        # No NaN/Inf in output
        atr_result = ATR(vec3)
        @test !any(isnan, atr_result)
        @test !any(isinf, atr_result)

        # Numerical validation
        # Constant range data: high-low=2 always, consecutive closes differ by 1
        # TR = max(H-L, |H-prevC|, |L-prevC|)
        # For uniform step: TR=2 every bar
        atr_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                           15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
        r = ATR(atr_data; n=3, ma_type=:SMA)
        # All true ranges are 2.0, so ATR should be 2.0 everywhere
        for i in 1:10
            @test r[i] ≈ 2.0 atol=1e-10
        end

        r_ema = ATR(atr_data; n=3, ma_type=:EMA)
        for i in 1:10
            @test r_ema[i] ≈ 2.0 atol=1e-10
        end
    end

    @testset "ChaikinOsc" begin
        @test ChaikinOsc(vec4) isa Vector{Float64}
        @test ChaikinOsc(vec4; fast=10, slow=30) isa Vector{Float64}
        @test ChaikinOsc(data_ts) isa TSFrame
        co = ChaikinOsc(data_ts; fast=10, slow=30)
        @test co isa TSFrame
        @test names(co)[1] == "ChaikinOsc"

        # No NaN/Inf in output
        co_result = ChaikinOsc(vec4)
        @test !any(isnan, co_result)
        @test !any(isinf, co_result)

        # Numerical validation
        # ChaikinOsc = EMA(fast) of ADL - EMA(slow) of ADL
        co_data = Float64[10 8 10 1000; 12 8 11 2000; 15 10 14 3000;
                          14 11 13 2500; 16 12 15 4000; 15 13 14 3000;
                          17 14 16 5000; 16 13 15 3500; 18 15 17 4500;
                          17 14 16 4000]
        r = ChaikinOsc(co_data; fast=3, slow=5)
        @test r[1] ≈ 0.0 atol=1e-10                          # both EMAs start equal
        @test r[end] ≈ 1168.357553155005 atol=1e-4
    end

    @testset "OBV" begin
        @test OBV(vec2) isa Vector{Float64}
        res = OBV(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "OBV"

        # No NaN/Inf in output
        obv_result = OBV(vec2)
        @test !any(isnan, obv_result)
        @test !any(isinf, obv_result)

        # Numerical validation
        # OBV: +volume on up close, -volume on down close, unchanged on flat
        obv_data = Float64[10 100; 11 200; 10.5 150; 11.5 300; 11.5 100]
        r = OBV(obv_data)
        @test r[1] ≈ 100.0 atol=1e-10                        # init with first volume
        @test r[2] ≈ 300.0 atol=1e-10                        # 11>10: 100+200
        @test r[3] ≈ 150.0 atol=1e-10                        # 10.5<11: 300-150
        @test r[4] ≈ 450.0 atol=1e-10                        # 11.5>10.5: 150+300
        @test r[5] ≈ 450.0 atol=1e-10                        # 11.5==11.5: unchanged
    end

    @testset "VWAP" begin
        @test VWAP(vec4) isa Vector{Float64}
        res = VWAP(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "VWAP"

        # No NaN/Inf in output
        vwap_result = VWAP(vec4)
        @test !any(isnan, vwap_result)
        @test !any(isinf, vwap_result)

        # Numerical validation
        # TP = (H + L + C) / 3; VWAP = cumsum(TP*V) / cumsum(V)
        vwap_data = Float64[10 8 9 1000; 12 10 11 2000; 14 12 13 3000; 16 14 15 4000; 18 16 17 5000]
        r = VWAP(vwap_data)

        # VWAP[1] == TP[1] = (10+8+9)/3 = 9.0
        @test r[1] ≈ 9.0 atol=1e-10

        # VWAP[2]: TP1=9, TP2=(12+10+11)/3=11; cum_tpv=9*1000+11*2000=31000; cum_v=3000
        @test r[2] ≈ 31000.0 / 3000.0 atol=1e-10

        # VWAP[3]: TP3=(14+12+13)/3=13; cum_tpv=31000+13*3000=70000; cum_v=6000
        @test r[3] ≈ 70000.0 / 6000.0 atol=1e-10

        # VWAP is always between min(Low) and max(High) of cumulative window
        for i in 1:5
            min_low = minimum(vwap_data[1:i, 2])
            max_high = maximum(vwap_data[1:i, 1])
            @test min_low <= r[i] <= max_high
        end

        # For constant prices and volume: VWAP equals that price
        const_data = Float64[10 10 10 500; 10 10 10 500; 10 10 10 500]
        r_const = VWAP(const_data)
        @test all(r_const .≈ 10.0)

        # All values should be finite
        @test all(isfinite, VWAP(vec4))

        # AAPL smoke test
        vwap_aapl = VWAP(data_ts)
        @test vwap_aapl isa TSFrame
        @test size(vwap_aapl)[1] == size(data_ts)[1]

        # Input validation
        @test_throws ArgumentError VWAP(rand(10, 3))  # wrong column count
    end

    @testset "AnchoredVWAP" begin
        # 1. Basic type checks
        @test AnchoredVWAP(vec4; anchor=1) isa Vector{Float64}
        res_ts = AnchoredVWAP(data_ts; anchor=1)
        @test res_ts isa TSFrame
        @test names(res_ts)[1] == "AnchoredVWAP"

        # 2. anchor=1 parity: must exactly match VWAP
        @test AnchoredVWAP(vec4; anchor=1) == VWAP(vec4)

        # 3. Pre-anchor NaN, post-anchor finite
        r_anchor3 = AnchoredVWAP(vec4; anchor=3)
        @test all(isnan, r_anchor3[1:2])
        @test all(isfinite, r_anchor3[3:end])

        # 4. Numerical accuracy (hand-calculated)
        #    5-row fixed data, anchor=3
        avwap_data = Float64[10 8 9 1000; 12 10 11 2000; 14 12 13 3000; 16 14 15 4000; 18 16 17 5000]
        r = AnchoredVWAP(avwap_data; anchor=3)
        # rows 1-2: NaN
        @test isnan(r[1])
        @test isnan(r[2])
        # row 3: TP3=(14+12+13)/3=13; AVWAP=13*3000/3000=13.0
        @test r[3] ≈ 13.0 atol=1e-10
        # row 4: TP4=(16+14+15)/3=15; cum_tpv=13*3000+15*4000=99000; cum_v=7000
        @test r[4] ≈ 99000.0 / 7000.0 atol=1e-10
        # row 5: TP5=(18+16+17)/3=17; cum_tpv=99000+17*5000=184000; cum_v=12000
        @test r[5] ≈ 184000.0 / 12000.0 atol=1e-10

        # Verify: anchor=3 result[3:5] matches VWAP on rows 3:5 slice
        vwap_slice = VWAP(avwap_data[3:5, :])
        @test r[3:5] ≈ vwap_slice atol=1e-10

        # 5. Last-row anchor
        n_rows = size(vec4, 1)
        r_last = AnchoredVWAP(vec4; anchor=n_rows)
        @test all(isnan, r_last[1:n_rows-1])
        # Last row: just the typical price
        tp_last = (vec4[n_rows, 1] + vec4[n_rows, 2] + vec4[n_rows, 3]) / 3.0
        @test r_last[n_rows] ≈ tp_last atol=1e-10

        # 6. TSFrame wrapper: anchor::Int and anchor::Date give the same result
        anchor_row = 5
        anchor_date = TSFrames.index(data_ts)[anchor_row]
        res_int = AnchoredVWAP(data_ts; anchor=anchor_row)
        res_date = AnchoredVWAP(data_ts; anchor=anchor_date)
        @test isequal(Matrix(res_int), Matrix(res_date))

        # 7. Error cases
        @test_throws ArgumentError AnchoredVWAP(vec4; anchor=0)          # anchor=0
        @test_throws ArgumentError AnchoredVWAP(vec4; anchor=n_rows+1)   # anchor > nrow
        @test_throws ArgumentError AnchoredVWAP(rand(10, 3); anchor=1)   # wrong column count
        @test_throws ArgumentError AnchoredVWAP(Matrix{Float64}(undef, 0, 4); anchor=1)  # empty matrix
        @test_throws ArgumentError AnchoredVWAP(data_ts; anchor=Date(1900, 1, 1))  # date not found
    end

    @testset "CCI" begin
        @test CCI(vec3) isa Vector{Float64}
        @test CCI(vec3; n=10) isa Vector{Float64}
        res = CCI(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "CCI_20"

        # No NaN/Inf in output
        cci_result = CCI(vec3)
        @test !any(isnan, cci_result)
        @test !any(isinf, cci_result)

        # Numerical validation
        # CCI = (TP - SMA_TP) / (0.015 * MAD)
        small_hlc = Float64[1 2 3; 4 5 6; 2 3 4; 5 6 7; 3 4 5]
        r = CCI(small_hlc; n=3)

        # For constant TP (MAD=0), CCI = 0.0
        const_hlc = Float64[10 10 10; 10 10 10; 10 10 10; 10 10 10; 10 10 10]
        r_const = CCI(const_hlc; n=3)
        @test all(r_const .≈ 0.0)

        # CCI should contain both positive and negative values for non-constant oscillating data
        @test any(x -> x > 0.0, r) && any(x -> x < 0.0, r)

        # For linearly rising data, CCI should be positive at end
        rising_hlc = hcat([i+1 for i in 1.0:20.0], [i-1 for i in 1.0:20.0], [i for i in 1.0:20.0])
        r_rising = CCI(rising_hlc; n=5)
        # After warmup, TP is above the SMA_TP -> CCI > 0
        @test r_rising[end] > 0.0 || r_rising[end] ≈ 0.0

        # All values should be finite
        @test all(isfinite, CCI(vec3))

        # Specific numerical check for small_hlc n=3
        # TP = (H+L+C)/3: [2.0, 5.0, 3.0, 6.0, 4.0]
        # At i=3 (full window): window=[2,5,3], SMA=10/3, MAD=mean(|2-10/3|,|5-10/3|,|3-10/3|)
        # = mean(4/3, 5/3, 1/3) = 10/9
        # CCI = (3 - 10/3) / (0.015 * 10/9) = (-1/3) / (1/60) = -20.0
        @test r[3] ≈ -20.0 atol=1e-10

        # AAPL smoke test
        cci_aapl = CCI(data_ts)
        @test cci_aapl isa TSFrame
        @test size(cci_aapl)[1] == size(data_ts)[1]

        # Input validation
        @test_throws ArgumentError CCI(rand(10, 2))  # wrong column count
        @test_throws ArgumentError CCI(rand(10, 3); n=0)  # period must be positive
    end

    @testset "ForceIndex" begin
        @test ForceIndex(vec2) isa Vector{Float64}
        @test ForceIndex(vec2; n=20) isa Vector{Float64}
        res = ForceIndex(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "ForceIndex_13"
        res2 = ForceIndex(data_ts; n=20)
        @test names(res2)[1] == "ForceIndex_20"

        # No NaN/Inf in output
        fi_result = ForceIndex(vec2)
        @test !any(isnan, fi_result)
        @test !any(isinf, fi_result)

        # Numerical validation
        # RawForce[1] = 0; RawForce[i] = (Close[i] - Close[i-1]) * Volume[i]
        # ForceIndex = EMA(RawForce; n=n)
        fi_data = Float64[10 100; 12 200; 11 150; 14 300; 13 250]
        r = ForceIndex(fi_data; n=2)

        # Raw force: [0, (12-10)*200=400, (11-12)*150=-150, (14-11)*300=900, (13-14)*250=-250]
        raw = [0.0, 400.0, -150.0, 900.0, -250.0]
        expected = EMA(raw; n=2)
        @test r ≈ expected atol=1e-10

        # Rising price with volume: Force Index should be positive (eventually)
        rising_data = hcat(collect(1.0:20.0), fill(1000.0, 20))
        r_rising = ForceIndex(rising_data; n=5)
        @test r_rising[end] > 0.0

        # Falling price with volume: Force Index should be negative (eventually)
        falling_data = hcat(collect(20.0:-1.0:1.0), fill(1000.0, 20))
        r_falling = ForceIndex(falling_data; n=5)
        @test r_falling[end] < 0.0

        # Zero price change: raw force is 0 for those bars
        const_data = Float64[10 100; 10 200; 10 150; 10 300; 10 250]
        r_const = ForceIndex(const_data; n=2)
        # All raw forces are 0 (no price change), so EMA of zeros = 0
        @test all(r_const .≈ 0.0)

        # All values should be finite
        @test all(isfinite, ForceIndex(vec2))

        # AAPL smoke test
        fi_aapl = ForceIndex(data_ts)
        @test fi_aapl isa TSFrame
        @test size(fi_aapl)[1] == size(data_ts)[1]

        # Input validation
        @test_throws ArgumentError ForceIndex(rand(10, 3))  # wrong column count
    end

    @testset "MFI" begin
        @test MFI(vec4) isa Vector{Float64}
        @test MFI(vec4; n=10) isa Vector{Float64}
        res = MFI(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "MFI_14"
        res2 = MFI(data_ts; n=10)
        @test names(res2)[1] == "MFI_10"

        # Output range: MFI must be in [0, 100]
        r_fixed = MFI(vec4)
        @test all(v -> 0.0 <= v <= 100.0, r_fixed)

        # All values should be finite
        @test all(isfinite, r_fixed)

        # No NaN/Inf in output
        @test !any(isnan, r_fixed)
        @test !any(isinf, r_fixed)

        # All prices rising with volume: all positive flow -> MFI = 100
        rising_data = Float64[10 8 9 1000;
                              12 10 11 2000;
                              14 12 13 3000;
                              16 14 15 4000;
                              18 16 17 5000]
        r_rising = MFI(rising_data; n=3)
        # After warmup, TP is always rising, so all flow is positive -> MFI = 100
        @test r_rising[end] ≈ 100.0 atol=1e-10

        # All prices falling with volume: all negative flow -> MFI = 0
        falling_data = Float64[18 16 17 5000;
                               16 14 15 4000;
                               14 12 13 3000;
                               12 10 11 2000;
                               10 8 9 1000]
        r_falling = MFI(falling_data; n=3)
        # After warmup, TP is always falling, so all flow is negative -> MFI = 0
        @test r_falling[end] ≈ 0.0 atol=1e-10

        # Alternating up/down with equal volumes: MFI near 50
        alt_data = Float64[10 8 9 1000;
                           12 10 11 1000;
                           10 8 9 1000;
                           12 10 11 1000;
                           10 8 9 1000;
                           12 10 11 1000;
                           10 8 9 1000;
                           12 10 11 1000]
        r_alt = MFI(alt_data; n=4)
        # TP alternates 9,11,9,11... MF alternates 9000,11000,9000,11000...
        # In a full window of 4: 2 positive (MF=11000 each), 2 negative (MF=9000 each)
        # MFR = 22000/18000, MFI = 100 - 100/(1+22/18) = 100 - 100/(40/18) = 100 - 45 = 55
        @test r_alt[end] ≈ 55.0 atol=1e-10

        # Numerical validation: manual calculation
        # prices: [H, L, C, V]
        num_data = Float64[10 8 9 100;    # TP=9,  MF=900
                           12 10 11 200;  # TP=11, MF=2200 (TP up: positive)
                           11 9 10 150]   # TP=10, MF=1500 (TP down: negative)
        r_num = MFI(num_data; n=2)
        # i=1: only 1 bar, no previous TP -> neutral. PosFlow=0, NegFlow=0 -> edge case
        # i=2: window [1,2]. Bar 1: neutral (no prev). Bar 2: TP[2]=11>TP[1]=9, pos. PosFlow=2200, NegFlow=0 -> MFI=100
        @test r_num[2] ≈ 100.0 atol=1e-10
        # i=3: window [2,3]. Bar 2: TP[2]=11>TP[1]=9, pos, MF=2200. Bar 3: TP[3]=10<TP[2]=11, neg, MF=1500.
        # PosFlow=2200, NegFlow=1500. MFR=2200/1500=22/15. MFI=100-100/(1+22/15)=100-100/(37/15)=100-1500/37
        expected_mfi = 100.0 - 100.0 / (1.0 + 2200.0 / 1500.0)
        @test r_num[3] ≈ expected_mfi atol=1e-10

        # Edge case: constant TP → pos_mf = neg_mf = 0 for all bars → MFI returns 100.0
        mfi_constant = repeat([105.0  103.0  104.0  1_000_000.0], 10, 1)
        result_const = MFI(mfi_constant; n=5)
        # When both pos and neg flow are zero, Foxtail returns 100.0 (neutral convention)
        @test all(isfinite, result_const)
        @test all(result_const .== 100.0)

        # AAPL smoke test
        mfi_aapl = MFI(data_ts)
        @test mfi_aapl isa TSFrame
        @test size(mfi_aapl)[1] == size(data_ts)[1]
        r_aapl = MFI(data_ts[:, [:High, :Low, :Close, :Volume]] |> Matrix)
        @test all(v -> 0.0 <= v <= 100.0, r_aapl)

        # Input validation
        @test_throws ArgumentError MFI(rand(10, 3))  # wrong column count
        @test_throws ArgumentError MFI(rand(10, 4); n=0)  # period must be positive
    end

    @testset "CMF" begin
        @test CMF(vec4) isa Vector{Float64}
        @test CMF(vec4; n=10) isa Vector{Float64}
        res = CMF(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "CMF_20"
        res2 = CMF(data_ts; n=10)
        @test names(res2)[1] == "CMF_10"

        # Output range: CMF must be in [-1, 1]
        r_fixed = CMF(vec4)
        @test all(v -> -1.0 <= v <= 1.0, r_fixed)

        # All values should be finite
        @test all(isfinite, r_fixed)

        # No NaN/Inf in output
        @test !any(isnan, r_fixed)
        @test !any(isinf, r_fixed)

        # All closes at high (bullish): CLV=1, CMF=1
        bull_data = Float64[10 8 10 1000;
                            12 10 12 1000;
                            11 9 11 1000]
        r_bull = CMF(bull_data; n=2)
        @test r_bull[2] ≈ 1.0 atol=1e-10
        @test r_bull[3] ≈ 1.0 atol=1e-10

        # All closes at low (bearish): CLV=-1, CMF=-1
        bear_data = Float64[10 8 8 1000;
                            12 10 10 1000;
                            11 9 9 1000]
        r_bear = CMF(bear_data; n=2)
        @test r_bear[2] ≈ -1.0 atol=1e-10
        @test r_bear[3] ≈ -1.0 atol=1e-10

        # Close at midpoint: CLV=0, CMF=0
        mid_data = Float64[10 8 9 1000;
                           12 10 11 1000;
                           11 9 10 1000]
        r_mid = CMF(mid_data; n=2)
        @test r_mid[2] ≈ 0.0 atol=1e-10
        @test r_mid[3] ≈ 0.0 atol=1e-10

        # Edge case: High == Low -> CLV = 0
        flat_data = Float64[10 10 10 1000;
                            10 10 10 1000;
                            10 10 10 1000]
        r_flat = CMF(flat_data; n=2)
        @test all(r_flat .≈ 0.0)

        # Edge case: Volume == 0 -> CMF = 0
        zero_vol = Float64[10 8 9 0;
                           12 10 11 0;
                           11 9 10 0]
        r_zero = CMF(zero_vol; n=2)
        @test all(r_zero .≈ 0.0)

        # Numerical validation: mixed CLV values
        # Bar 1: H=10,L=8,C=10,V=1000 -> CLV=(20-8-10)/(10-8)=2/2=1, MFV=1000
        # Bar 2: H=12,L=10,C=10,V=2000 -> CLV=(20-10-12)/(12-10)=-2/2=-1, MFV=-2000
        # Bar 3: H=11,L=9,C=10.5,V=1500 -> CLV=(21-9-11)/(11-9)=1/2=0.5, MFV=750
        num_data = Float64[10 8 10 1000;
                           12 10 10 2000;
                           11 9 10.5 1500]
        r_num = CMF(num_data; n=2)
        # i=2: window [1,2]. sum(MFV)=1000+(-2000)=-1000; sum(V)=1000+2000=3000; CMF=-1000/3000
        @test r_num[2] ≈ -1000.0 / 3000.0 atol=1e-10
        # i=3: window [2,3]. sum(MFV)=-2000+750=-1250; sum(V)=2000+1500=3500; CMF=-1250/3500
        @test r_num[3] ≈ -1250.0 / 3500.0 atol=1e-10

        # AAPL smoke test
        cmf_aapl = CMF(data_ts)
        @test cmf_aapl isa TSFrame
        @test size(cmf_aapl)[1] == size(data_ts)[1]
        r_aapl = CMF(data_ts[:, [:High, :Low, :Close, :Volume]] |> Matrix)
        @test all(v -> -1.0 <= v <= 1.0, r_aapl)

        # Input validation
        @test_throws ArgumentError CMF(rand(10, 3))  # wrong column count
        @test_throws ArgumentError CMF(rand(10, 4); n=0)  # period must be positive
    end

    @testset "VPT" begin
        @test VPT(vec2) isa Vector{Float64}
        res = VPT(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "VPT"

        # No NaN/Inf in output
        vpt_result = VPT(vec2)
        @test !any(isnan, vpt_result)
        @test !any(isinf, vpt_result)

        # Numerical validation
        # VPT[1] = 0.0
        # VPT[i] = VPT[i-1] + Volume[i] * (Close[i] - Close[i-1]) / Close[i-1]
        vpt_data = Float64[100 1000; 110 1500; 105 1200; 105 800; 120 2000]
        r = VPT(vpt_data)

        # VPT[1] = 0.0
        @test r[1] ≈ 0.0 atol=1e-10

        # VPT[2] = 0 + 1500 * (110 - 100) / 100 = 150.0
        @test r[2] ≈ 150.0 atol=1e-10

        # VPT[3] = 150 + 1200 * (105 - 110) / 110 = 150 - 54.5454... = 95.4545...
        @test r[3] ≈ 150.0 + 1200.0 * (105.0 - 110.0) / 110.0 atol=1e-10

        # Rising price + positive volume -> VPT increases
        @test r[2] > r[1]

        # Falling price + positive volume -> VPT decreases
        @test r[3] < r[2]

        # Constant price -> VPT unchanged
        @test r[4] ≈ r[3] atol=1e-10

        # All values should be finite
        @test all(isfinite, VPT(vec2))

        # AAPL smoke test
        vpt_aapl = VPT(data_ts)
        @test vpt_aapl isa TSFrame
        @test size(vpt_aapl)[1] == size(data_ts)[1]

        # Zero-denominator guard: close containing 0.0 should not produce Inf/NaN
        vpt_zero_data = Float64[0.0 1000; 50.0 1500; 100.0 1200]
        vpt_zero = VPT(vpt_zero_data)
        @test !any(isnan, vpt_zero) && !any(isinf, vpt_zero)
        @test vpt_zero[2] ≈ 0.0 atol=1e-10  # denominator closes[1]=0.0 -> guarded to 0.0

        # Input validation
        @test_throws ArgumentError VPT(rand(10, 3))  # wrong column count
    end

    @testset "NVI" begin
        @test NVI(vec2) isa Vector{Float64}
        res = NVI(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "NVI"

        # No NaN/Inf in output
        nvi_result = NVI(vec2)
        @test !any(isnan, nvi_result)
        @test !any(isinf, nvi_result)

        # Numerical validation
        # NVI[1] = 1000.0
        # if Volume[i] < Volume[i-1]: NVI[i] = NVI[i-1] * (1 + (Close[i] - Close[i-1]) / Close[i-1])
        # else: NVI[i] = NVI[i-1]
        nvi_data = Float64[100 2000; 110 1500; 105 1800; 115 1200; 120 1300]
        r = NVI(nvi_data)

        # NVI[1] = 1000.0
        @test r[1] ≈ 1000.0 atol=1e-10

        # i=2: Volume=1500 < 2000 -> update: 1000 * (1 + (110-100)/100) = 1000 * 1.1 = 1100
        @test r[2] ≈ 1100.0 atol=1e-10

        # i=3: Volume=1800 > 1500 -> no update: NVI[3] = NVI[2] = 1100
        @test r[3] ≈ 1100.0 atol=1e-10

        # i=4: Volume=1200 < 1800 -> update: 1100 * (1 + (115-105)/105)
        @test r[4] ≈ 1100.0 * (1.0 + (115.0 - 105.0) / 105.0) atol=1e-10

        # When volume increases: NVI unchanged
        @test r[3] ≈ r[2] atol=1e-10

        # When volume decreases and price rises: NVI increases
        @test r[2] > r[1]

        # All values positive (starts at 1000, only multiplicative changes)
        @test all(v -> v > 0.0, r)

        # All values should be finite
        @test all(isfinite, NVI(vec2))

        # AAPL smoke test
        nvi_aapl = NVI(data_ts)
        @test nvi_aapl isa TSFrame
        @test size(nvi_aapl)[1] == size(data_ts)[1]

        # Zero-denominator guard: close containing 0.0 should not produce Inf/NaN
        nvi_zero_data = Float64[0.0 2000; 50.0 1500; 100.0 1800]
        nvi_zero = NVI(nvi_zero_data)
        @test !any(isnan, nvi_zero) && !any(isinf, nvi_zero)
        @test nvi_zero[2] ≈ 1000.0 atol=1e-10  # denominator closes[1]=0.0 -> guarded, carries forward

        # Input validation
        @test_throws ArgumentError NVI(rand(10, 3))  # wrong column count
    end

    @testset "PVI" begin
        @test PVI(vec2) isa Vector{Float64}
        res = PVI(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "PVI"

        # No NaN/Inf in output
        pvi_result = PVI(vec2)
        @test !any(isnan, pvi_result)
        @test !any(isinf, pvi_result)

        # Numerical validation
        # PVI[1] = 1000.0
        # if Volume[i] > Volume[i-1]: PVI[i] = PVI[i-1] * (1 + (Close[i] - Close[i-1]) / Close[i-1])
        # else: PVI[i] = PVI[i-1]
        pvi_data = Float64[100 1000; 110 1500; 105 1200; 115 2000; 120 1800]
        r = PVI(pvi_data)

        # PVI[1] = 1000.0
        @test r[1] ≈ 1000.0 atol=1e-10

        # i=2: Volume=1500 > 1000 -> update: 1000 * (1 + (110-100)/100) = 1000 * 1.1 = 1100
        @test r[2] ≈ 1100.0 atol=1e-10

        # i=3: Volume=1200 < 1500 -> no update: PVI[3] = PVI[2] = 1100
        @test r[3] ≈ 1100.0 atol=1e-10

        # i=4: Volume=2000 > 1200 -> update: 1100 * (1 + (115-105)/105)
        @test r[4] ≈ 1100.0 * (1.0 + (115.0 - 105.0) / 105.0) atol=1e-10

        # When volume decreases: PVI unchanged
        @test r[3] ≈ r[2] atol=1e-10

        # When volume increases and price rises: PVI increases
        @test r[2] > r[1]

        # All values positive (starts at 1000, only multiplicative changes)
        @test all(v -> v > 0.0, r)

        # All values should be finite
        @test all(isfinite, PVI(vec2))

        # AAPL smoke test
        pvi_aapl = PVI(data_ts)
        @test pvi_aapl isa TSFrame
        @test size(pvi_aapl)[1] == size(data_ts)[1]

        # Zero-denominator guard: close containing 0.0 should not produce Inf/NaN
        pvi_zero_data = Float64[0.0 1000; 50.0 1500; 100.0 1200]
        pvi_zero = PVI(pvi_zero_data)
        @test !any(isnan, pvi_zero) && !any(isinf, pvi_zero)
        @test pvi_zero[2] ≈ 1000.0 atol=1e-10  # denominator closes[1]=0.0 -> guarded, carries forward

        # Input validation
        @test_throws ArgumentError PVI(rand(10, 3))  # wrong column count
    end

    @testset "EMV" begin
        @test EMV(vec3) isa Vector{Float64}
        @test EMV(vec3; n=10) isa Vector{Float64}
        res = EMV(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "EMV_14"

        # No NaN/Inf in output
        emv_result = EMV(vec3)
        @test !any(isnan, emv_result)
        @test !any(isinf, emv_result)

        # EMV[1] == 0.0 (no previous bar -> raw_emv[1] = 0)
        emv_data = Float64[10 8 1000; 12 10 2000; 14 12 3000; 13 11 2500; 15 13 4000;
                           14 12 3500; 16 14 5000; 15 13 4500; 17 15 6000; 16 14 5500]
        r = EMV(emv_data; n=3)
        # raw_emv[1] = 0 because no previous bar
        # After SMA smoothing, first value still 0.0 (SMA(1) uses only raw_emv[1]=0)
        @test r[1] ≈ 0.0 atol=1e-10

        # For constant High/Low (distance_moved = 0): EMV should be 0
        const_hl = Float64[10 8 1000; 10 8 2000; 10 8 3000; 10 8 4000; 10 8 5000]
        r_const = EMV(const_hl; n=2)
        @test all(x -> abs(x) < 1e-10, r_const)

        # All values should be finite
        @test all(isfinite, EMV(vec3))

        # Edge case: High == Low (hl_diff = 0) → raw_emv should be 0.0
        emv_flat_hl = [
            102.0  102.0  1_000_000.0;  # first bar (reference)
            102.0  102.0  1_000_000.0;  # High == Low → hl_diff = 0
            103.0  101.0  1_200_000.0;
            104.0  102.0    900_000.0;
            103.5  101.5  1_100_000.0;
        ]
        result_flat = EMV(emv_flat_hl; n=2)
        @test all(isfinite, result_flat)

        # Edge case: Volume == 0 → box_ratio = 0 → raw_emv should be 0.0
        emv_zero_vol = [
            102.0  100.0  1_000_000.0;
            103.0  101.0          0.0;  # Volume == 0 → box_ratio = 0
            104.0  102.0  1_200_000.0;
            103.5  101.5    900_000.0;
            104.5  102.5  1_100_000.0;
        ]
        result_zvol = EMV(emv_zero_vol; n=2)
        @test all(isfinite, result_zvol)

        # AAPL smoke test (data_ts has High, Low, Volume columns)
        emv_aapl = EMV(data_ts)
        @test emv_aapl isa TSFrame
        @test size(emv_aapl)[1] == size(data_ts)[1]
    end

    @testset "MassIndex" begin
        vec2_hl = hcat(_high_col, _low_col)

        # Type checks
        @test MassIndex(vec2_hl) isa Vector{Float64}
        @test MassIndex(vec2_hl; n=10, ema_period=5) isa Vector{Float64}

        # TSFrame wrapper
        res = MassIndex(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "MassIndex_25"
        res2 = MassIndex(data_ts; n=10)
        @test names(res2)[1] == "MassIndex_10"

        # Length check
        @test length(MassIndex(vec2_hl)) == 100

        # No Inf in output
        mi_result = MassIndex(vec2_hl)
        @test !any(isinf, mi_result)

        # Numerical validation with small known input
        # range = [5, 4, 3, 4, 5]
        # single_ema(period=2): alpha warmup: r[1]=5, r[2]=5*0.333+4*0.667≈4.333, ...
        # We validate properties rather than exact intermediate EMA values
        mi_data = Float64[10 5; 12 8; 11 8; 13 9; 15 10]
        r = MassIndex(mi_data; n=3, ema_period=2)
        @test length(r) == 5
        @test r[1] > 0.0  # first bar: ratio is single_ema/double_ema = data[1]/data[1] = 1.0, sum=1.0
        @test r[1] ≈ 1.0 atol=1e-10  # bar 1: single_ema=double_ema=range[1], ratio=1.0, sum=1.0

        # Constant range: single_ema ≈ double_ema ≈ range, ratio ≈ 1.0, MI ≈ n
        const_data = Float64[10 8; 12 10; 14 12; 16 14; 18 16; 20 18; 22 20; 24 22; 26 24; 28 26]
        r_const = MassIndex(const_data; n=5, ema_period=3)
        # After warmup, all ratios converge to 1.0, so MI converges to n=5
        @test r_const[end] ≈ 5.0 atol=0.1

        # All values should be finite and non-negative
        @test all(isfinite, mi_result)
        @test all(v -> v >= 0.0, mi_result)

        # AAPL smoke test
        mi_aapl = MassIndex(data_ts)
        @test mi_aapl isa TSFrame
        @test size(mi_aapl)[1] == size(data_ts)[1]
        r_aapl = MassIndex(data_ts[:, [:High, :Low]] |> Matrix)
        @test all(isfinite, r_aapl)

        # Input validation
        @test_throws ArgumentError MassIndex(rand(10, 3))   # wrong column count
        @test_throws ArgumentError MassIndex(rand(10, 2); n=0)  # n must be positive
        @test_throws ArgumentError MassIndex(rand(10, 2); ema_period=0)  # ema_period must be positive
    end

    @testset "UltimateOsc" begin
        # Type checks
        @test UltimateOsc(vec3) isa Vector{Float64}
        @test UltimateOsc(vec3; fast=5, medium=10, slow=20) isa Vector{Float64}

        # TSFrame wrapper
        res = UltimateOsc(data_ts)
        @test res isa TSFrame
        @test names(res)[1] == "UltimateOsc"

        # Length check
        @test length(UltimateOsc(vec3)) == 100

        # No Inf in output
        uo_result = UltimateOsc(vec3)
        @test !any(isinf, uo_result)

        # Numerical validation with small known input
        # [High Low Close]: bar 1 has no prev close -> bp=0
        uo_data = Float64[10 8 9; 12 9 11; 11 8 10; 13 10 12; 14 11 13]
        r = UltimateOsc(uo_data; fast=2, medium=3, slow=4)
        @test length(r) == 5

        # Bar 1: bp=0, tr=H-L=2. All sums have bp=0, so UO=0
        @test r[1] ≈ 0.0 atol=1e-10

        # Bar 2: true_low=min(9, 9)=9, bp=11-9=2, tr=max(12,9)-min(9,9)=3
        # fast(2): sum_bp=[0,2]=2, sum_tr=[2,3]=5 -> avg=2/5=0.4
        # medium(3): sum_bp=[0,2]=2, sum_tr=[2,3]=5 -> avg=2/5=0.4
        # slow(4): sum_bp=[0,2]=2, sum_tr=[2,3]=5 -> avg=2/5=0.4
        # UO = 100*(4*0.4 + 2*0.4 + 0.4)/7 = 100*2.8/7 = 40.0
        @test r[2] ≈ 40.0 atol=1e-10

        # Bar 3: true_low=min(8,11)=8, bp=10-8=2, tr=max(11,11)-min(8,11)=3
        # fast(2): sum_bp=[2,2]=4, sum_tr=[3,3]=6 -> avg=4/6=2/3
        # medium(3): sum_bp=[0,2,2]=4, sum_tr=[2,3,3]=8 -> avg=4/8=0.5
        # slow(4): sum_bp=[0,2,2]=4, sum_tr=[2,3,3]=8 -> avg=4/8=0.5
        # UO = 100*(4*(2/3) + 2*0.5 + 0.5)/7 = 100*(8/3 + 1.5)/7
        expected_bar3 = 100.0 * (4.0 * (4.0/6.0) + 2.0 * (4.0/8.0) + 1.0 * (4.0/8.0)) / 7.0
        @test r[3] ≈ expected_bar3 atol=1e-10

        # All values should be finite
        @test all(isfinite, uo_result)

        # Range check: UO is in [0, 100] for normal market data
        @test all(v -> 0.0 <= v <= 100.0, uo_result)

        # Constant price (H==L==C): all bp=0, all tr=0 -> UO=0 (guarded)
        const_data = Float64[10 10 10; 10 10 10; 10 10 10; 10 10 10; 10 10 10]
        r_const = UltimateOsc(const_data; fast=2, medium=3, slow=4)
        @test all(r_const .≈ 0.0)

        # AAPL smoke test
        uo_aapl = UltimateOsc(data_ts)
        @test uo_aapl isa TSFrame
        @test size(uo_aapl)[1] == size(data_ts)[1]
        r_aapl = UltimateOsc(data_ts[:, [:High, :Low, :Close]] |> Matrix)
        @test all(isfinite, r_aapl)

        # Input validation
        @test_throws ArgumentError UltimateOsc(rand(10, 2))       # wrong column count
        @test_throws ArgumentError UltimateOsc(rand(10, 3); fast=0)    # fast must be positive
        @test_throws ArgumentError UltimateOsc(rand(10, 3); medium=0)  # medium must be positive
        @test_throws ArgumentError UltimateOsc(rand(10, 3); slow=0)    # slow must be positive
    end
end
