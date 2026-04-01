@testset "Indicators" begin
    aapl = CSV.read(joinpath(dirname(@__FILE__), "aapl.csv"), TSFrame)
    data_ts = aapl[end-100:end]

    @testset "Indicators SISO" begin
        data_vec = collect(1.0:50.0)

        # Shared small input for numerical validation
        small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

        @testset "ALMA" begin
            @test ALMA(data_vec) isa Vector{Float64}
            @test ALMA(data_vec; n=5) isa Vector{Float64}
            @test ALMA(data_ts) isa TSFrame
            ma = ALMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ALMA_50"
            @test ALMA(data_ts; offset=0.9, sigma=5.5, n=20) isa TSFrame

            # Numerical validation
            # ALMA n=3: Gaussian-weighted MA. Reference computed via Foxtail.
            r = ALMA(small; n=3)
            @test length(r) == 10
            @test r[1] ≈ 1.0 atol=1e-10                  # first value = price[1]
            @test r[3] ≈ 2.6856736002382617 atol=1e-8     # full window at i=3
            @test r[end] ≈ 9.685673600238262 atol=1e-8     # steady-state offset
            # Once window is full, ALMA(i) - ALMA(i-1) ≈ 1.0 for linear data
            @test r[6] - r[5] ≈ 1.0 atol=1e-10
        end

        @testset "EMA" begin
            @test EMA(data_vec) isa Vector{Float64}
            @test EMA(data_vec; n=5) isa Vector{Float64}
            @test EMA(data_ts) isa TSFrame
            ma = EMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "EMA_50"

            # Numerical validation
            # EMA n=3: alpha=2/(1+i) for i<=3, then alpha=2/(1+3)=0.5
            r = EMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[2] ≈ 5/3 atol=1e-10                          # alpha=2/3: 2*(2/3)+1*(1/3)
            @test r[3] ≈ 7/3 atol=1e-10                          # alpha=0.5: 3*0.5+5/3*0.5
            @test r[4] ≈ 4*0.5 + 7/3*0.5 atol=1e-10             # post-init: alpha=0.5
            @test r[end] ≈ 9.002604166666666 atol=1e-8           # converges toward data

            # EMA with different period
            r5 = EMA(small; n=5)
            @test r5[5] ≈ 11/3 atol=1e-10                        # alpha=2/6=1/3 at i=5
            @test r5[end] ≈ 8.087791495198903 atol=1e-8
        end

        @testset "DEMA" begin
            @test DEMA(data_vec) isa Vector{Float64}
            @test DEMA(data_vec; n=5) isa Vector{Float64}
            @test DEMA(data_ts) isa TSFrame
            ma = DEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "DEMA_50"

            # Numerical validation
            # DEMA = 2*EMA(price) - EMA(EMA(price))
            r = DEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value
            @test r[2] ≈ 1.8888888888888888 atol=1e-8
            @test r[3] ≈ 2.7777777777777777 atol=1e-8
            @test r[end] ≈ 9.989149305555555 atol=1e-8           # near 10 for linear data
            # DEMA should track linear data more closely than EMA
            ema_r = EMA(small; n=3)
            @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)
        end

        @testset "HMA" begin
            @test HMA(data_vec) isa Vector{Float64}
            @test HMA(data_vec; n=5) isa Vector{Float64}
            @test HMA(data_ts) isa TSFrame
            ma = HMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "HMA_50"

            # Numerical validation
            # HMA n=4: WMA[sqrt(4)=2]( 2*WMA[2] - WMA[4] )
            r = HMA(small; n=4)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[end] ≈ 10.0 atol=1e-10                       # HMA perfectly tracks linear data
            @test r[5] ≈ 5.0 atol=1e-8
            @test r[6] ≈ 6.0 atol=1e-8
        end

        @testset "JMA" begin
            @test JMA(data_vec) isa Vector{Float64}
            @test JMA(data_vec; n=5) isa Vector{Float64}
            @test JMA(data_ts) isa TSFrame
            ma = JMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "JMA_50"
            @test JMA(data_ts; phase=55.0, n=25) isa TSFrame
            @test JMA(data_ts; phase=-55.0, n=25) isa TSFrame

            # Numerical validation
            # JMA is adaptive; verify basic properties
            r = JMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value = price[1]
            @test length(r) == 10
            # JMA should be monotonically increasing for monotonic input
            for i in 2:10
                @test r[i] >= r[i-1] - 1e-10
            end
        end

        @testset "KAMA" begin
            @test KAMA(data_vec) isa Vector{Float64}
            @test KAMA(data_vec; n=5) isa Vector{Float64}
            @test KAMA(data_ts) isa TSFrame
            ma = KAMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "KAMA_50"
            @test KAMA(data_ts; fast=5, slow=25, n=15) isa TSFrame

            # Numerical validation
            # KAMA n=3: Kaufman Adaptive MA
            r = KAMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.4444444444444442 atol=1e-8
            @test r[3] ≈ 2.135802469135802 atol=1e-8
            @test r[end] ≈ 6.8882667553034 atol=1e-6
            # KAMA should lag behind for trending data
            @test r[end] < small[end]
        end

        @testset "RSI" begin
            @test RSI(data_vec) isa Vector{Float64}
            @test RSI(data_vec; n=5) isa Vector{Float64}
            @test RSI(data_ts) isa TSFrame
            @test RSI(data_ts; ma_type=:EMA) isa TSFrame
            @test RSI(data_ts; ma_type=:SMMA) isa TSFrame
            ma = RSI(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "RSI_50"
            @test RMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # RSI first value is always 0 (undefined)
            rsi_data = [44.0, 44.34, 44.09, 43.61, 44.33, 44.83, 45.10,
                        45.42, 45.84, 46.08, 45.89, 46.03, 45.61, 46.28,
                        46.28, 46.00, 46.03, 46.41, 46.22, 45.64]
            r = RSI(rsi_data; n=14)
            @test r[1] ≈ 0.0 atol=1e-10                          # first is undefined
            @test r[end] ≈ 60.13716896582762 atol=1e-6

            # RSI with SMA: simple small dataset
            rsi_small = [10.0, 12.0, 11.0, 13.0, 12.5, 14.0, 13.0, 15.0, 14.5, 16.0]
            r2 = RSI(rsi_small; n=3, ma_type=:SMA)
            @test r2[1] ≈ 0.0 atol=1e-10
            @test r2[2] ≈ 100.0 atol=1e-10                       # pure gain -> RSI=100
            @test r2[end] ≈ 87.5 atol=1e-6

            # RSI should be bounded [0, 100] (except first which is 0)
            for i in 2:length(r)
                @test 0.0 <= r[i] <= 100.0
            end

            # Monotonically increasing data -> RSI = 100 at index 2
            mono = collect(1.0:20.0)
            r_mono = RSI(mono; n=5)
            @test r_mono[2] ≈ 100.0 atol=1e-10
        end

        @testset "SMA" begin
            @test SMA(data_vec) isa Vector{Float64}
            @test SMA(data_vec; n=5) isa Vector{Float64}
            @test SMA(data_ts) isa TSFrame
            ma = SMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMA_50"
            @test RMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # SMA n=3: arithmetic mean over sliding window
            r = SMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # 1/1
            @test r[2] ≈ 1.5 atol=1e-10                          # (1+2)/2
            @test r[3] ≈ 2.0 atol=1e-10                          # (1+2+3)/3 = 2.0
            @test r[4] ≈ 3.0 atol=1e-10                          # (2+3+4)/3 = 3.0
            @test r[5] ≈ 4.0 atol=1e-10                          # (3+4+5)/3 = 4.0
            @test r[end] ≈ 9.0 atol=1e-10                        # (8+9+10)/3 = 9.0

            # SMA n=5
            r5 = SMA(small; n=5)
            @test r5[5] ≈ 3.0 atol=1e-10                         # (1+2+3+4+5)/5 = 3.0
            @test r5[end] ≈ 8.0 atol=1e-10                       # (6+7+8+9+10)/5 = 8.0
        end

        @testset "SMMA" begin
            @test SMMA(data_vec) isa Vector{Float64}
            @test SMMA(data_vec; n=5) isa Vector{Float64}
            @test SMMA(data_ts) isa TSFrame
            ma = SMMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMMA_50"

            # Numerical validation
            # SMMA n=3: alpha=1/i for i<=3, then alpha=1/3
            r = SMMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[2] ≈ 1.5 atol=1e-10                          # alpha=1/2: 2*0.5+1*0.5
            @test r[3] ≈ 2.0 atol=1e-10                          # alpha=1/3: 3/3+1.5*2/3
            @test r[4] ≈ 8/3 atol=1e-10                          # alpha=1/3: 4/3+2*2/3
            @test r[end] ≈ 8.058527663465936 atol=1e-8

            # SMMA n=5
            r5 = SMMA(small; n=5)
            @test r5[5] ≈ 3.0 atol=1e-10                         # matches SMA at period end
            @test r5[end] ≈ 6.655360000000001 atol=1e-8           # more lag than EMA
        end

        @testset "T3" begin
            @test T3(data_vec) isa Vector{Float64}
            @test T3(data_vec; n=5) isa Vector{Float64}
            @test T3(data_ts) isa TSFrame
            ma = T3(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "T3_50"
            @test T3(data_ts;n=25, a=0.6) isa TSFrame

            # Numerical validation
            # T3 is built from DEMA layers; verify basic properties
            r = T3(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value
            @test length(r) == 10
            # T3 should be monotonically increasing for monotonic input
            for i in 2:10
                @test r[i] >= r[i-1] - 1e-6
            end
        end

        @testset "TEMA" begin
            @test TEMA(data_vec) isa Vector{Float64}
            @test TEMA(data_vec; n=5) isa Vector{Float64}
            @test TEMA(data_ts) isa TSFrame
            ma = TEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TEMA_50"

            # Numerical validation
            # TEMA = (EMA1 - EMA2)*3 + EMA3
            r = TEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.9629629629629632 atol=1e-8
            @test r[3] ≈ 2.9259259259259256 atol=1e-8
            @test r[end] ≈ 10.014612268518519 atol=1e-8          # overshoots slightly
            # TEMA tracks linear data very closely
            @test abs(r[end] - 10.0) < 0.02
        end

        @testset "TMA" begin
            @test TMA(data_vec) isa Vector{Float64}
            @test TMA(data_vec; n=5) isa Vector{Float64}
            @test TMA(data_ts) isa TSFrame
            ma = TMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TMA_50"
            @test TRIMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # TMA n=3: SMA(SMA(price; n=3); n=div(4,2)=2)
            r = TMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.25 atol=1e-10                         # SMA of [1.0,1.5] = 1.25
            @test r[3] ≈ 1.75 atol=1e-10                         # SMA of [1.5,2.0] = 1.75
            @test r[4] ≈ 2.5 atol=1e-10                          # SMA of [2.0,3.0] = 2.5
            @test r[end] ≈ 8.5 atol=1e-10                        # SMA of [8.0,9.0] = 8.5
            # TMA lags behind SMA
            sma_r = SMA(small; n=3)
            @test r[end] < sma_r[end]
        end

        @testset "WMA" begin
            @test WMA(data_vec) isa Vector{Float64}
            @test WMA(data_vec; n=5) isa Vector{Float64}
            @test WMA(data_ts) isa TSFrame
            ma = WMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "WMA_50"

            # Numerical validation
            # WMA n=3: weights [1,2,3], denom=6
            r = WMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # (1*1)/1
            @test r[2] ≈ 5/3 atol=1e-10                          # (1*1+2*2)/3 = 5/3
            @test r[3] ≈ 14/6 atol=1e-10                         # (1+4+9)/6 = 14/6
            @test r[4] ≈ 10/3 atol=1e-10                         # (1*2+2*3+3*4)/6 = 20/6 = 10/3
            @test r[end] ≈ 28/3 atol=1e-10                       # (1*8+2*9+3*10)/6 = 56/6

            # WMA n=5
            r5 = WMA(small; n=5)
            @test r5[5] ≈ 11/3 atol=1e-10                        # (1+4+9+16+25)/15 = 55/15
            @test r5[end] ≈ 26/3 atol=1e-10                      # (6+14+24+36+50)/15 = 130/15
        end

        @testset "ZLEMA" begin
            @test ZLEMA(data_vec) isa Vector{Float64}
            @test ZLEMA(data_vec; n=5) isa Vector{Float64}
            @test ZLEMA(data_ts) isa TSFrame
            ma = ZLEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ZLEMA_50"

            # Numerical validation
            # ZLEMA n=3: zero-lag EMA using modified price = 2*price - price[lag]
            r = ZLEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[end] ≈ 9.998697916666666 atol=1e-8            # nearly perfect tracking
            # ZLEMA tracks linear data better than standard EMA
            ema_r = EMA(small; n=3)
            @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)

            # ZLEMA n=5
            r5 = ZLEMA(small; n=5)
            @test r5[end] ≈ 10.008779149519892 atol=1e-8
        end
    end

    @testset "Indicators MISO" begin
        vec2 = rand(100,2) * 100
        vec3 = rand(100,3) * 100
        vec4 = rand(100,4) * 100

        @testset "ADL" begin
            @test ADL(vec4) isa Vector{Float64}
            @test ADL(data_ts) isa TSFrame
            @test names(ADL(data_ts))[1] == "ADL"

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
    end

    @testset "Indicators SIMO" begin
        data_vec = collect(1.0:50.0)

        # Shared small input for numerical validation
        small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

        @testset "BollingerBands" begin
            @test BB(data_vec) isa Matrix{Float64}
            @test BB(data_vec; n=25, num_std=3.0) isa Matrix{Float64}
            @test BB(data_ts) isa TSFrame
            @test BB(data_ts; n=25, num_std=3.0) isa TSFrame
            @test BB(data_ts; ma_type=:EMA) isa TSFrame
            @test BB(data_ts; ma_type=:SMMA) isa TSFrame
            ind = BB(data_ts)
            @test names(ind)[1] == "BB_Center"
            @test names(ind)[2] == "BB_Upper"
            @test names(ind)[3] == "BB_Lower"

            # Numerical validation
            # BB n=3, num_std=2.0: Center=SMA, Upper/Lower=Center +/- 2*std
            bb = BB(small; n=3, num_std=2.0)
            # Center = SMA n=3
            @test bb[3,1] ≈ 2.0 atol=1e-10                       # SMA([1,2,3])
            @test bb[4,1] ≈ 3.0 atol=1e-10                       # SMA([2,3,4])
            @test bb[end,1] ≈ 9.0 atol=1e-10                     # SMA([8,9,10])

            # At i=3: std of [1,2,3] = sqrt(2/3) ≈ 0.8165
            std3 = sqrt(2/3)
            @test bb[3,2] ≈ 2.0 + 2.0*std3 atol=1e-8             # upper
            @test bb[3,3] ≈ 2.0 - 2.0*std3 atol=1e-8             # lower

            # Band symmetry: upper - center == center - lower
            for i in 3:10
                @test (bb[i,2] - bb[i,1]) ≈ (bb[i,1] - bb[i,3]) atol=1e-10
            end

            # First value: no spread
            @test bb[1,1] ≈ 1.0 atol=1e-10
            @test bb[1,2] ≈ 1.0 atol=1e-10                       # std=0 for single point
            @test bb[1,3] ≈ 1.0 atol=1e-10
        end

        @testset "MACD" begin
            @test MACD(data_vec) isa Matrix{Float64}
            ind = MACD(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "MACD_Line"
            @test names(ind)[2] == "MACD_Signal"
            @test names(ind)[3] == "MACD_Histogram"

            # Numerical validation
            # MACD = EMA(fast) - EMA(slow); Signal = EMA(MACD); Histogram = MACD - Signal
            data30 = collect(1.0:30.0)
            m = MACD(data30; fast=3, slow=5, signal=3)
            # For linear data, fast EMA > slow EMA -> MACD line > 0
            @test m[end,1] ≈ 0.9999736010648235 atol=1e-6        # MACD line
            @test m[end,2] ≈ 0.9999472455913766 atol=1e-6        # Signal line
            @test m[end,3] ≈ m[end,1] - m[end,2] atol=1e-10     # Histogram = Line - Signal

            # MACD line should be positive for upward-trending data
            for i in 5:30
                @test m[i,1] > 0.0
            end

            # Histogram should converge to 0 for linear data
            @test abs(m[end,3]) < 0.001
        end

        @testset "MACD3" begin
            @test MACD3(data_vec) isa Matrix{Float64}
            ind = MACD3(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "MACD3_Fast"
            @test names(ind)[2] == "MACD3_Middle"
            @test names(ind)[3] == "MACD3_Slow"
            @test MACD3(data_ts; ma_type=:HAJ, fast=10, middle=30, slow=50) isa TSFrame
            @test MACD3(data_ts; ma_type=:KAMA, fast=10, middle=30, slow=50) isa TSFrame
            @test MACD3(data_ts; ma_type=:ALMA, fast=10, middle=30, slow=50) isa TSFrame

            # Numerical validation
            # MACD3 with EMA: fast-middle, fast-slow, middle-slow differences
            m = MACD3(data_vec)
            @test size(m) == (50, 3)
            # For linear data, all differences should be positive (fast > slow)
            # and converge. Check last values are positive.
            @test m[end,1] > 0.0                                  # fast - middle > 0
            @test m[end,2] > 0.0                                  # fast - slow > 0
            @test m[end,3] > 0.0                                  # middle - slow > 0
            # Middle line should be larger than fast and slow lines
            @test m[end,2] > m[end,1]
            @test m[end,2] > m[end,3]
        end

        @testset "Stochastic RSI" begin
            @test StochRSI(data_vec) isa Matrix{Float64}
            @test StochRSI(data_ts) isa TSFrame
            @test StochRSI(data_ts; ma_type=:EMA, k_smooth=3, d_smooth=5) isa TSFrame
            @test StochRSI(data_ts; ma_type=:SMMA, k_smooth=4, d_smooth=6) isa TSFrame
            @test StochRSI(data_ts; ma_type=:RMA, k_smooth=4, d_smooth=6) isa TSFrame
            @test StochRSI(data_ts; ma_type=:WMA, k_smooth=6, d_smooth=8) isa TSFrame
            ind = StochRSI(data_ts)
            @test names(ind)[1] == "StochRSI_K"
            @test names(ind)[2] == "StochRSI_D"

            # Numerical validation
            # For monotonically increasing data, RSI stays near 100,
            # so StochRSI should reflect that stability
            r = StochRSI(data_vec)
            @test size(r) == (50, 2)
            # K and D lines should be in [0, 100] range roughly
            # (smoothing may cause small overshoots but should be close)
            @test r[end,1] >= 0.0
            @test r[end,2] >= 0.0
        end
    end

    @testset "Indicators MIMO" begin
        vec3 = rand(100,3) * 100

        @testset "Stochastic" begin
            @test Stoch(vec3) isa Matrix{Float64}
            res = Stoch(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "Stoch_K"
            @test names(res)[2] == "Stoch_D"
            @test Stoch(data_ts; n=25, k_smooth=4, d_smooth=5) isa TSFrame
            @test Stoch(data_ts; ma_type=:EMA) isa TSFrame
            @test Stoch(data_ts; ma_type=:SMMA) isa TSFrame

            # Numerical validation
            # Stochastic with known data: %K = 100*(close-lowest)/(highest-lowest)
            stoch_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                                 14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
            s = Stoch(stoch_data; n=3, k_smooth=2, d_smooth=2)
            @test s[1,1] ≈ 50.0 atol=1e-8                        # first raw K
            @test s[end,1] ≈ 56.66666666666667 atol=1e-6         # K at end
            @test s[end,2] ≈ 67.08333333333334 atol=1e-6         # D at end

            # K and D should be bounded roughly in [0, 100]
            for i in 1:10
                @test -1.0 <= s[i,1] <= 101.0
                @test -1.0 <= s[i,2] <= 101.0
            end
        end

        @testset "Williams R" begin
            @test WR(vec3) isa Matrix{Float64}
            res = WR(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "WR_raw"
            @test names(res)[2] == "WR_EMA"
            @test WR(data_ts; n=25) isa TSFrame

            # Numerical validation
            # WR = -100 * (highest - close) / (highest - lowest)
            wr_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                              14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
            r = WR(wr_data; n=3)
            @test r[1,1] ≈ -50.0 atol=1e-8                       # (10-9)/(10-8) = 0.5 -> -50
            @test r[end,1] ≈ -66.66666666666667 atol=1e-6
            @test r[end,2] ≈ -52.694541821199344 atol=1e-6       # EMA smoothed

            # WR raw should be in [-100, 0] range
            for i in 1:10
                @test -100.0 <= r[i,1] <= 0.0 + 1e-10
            end
        end
    end
end
